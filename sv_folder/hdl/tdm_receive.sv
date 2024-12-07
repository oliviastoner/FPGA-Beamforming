`timescale 1ns / 1ps `default_nettype none

module tdm_receive #(
    parameter BIT_WIDTH = 24,
    parameter SLOTS = 4
) (
    input wire clk_in, // 100MHz clk
    input wire sck_in,  // Serial Clock trigger
    input wire ws_in,  // Word Select
    input wire sd_in,  // Serial Data
    input wire rst_in,  // system reset
    output logic [BIT_WIDTH-1:0] audio_out[SLOTS],  // audio from microphone 1
    output logic audio_valid_out  // valid signal, HIGH when valid
);

  localparam [5:0] TOTAL_CYCLES = 31;  // cycle # that indicates looping back
  logic [5:0] sck_in_counter;
  logic [2:0] curr_slot;  // can also just harcode this since we know our slot #s
  logic active;  // flag to know to stay on slot 0 for start
  logic prev_sck_in;
  //logic prev_ws_in;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      sck_in_counter <= 0;
      curr_slot   <= 0;
      prev_sck_in <=0;
      active<=0;
      //prev_ws_in <=0;
    end else begin

        
      // trigger on rising edge still
      if(sck_in && !prev_sck_in)begin
            
        if (ws_in ) begin
            sck_in_counter <= 0;
            curr_slot   <= 0;
            for (int i = 0; i < SLOTS; i++) audio_out[i] <= 0;
            audio_valid_out <= 0;
            active <= 1;
        end else begin

            if (active) begin
                // add logic so it only starts doing reads when a ws_in signal comes by
                if (sck_in_counter < BIT_WIDTH - 1) begin
                    // shift in bits, MSB first
                    audio_out[curr_slot] <= {audio_out[curr_slot][BIT_WIDTH-2:0], sd_in};
                    sck_in_counter <= sck_in_counter + 1;
                end else if (sck_in_counter == BIT_WIDTH - 1) begin
                    // shift in bits, MSB first
                    audio_out[curr_slot] <= {audio_out[curr_slot][BIT_WIDTH-2:0], sd_in};
                    if (curr_slot == SLOTS - 1) begin
                    // raise high for a cycle now that they're all valid
                    audio_valid_out <= 1;
                    end
                    sck_in_counter <= sck_in_counter + 1;
                end else if (sck_in_counter == TOTAL_CYCLES) begin
                    // set up like the beginning
                    sck_in_counter <= 0;

                    audio_valid_out <= 0;
                    if (curr_slot == SLOTS - 1) begin
                    curr_slot <= 0;
                    active <= 0;
                    for (int i = 0; i < SLOTS; i++) audio_out[i] <= 0;
                    end else begin
                    curr_slot <= curr_slot + 1;
                    end

                end else begin
                    audio_valid_out <= 0;
                    sck_in_counter <= sck_in_counter + 1;
                end
            end
        end
        end
        prev_sck_in <= sck_in;
        //prev_ws_in <= ws_in;
      end




  end
endmodule  // tdm_receive

`default_nettype wire