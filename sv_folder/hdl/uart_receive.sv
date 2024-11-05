`timescale 1ns / 1ps
`default_nettype none

module uart_receive
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	       clk_in,
    input wire 	       rst_in,
    input wire 	       rx_wire_in,
    output logic       new_data_out,
    output logic [7:0] data_byte_out
    );
localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ/BAUD_RATE;
localparam HALF_PERIOD = BAUD_BIT_PERIOD >>1;
localparam THREE_QUART_PERIOD = HALF_PERIOD + (HALF_PERIOD>>1);
localparam DATA_WIDTH = 8;
typedef enum{IDLE,START,DATA,STOP,TRANSMIT} state;
logic [31:0] cycle_counter;
state myState;
logic old_bit;
logic can_switch;
logic [3:0]bit_counter;

// verify start bit from input to half baud
// verify stop bit from half baud to .75 baud

// always_ff @(posedge clk_in)begin 
//     // reset behavior
//     if(rst_in)begin 
//         new_data_out <=0;
//         myState = IDLE;
//         cycle_counter<=0;
//         old_bit <=0;
//         can_switch<=0;
//         bit_counter<=0;
//         data_byte_out <=0;
//     end 
//     // states
//     else begin
//         // idle state
//         if( myState == IDLE && !rx_wire_in)begin
//             cycle_counter <=0;
//             old_bit <=0;
//             can_switch<=0;
//             myState<= START;
//             bit_counter <=0;
//             new_data_out <=0;
//             data_byte_out<=0;

//         // start, data, stop. Do clock counting
//         end else if(myState == START || myState == DATA || myState == STOP) begin
//             // do clock counting no matter what
//             if (cycle_counter == BAUD_BIT_PERIOD-1)begin
//                 cycle_counter <= 0;
//             end
//             else begin
//                 cycle_counter <= cycle_counter + 1; 
//             end

//             if(myState == START)begin
//                 if(can_switch && cycle_counter == (BAUD_BIT_PERIOD -1))begin
//                     myState<=DATA;
//                     can_switch <=0;
//                 end
//                 // verified good bit moves to data state
//                 else if((cycle_counter == (HALF_PERIOD-1)) && old_bit == rx_wire_in)begin
//                     can_switch <= 1;
//                 // waits until state is verified
//                 end else if((cycle_counter < (HALF_PERIOD-1)) && old_bit == rx_wire_in )begin
//                     old_bit <= rx_wire_in;
                
//                 end else if(cycle_counter > (HALF_PERIOD -1 ) && can_switch)begin
//                     can_switch<=1;
//                 end // bad bit, go back to IDLE 
//                 else myState <=IDLE;
//             end
//             else if(myState == DATA)begin
//                 if(bit_counter<DATA_WIDTH)begin
//                     if(cycle_counter == HALF_PERIOD-1)begin
//                         data_byte_out<= {rx_wire_in,data_byte_out[7:1]};
//                         bit_counter<= bit_counter+1;
//                     end

//                 end else begin
//                     if(cycle_counter == BAUD_BIT_PERIOD -1) myState <= STOP;
//                 end

//             end
//             else if(myState == STOP)begin
                
//                 if(cycle_counter == HALF_PERIOD-1)begin
//                     old_bit<=rx_wire_in;
//                 end else if(cycle_counter == THREE_QUART_PERIOD && old_bit == rx_wire_in )begin
//                     // can go straight to transmit if all good
//                     myState<= TRANSMIT;
//                     //new_data_out<=1;
//                 end else if(cycle_counter > HALF_PERIOD-1 ) begin
//                     if(old_bit == rx_wire_in)begin
//                     old_bit <=rx_wire_in;
//                     end else myState<= IDLE;
//                 end
//             end
//         end
//         // transmit
//         else if(myState == TRANSMIT)begin
//             new_data_out <= 1;
//             myState <= IDLE;
//         end

//         else begin
//             new_data_out <=0;
//             myState<= IDLE;
//         end

//     end
// end


always_ff @(posedge clk_in)begin
    if(rst_in) begin
        cycle_counter <=0;

    end
    else if(myState == IDLE) cycle_counter<=0;
    else if(myState == START || myState == DATA || myState == STOP) begin
    if (cycle_counter == BAUD_BIT_PERIOD-1)begin
                cycle_counter <= 0;
            end
            else begin
                cycle_counter <= cycle_counter + 1; 
            end
    end
end

always_ff @(posedge clk_in)begin
    if(rst_in)begin
        new_data_out <=0;
        myState <= IDLE;
        old_bit <=0;
        can_switch<=0;
        bit_counter<=0;
        data_byte_out <=0;
    end
    else begin
        case(myState)

        IDLE: begin
            if(!rx_wire_in)begin
            
            old_bit <=0;
            can_switch<=0;
            myState<= START;
            bit_counter <=0;
            new_data_out <=0;
            data_byte_out<=0;
            end else new_data_out<=0;

        end

        START: begin
            if(can_switch && cycle_counter == (BAUD_BIT_PERIOD -1))begin
                    myState<=DATA;
                    can_switch <=0;
                end
                // verified good bit moves to data state
                else if((cycle_counter == (HALF_PERIOD-1)) && old_bit == rx_wire_in)begin
                    can_switch <= 1;
                // waits until state is verified
                end else if((cycle_counter < (HALF_PERIOD-1)) && old_bit == rx_wire_in )begin
                    old_bit <= rx_wire_in;
                
                end else if(cycle_counter > (HALF_PERIOD -1 ) && can_switch)begin
                    can_switch<=1;
                end // bad bit, go back to IDLE 
                else myState <=IDLE;

        end
        DATA: begin
            if(bit_counter<DATA_WIDTH)begin
                    if(cycle_counter == HALF_PERIOD-1)begin
                        data_byte_out<= {rx_wire_in,data_byte_out[7:1]};
                        bit_counter<= bit_counter+1;
                    end

                end else begin
                    if(cycle_counter == BAUD_BIT_PERIOD -1) myState <= STOP;
                end

        end

        STOP: begin
            if(cycle_counter == (HALF_PERIOD-1) )begin
                    if(rx_wire_in)begin
                    old_bit<=rx_wire_in;
                    end else myState <= IDLE;
            end else if(cycle_counter == (THREE_QUART_PERIOD -1) && old_bit == rx_wire_in )begin
                    // can go straight to transmit if all good
                    myState<= TRANSMIT;
                    //new_data_out<=1;
            end else if(cycle_counter > HALF_PERIOD-1 ) begin
                    if(old_bit == rx_wire_in)begin
                    old_bit <=rx_wire_in;
                    end else myState <=IDLE;
            end // less than half period so we just let clock run until half period

        end

        TRANSMIT: begin
            new_data_out <= 1;
            myState <= IDLE;

        end



        default: myState<=IDLE;

        endcase
    end
end

endmodule // uart_receive

`default_nettype wire