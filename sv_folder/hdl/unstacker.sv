`timescale 1ns / 1ps
`default_nettype none

module unstacker
  (
   input wire 	       clk_in,
   input wire 	       rst_in,
   // input axis: 128 bit phrases
   input wire 	       audio_chunk_tvalid,
   output logic        audio_chunk_tready,
   input wire [127:0]  audio_chunk_tdata,
   input wire 	       audio_chunk_tlast,
   // output axis: 16 bit words, each representing a 16-bit audio value
   output logic        audio_tvalid,
   input wire 	       audio_tready,
   output logic [15:0] audio_tdata,
   output logic        audio_tlast
   );

  logic [2:0] offset;
  logic       accept_in;
  logic       accept_out;

  assign accept_in = audio_chunk_tvalid && audio_chunk_tready;
  assign accept_out = audio_tvalid && audio_tready;

  logic [127:0] shift_phrase;
  assign audio_tdata = shift_phrase[15:0];

  logic tlast_hold;
  assign audio_tlast = offset == 7 ? tlast_hold : 1'b0;

  logic need_phrase;

  assign audio_chunk_tready = need_phrase || (offset == 7 && accept_out);
  assign audio_tvalid = !need_phrase;
  
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      shift_phrase <= 128'b0;
      need_phrase  <= 1'b1;
      offset       <= 0;
      tlast_hold <= 1'b1;
      
    end else begin

      if (accept_out) begin
        offset <= offset+1;

        if (offset==7) begin
          if (audio_chunk_tvalid) begin
            shift_phrase <= audio_chunk_tdata;
            tlast_hold <= audio_chunk_tlast;
          end else begin
            need_phrase <= 1'b1;
          end
          
        end else begin
          shift_phrase <= {16'b0, shift_phrase[127:16]};
        end
        
      end else if (accept_in) begin
        need_phrase  <= 1'b0;
        shift_phrase <= audio_chunk_tdata;
        tlast_hold <= audio_chunk_tlast;
        offset       <= 0;
      end
    end

  end

endmodule   

`default_nettype wire
