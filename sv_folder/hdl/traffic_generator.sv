`timescale 1ns / 1ps
`default_nettype none

/*
 * traffic_generator
 * 
 * Module to provide the memory interface IP with the signals it needs,
 * decides what commands are issued in what order. Arbitrates between
 * write requests issued by write_axis, and read requests cycling through
 * the audio buffer, whose responses are fed into read_axis.
 * 
 */

module traffic_generator
  (
   input wire           clk_in,      // should be ui clk of DDR3!
   input wire           rst_in,
  
   // MIG UI --> generic outputs
   output logic [26:0]  app_addr,
   output logic [2:0]   app_cmd,
   output logic         app_en,
   // MIG UI --> write outputs
   output logic [127:0] app_wdf_data,
   output logic         app_wdf_end,
   output logic         app_wdf_wren,
   output logic [15:0]  app_wdf_mask,
   // MIG UI --> read inputs
   input wire [127:0]   app_rd_data,
   input wire           app_rd_data_end,
   input wire           app_rd_data_valid,
   // MIG UI --> generic inputs
   input wire           app_rdy,
   input wire           app_wdf_rdy,
   // MIG UI --> misc
   output logic         app_sr_req,  // ??
   output logic         app_ref_req, // ??
   output logic         app_zq_req,  // ??
   input wire           app_sr_active,
   input wire           app_ref_ack,
   input wire           app_zq_ack,
   input wire           init_calib_complete,
  
   // Write AXIS FIFO input
   input wire [127:0]   write_axis_data,
   input wire           write_axis_tlast,
   input wire           write_axis_valid,
   input wire           write_axis_smallpile,
   output logic         write_axis_ready,
   // Read AXIS FIFO output
   output logic [127:0] read_axis_data,
   output logic         read_axis_tlast,
   output logic         read_axis_valid,
   input wire           read_axis_af, // almost full signal
   input wire           read_axis_ready
  
   );


  // signals needed for app_cmd, specified by documentation
  localparam CMD_WRITE = 3'b000;
  localparam CMD_READ = 3'b001;
  // unused MIG signals tied to 0
  assign app_sr_req = 0;
  assign app_ref_req = 0;
  assign app_zq_req = 0;
  assign app_wdf_mask = 16'b0;

  // state machine used to alternate between read & write requests
  typedef enum {
    RST,
		WAIT_INIT,
		RD_COMPUTER,
		WR_AUDIO
	} tg_state;
  tg_state state;
  
  // Define ready/valid signals to output to our input+output AXI Streams!
  
  // give the write FIFO a "ready" signal when the MI is ready and our state machine
  // indicates it's the write AXIS' turn.
  logic   wdf_ready;
  assign wdf_ready = app_rdy && app_wdf_rdy;
  assign write_axis_ready = wdf_ready && (state == WR_AUDIO);

  // Feed the read output from the MIG (app_rd_data and app_rd_data_valid)
  // * the MIG does not handle back-pressure--there's no hook-up for a ready signal here!
  //   so the state machine we provide you ensures that the FIFO /always/ has space available.
  //   it utilizes the "almost full" signal (read_axis_af) which goes high if there are
  //   less than 12 slots remaining in the FIFO.
  assign read_axis_valid = app_rd_data_valid;
  assign read_axis_data = app_rd_data;

  // Not an AXI-Stream, but the signals that define when we actually issue a read request.
  
  logic read_request_valid; // defined further below, based on state machine + address info
  logic read_request_ready;
  assign read_request_ready = app_rdy && state == RD_COMPUTER;
  

  // define the addresses associated with each read or write command + response
  logic [26:0] write_address;
  logic [26:0] read_request_address;
  logic [26:0] read_response_address;

  evt_counter
    #(
    .MAX_COUNT(23436) // max count is 6 seconds of audio worth of data: 31,250 samples * 6 seconds = 187500 addresses / 8 samples per 128-bit address slot = 23436 samples
    ) write_address_counter
      (
    .clk_in(clk_in),
    .rst_in(write_axis_tlast),
    .evt_in(write_axis_valid && write_axis_ready),
    .count_out(write_address)
  );

  evt_counter
    #(
    .MAX_COUNT(23436)
    ) read_request_address_counter
      (
    .clk_in(clk_in),
    .rst_in(rst_in), 
    .evt_in((read_request_valid && read_request_ready)),
    .count_out(read_request_address)
  );

  evt_counter
    #(
    .MAX_COUNT(23436)
    ) read_response_address_counter
      (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .evt_in((read_axis_valid && read_axis_ready)),
    .count_out(read_response_address)
  );

  // for defining the write requests: your event should be a handshake on the write AXIStream,
  //     and the address should **reset** if a valid write axis transaction carries a TLAST !
  // for defining the read RESPONSES: your event should be a handshake on the read AXIStream
  // for defining the read REQUESTS: your event should be a "handshake" on the read requests
  
  localparam MAX_ADDR = 23435;
  
  // TODO: TLAST generation for the read output!
  // assign a tlast value based on the address your response is up to!

  assign read_axis_tlast = read_response_address == MAX_ADDR; // change me!!
  
  // parameter to control how many sequential reads we'll send in a burst.
  localparam MAX_CMD_QUEUE = 8;
  logic [26:0] addr_diff;
  assign addr_diff = read_request_address - read_response_address;
  assign read_request_valid = (addr_diff < MAX_CMD_QUEUE) && ~read_axis_af && state == RD_COMPUTER;

  // switch between read/write logic:
  // * if the write fifo is empty, switch to read mode
  // * if more than MAX_CMD_QUEUE requests are waiting, switch to write mode
  // * if the read data FIFO is almost full, switch to write mode
  // this state machine could be improved greatly to increase throughput on our DRAM data bus!
  logic 	go_to_wr, go_to_rd;
  assign go_to_wr = (addr_diff >= MAX_CMD_QUEUE) || read_axis_af;
  assign go_to_rd = ~write_axis_valid;
  
  always_ff @(posedge clk_in) begin
    if(rst_in) begin
	    state <= RST;
    end else begin
	    case(state)
	      RST: begin
	        state <= WAIT_INIT;
	      end
	      WAIT_INIT: begin
	        state <= init_calib_complete ? RD_COMPUTER : WAIT_INIT;
	      end
	      RD_COMPUTER: begin
	        state <= go_to_wr ? WR_AUDIO : RD_COMPUTER;
	      end
	      WR_AUDIO: begin
	        state <= go_to_rd ? RD_COMPUTER : WR_AUDIO; 
	      end
	    endcase // case (state)
    end
  end

  // signals to issue to the MIG in each state: when in each state, attempt to issue commands!
  always_comb begin
    case(state)
	    RST, WAIT_INIT: begin
	      app_addr = 0;
	      app_cmd = 0;
	      app_en = 0;
	      app_wdf_data = 0;
	      app_wdf_end = 0;
	      app_wdf_wren = 0;
	    end
	    WR_AUDIO: begin
        // App address shifted right! !! your write_address should address a 128-bit message.
	      app_addr     = write_address << 3;
	      app_cmd      = CMD_WRITE;
        // set command enable signals whenever the axi-stream has data valid and the MIG is ready
	      app_en       = write_axis_valid && wdf_ready;
	      app_wdf_wren = write_axis_valid && wdf_ready;
	      app_wdf_data = write_axis_data;
	      app_wdf_end  = write_axis_valid && wdf_ready;
	    end
	    RD_COMPUTER: begin
        // App address shifted right! !! your read_request_address should address a 128-bit message.
	      app_addr = read_request_address << 3;
	      app_cmd = CMD_READ;
	      // app_en = 1'b1;
	      app_en = read_request_valid;
	      app_wdf_wren = 1'b0;
	      app_wdf_data = 0;
	      app_wdf_end = 1'b0;
	    end
      default: begin
        app_addr     = 0;
        app_cmd      = 0;
        app_en       = 0;
        app_wdf_data = 0;
        app_wdf_end  = 0;
        app_wdf_wren = 0;
      end
    endcase // case (state)
  end // always_comb

endmodule

`default_nettype wire
