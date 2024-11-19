`timescale 1ns / 1ps
`default_nettype none


module tdm_receive
    #(  parameter BIT_WIDTH = 24,
        parameter SLOTS = 4
     )
     (  input wire sck, // Serial Clock
        input wire ws, // Word Select
        input wire sd, // Serial Data
        input wire rst_in, // system reset
        output logic wso, // slot number for audio
        output logic [BIT_WIDTH-1:0] audio_out1, // audio from microphone 1
        output logic [BIT_WIDTH-1:0] audio_out2, // audio from microphone 2
        output logic [BIT_WIDTH-1:0] audio_out3, // audio from microphone 3
        output logic [BIT_WIDTH-1:0] audio_out4, // audio from microphone 4
        output logic audio_valid_out // valid signal, HIGH when valid
     );
   
    localparam [5:0] TOTAL_CYCLES = 31; // cycle # that indicates looping back
    logic [5:0] sck_counter;
    logic [2:0] curr_slot; // can also just harcode this since we know our slot #s
    logic active; // flag to know to stay on slot 0 for start


    always_ff @(posedge sck)begin
        if(rst_in)begin
            sck_counter<=0;
            curr_slot <=0;
           
       
        end
        else begin
            if(ws)begin
                sck_counter <=0;
                curr_slot<=0;
                audio_out1<=0;
                audio_out2<=0;
                audio_out3<=0;
                audio_out4<=0;
                audio_valid_out<=0;
                active<=1;
            end
            else begin


                if(active) begin
                    // add logic so it only starts doing reads when a WS signal comes by
                    if(sck_counter <BIT_WIDTH-1) begin
                        // shift in bits, MSB first
                        case (curr_slot) 
                        3'b00: audio_out1 <= {audio_out1[BIT_WIDTH-2:0],sd};
                        3'b01: audio_out2 <= {audio_out2[BIT_WIDTH-2:0],sd};
                        3'b10: audio_out3 <= {audio_out3[BIT_WIDTH-2:0],sd};
                        3'b11: audio_out4 <= {audio_out4[BIT_WIDTH-2:0],sd};
                        default: audio_out1 <= {audio_out1[BIT_WIDTH-2:0],sd};
                        endcase
                        
                        sck_counter <= sck_counter + 1;


                    end
                    else if(sck_counter == BIT_WIDTH-1)begin
                        case (curr_slot) 
                        3'b00: audio_out1 <= {audio_out1[BIT_WIDTH-2:0],sd};
                        3'b01: audio_out2 <= {audio_out2[BIT_WIDTH-2:0],sd};
                        3'b10: audio_out3 <= {audio_out3[BIT_WIDTH-2:0],sd};
                        3'b11: begin 
                            audio_out4 <= {audio_out4[BIT_WIDTH-2:0],sd};
                             // raise high for a cycle now that they're all valid
                            audio_valid_out<=1;
                        end
                        default: audio_out1 <= {audio_out1[BIT_WIDTH-2:0],sd};
                        endcase
                       


                        sck_counter <= sck_counter + 1;


                    end
                    else if(sck_counter == TOTAL_CYCLES )begin
                        // set up like the beginning
                        sck_counter <=0;
                       
                        audio_valid_out<=0;
                        if(curr_slot == SLOTS -1)begin
                            curr_slot <=0;
                            active<=0;
                            audio_out1<=0;
                            audio_out2<=0;
                            audio_out3<=0;
                            audio_out4<=0;
                        end
                        else begin
                            curr_slot<=curr_slot +1;
                        end
                       


                    end
                    else begin
                        audio_valid_out <=0;
                        sck_counter <= sck_counter + 1;
                    end




                end
            end


        end


    end






endmodule // tdm_receive






`default_nettype wire
