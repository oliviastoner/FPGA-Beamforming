`timescale 1ns / 1ps
`default_nettype none

/*
 * stacker
 * 
 * AXI-Stream (approximately) module that takes in serialized 16-bit audio messages
 * and stacks them together into 128-bit messages. Least-significant bytes
 * received first.
 */

module stacker
  (
  input wire           clk_in,
  input wire           rst_in,
  // input axis: 16 bit audio
  input wire           audio_tvalid,
  output logic         audio_tready,
  input wire [15:0]    audio_tdata,
  input wire           audio_tlast,
  // output axis: 128 bit mig-phrases
  output logic         audio_chunk_tvalid,
  input wire           audio_chunk_tready,
  output logic [127:0] audio_chunk_tdata,
  output logic         audio_chunk_tlast
);

  logic [127:0] data_recent;
  logic [2:0]   count;
  logic [7:0]   tlast_recent;

  logic         accept_in;
  assign accept_in = audio_tvalid && audio_tready;

  assign audio_tready = (count == 7) ? audio_chunk_tready : 1'b1;

  logic accept_out;
  assign accept_out = audio_chunk_tready && audio_chunk_tvalid;
  
  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      data_recent  <= 127'b0;
      count        <= 0;
      tlast_recent <= 8'b0;
      audio_chunk_tvalid <= 1'b0;
    end else begin
      if (accept_in) begin
        data_recent  <= { audio_tdata[15:0], data_recent[127:16] };
        tlast_recent <= { audio_tlast, tlast_recent[7:1] };
        count        <= count + 1;

        if (count == 7) begin
          audio_chunk_tdata  <= { audio_tdata[15:0], data_recent[127:16] };
          audio_chunk_tlast <= (tlast_recent > 0);
          audio_chunk_tvalid <= 1'b1;
        end
        
      end
      if (accept_out) begin
        audio_chunk_tvalid <= 1'b0;
      end
    end
  end
  
endmodule

`default_nettype wire
