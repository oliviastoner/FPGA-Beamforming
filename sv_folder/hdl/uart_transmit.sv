module uart_transmit #( parameter INPUT_CLOCK_FREQ = 100000000, 
                        parameter BAUD_RATE = 115200 
                        )
                        (   input wire clk_in, // clock for mod
                            input wire rst_in, // reset mod, active high
                            input wire [7:0] data_byte_in, // byte to transmit, only read when transmission starts
                            input wire trigger_in, // starts byte transmission, ignore if sending message
                            output logic busy_out, // hold high while module transmitting
                            output logic tx_wire_out // serial output signal
);
localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ/BAUD_RATE;
localparam DATA_WIDTH = 10;
logic [9:0] store_data;
logic [31:0] cycle_counter;
logic [4:0] bit_counter;


always_ff @(posedge clk_in)begin
    // reset things
    if(rst_in)begin
        bit_counter <=0;
        cycle_counter<=0;
        busy_out<=0;
        tx_wire_out<=1;
        store_data <= 10'b0;

    end
    else begin
        // start transmission
        if(trigger_in && ~busy_out)begin
            busy_out<=1;
            cycle_counter <=0;
            bit_counter<=0;
            // put transmission data in order of transmission
            // includes start and stop, relevant bit at 0 index
            tx_wire_out<= 0;
            store_data <= {1'b1, data_byte_in};
        end
        // doing transmission
        else if(busy_out)begin
            // deal with clocking cycles
           if (cycle_counter == BAUD_BIT_PERIOD-1)begin
                cycle_counter <= 0;
            end
            else begin
                cycle_counter <= cycle_counter + 1; 
            end
            // go through each bit
            if(bit_counter<DATA_WIDTH-1)begin
                if(cycle_counter == BAUD_BIT_PERIOD-1)begin
                    tx_wire_out<= store_data[0];
                    store_data <= {1'b0,store_data[9:1]};
                    bit_counter<= bit_counter+1;
                end

            end
            // deal with stopping transmission
            else begin
                // have to wait for cycle to finish
                if(cycle_counter == BAUD_BIT_PERIOD-1)begin
                    // actually finish transmission
                    busy_out<=0; // no longer busy, transmission done
                    tx_wire_out<=1; // hold data out 
                    
                    // reset bit_counter
                    bit_counter<=0;
                end


             end


        end
        // transient state
        else begin
            // keep wire high, make sure no extra 0s
            tx_wire_out <=1;
        end

    end


end
endmodule