`timescale 1ns / 1ps
`default_nettype none

module tdm_receive 
    #(  parameter BIT_WIDTH = 24 
        parameter SLOTS = 4
     )
     (  input wire sck, // Serial Clock
        input wire ws, // Word Select
        input wire sd, // Serial Data
        input rst_in, // system reset
        output [BIT_WIDTH-1:0] audio_out; // audio from microphone
        output logic audio_valid_out // valid signal, HIGH when valid
     ) 
    
    localparam [5:0] TOTAL_CYCLES = 31; // cycle # that indicates looping back
    logic sck_counter; 
    logic [$ceil($log2(SLOTS))-1:0] curr_slot; // can also just harcode this since we know our slot #
    logic starting; // flag to know to stay on slot 0 for start

    always_ff @(posedge sck)begin

    end



endmodule // tdm_receive



`default_nettype wire