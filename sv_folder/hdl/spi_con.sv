module spi_con
     #(parameter DATA_WIDTH = 8,
       parameter DATA_CLK_PERIOD = 100
      )
      (input wire   clk_in, //system clock (100 MHz)
       input wire   rst_in, //reset in signal
       input wire   [DATA_WIDTH-1:0] data_in, //data to send
       input wire   trigger_in, //start a transaction
       output logic [DATA_WIDTH-1:0] data_out, //data received!
       output logic data_valid_out, //high when output data is present.
 
       output logic chip_data_out, //(COPI)
       input wire   chip_data_in, //(CIPO)
       output logic chip_clk_out, //(DCLK)
       output logic chip_sel_out // (CS)
      );
  //your code 
    logic [DATA_WIDTH -1:0]store_data_in;
   
    logic [31:0] clock_counter; // assuming uint8 is enough to cover clock period count
    localparam CLOCK_SWITCH = DATA_CLK_PERIOD>>1; // Divide clock_period by 2 to know when to switch
    localparam CLOCK_PERIOD = CLOCK_SWITCH+CLOCK_SWITCH;//(DATA_CLK_PERIOD - DATA_CLK_PERIOD%2);
    logic [31:0] rising_edge_events;

  
  always_ff @(posedge clk_in)begin
    // reset things
    if (rst_in)begin
        // set most outputs to 0
        data_out <=0;
        data_valid_out <= 0;
        chip_data_out <= 0;
        chip_clk_out <= 0;
        // CS is held high at rest
        chip_sel_out <= 1;

        // initialize different counters
       
        clock_counter <= 0; 
        // data_transferred_count = 0;
        rising_edge_events<=0;

    end 
    // check out transaction stuff
    else begin
        // waiting for trigger
        if(chip_sel_out == 1)begin
            if (trigger_in) begin
                // tell peripheral transaction is starting
                chip_sel_out <=0;
                
                chip_data_out <= data_in[DATA_WIDTH-1];
                store_data_in <={data_in[DATA_WIDTH-2:0],1'b0};
                
                chip_clk_out<=0;
                rising_edge_events<=0;
                clock_counter<=0;

            end 
            else data_valid_out<=0;
        end
        // transaction happening
        else begin 
            if (clock_counter == CLOCK_PERIOD-1)begin
                clock_counter <= 0;
            end
            else begin
                clock_counter <= clock_counter + 1; 
            end

            if( rising_edge_events < DATA_WIDTH) begin
                // switch to DCLK low
                if(clock_counter == CLOCK_PERIOD-1 )begin
                    chip_clk_out <= 0;
                   
                    // place another piece of data for SPI on COPI line when clock goes HIGH -> LOW
                    chip_data_out <=store_data_in[DATA_WIDTH-1];
                    store_data_in <= {store_data_in[DATA_WIDTH-2:0],1'b0};
                    //rising_edge_events <= rising_edge_events +1;
                    
                end 
                // switch to DCLK high
                else if(clock_counter == CLOCK_SWITCH-1)begin
                    // deal with clock
                    chip_clk_out <=1;

                    // place another piece of data for SPI on COPI line when clock goes HIGH -> LOW
                    data_out <= {data_out[DATA_WIDTH-2:0],chip_data_in};

                    rising_edge_events <= rising_edge_events +1;
                end 
         
        end
            // do CS right after the after final cycle is done
            else if (clock_counter == CLOCK_PERIOD-1)begin

                chip_sel_out<=1;
                rising_edge_events<=0;
                chip_clk_out<=0;
                data_valid_out <= 1;
                clock_counter<=0;
            end

    end

  end
  end

endmodule