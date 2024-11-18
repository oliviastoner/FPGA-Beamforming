module delay_bram (
    input logic clk_in,                   // Clock signal
    input logic rst_in,                   // Reset signal
    input logic valid_in,                 // Signal indicating valid input data
    input logic [15:0] delay_1,           // Delay for microphone 1 in microseconds
    input logic [15:0] delay_2,           // Delay for microphone 2 in microseconds
    input logic [15:0] delay_3,           // Delay for microphone 3 in microseconds
    input logic [15:0] delay_4,           // Delay for microphone 4 in microseconds
    input logic [15:0] audio_in_1,        // Input mic 1 audio sample to store
    input logic [15:0] audio_in_2,        // Input mic 2 audio sample to store
    input logic [15:0] audio_in_3,        // Input mic 3 audio sample to store
    input logic [15:0] audio_in_4,        // Input mic 4 audio sample to store
    output logic [15:0] audio_out,        // Output audio (delayed & summed & shifted)
    output logic valid_out                // If audio_out is valid
);

    xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(2048),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) mic_1_delay (
    .addra(rw_addr_mic1),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(rw_addr_mic1),   // Port B address bus, width determined from RAM_DEPTH
    .dina(audio_in_1),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),     // Port A clock
    .clkb(clk_in),     // Port B clock
    .wea(valid_in),       // Port A write enable
    .web(0),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(), // Port A output register enable
    .regceb(((delay_1 == 0) || (num_cycles > delay_1) || (read_all)) ? 1'b1 : 0), // Port B output register enable
    .douta(),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(audio_out_mic1)    // Port B RAM output data, width determined from RAM_WIDTH
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(2048),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) mic_2_delay (
    .addra(rw_addr_mic2),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(rw_addr_mic2),   // Port B address bus, width determined from RAM_DEPTH
    .dina(audio_in_2),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),     // Port A clock
    .clkb(clk_in),     // Port B clock
    .wea(valid_in),       // Port A write enable
    .web(0),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(), // Port A output register enable
    .regceb(((delay_2 == 0) || (num_cycles > delay_2) || (read_all)) ? 1'b1 : 0), // Port B output register enable
    .douta(),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(audio_out_mic2)    // Port B RAM output data, width determined from RAM_WIDTH
  );

    xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(2048),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) mic_3_delay (
    .addra(rw_addr_mic3),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(rw_addr_mic3),   // Port B address bus, width determined from RAM_DEPTH
    .dina(audio_in_3),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),     // Port A clock
    .clkb(clk_in),     // Port B clock
    .wea(valid_in),       // Port A write enable
    .web(0),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(), // Port A output register enable
    .regceb(((delay_3 == 0) || (num_cycles > delay_3) || (read_all)) ? 1'b1 : 0), // Port B output register enable
    .douta(),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(audio_out_mic3)    // Port B RAM output data, width determined from RAM_WIDTH
  );

    xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(2048),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) mic_4_delay (
    .addra(rw_addr_mic4),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(rw_addr_mic4),   // Port B address bus, width determined from RAM_DEPTH
    .dina(audio_in_4),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),     // Port A clock
    .clkb(clk_in),     // Port B clock
    .wea(valid_in),       // Port A write enable
    .web(0),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(), // Port A output register enable
    .regceb(((delay_4 == 0) || (num_cycles > delay_4) || (read_all)) ? 1'b1 : 0), // Port B output register enable
    .douta(),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(audio_out_mic4)    // Port B RAM output data, width determined from RAM_WIDTH
  );

  evt_counter count_cycles (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .evt_in(valid_in),
    .count_out(num_cycles)
    );

    logic [15:0] rw_addr_mic1, rw_addr_mic2, rw_addr_mic3, rw_addr_mic4 = 0; // Define address pointers for the write/read locations (both same; read first, then write)
    logic [15:0] audio_out_mic1, audio_out_mic2, audio_out_mic3, audio_out_mic4; // Output audio from the read BRAM slot
    logic [31:0] num_cycles; // Counts number of cycles to determine when certain BRAM audio should be incorporated into output
    logic [17:0] summed_audio; // 18-bit audio: all audio summed together
    logic [15:0] shifted_audio; // divide audio by 4: shift right by 2 to preserve 16-bit audio transmission
    logic read_all = 0; // boolean value representing whether you have exceeded the delay of all audios and can now read from all 4 BRAMs
    logic valid_out_r1, valid_out_r2, valid_out_r3, valid_out_r4 = 0; // registers to pipeline the valid_in signal to account for 5-cycle delay from input audio to output audio

    // Reset variables
    always_ff @(posedge clk_in) begin
        if (rst_in) begin

            rw_addr_mic1 <= 0;
            rw_addr_mic2 <= 0;
            rw_addr_mic3 <= 0;
            rw_addr_mic4 <= 0;
            read_all <= 0;
            valid_out_r1 <= 0;
            valid_out_r2 <= 0;
            valid_out_r3 <= 0;
            valid_out_r4 <= 0;
            valid_out <= 0;

        end else if (valid_in) begin

            // wrap around where you are writing to / reading from depending on each mic's delay.
            // this accounts for the fact that the active BRAM depth is equal to the delay for each mic.

            // if there is no delay, you can read from all mics from the start
            if ((delay_1 == 0) && (delay_2 == 0) && (delay_3 == 0) && (delay_4 == 0)) begin

                read_all <= 1; 

            end else begin

                // regardless of angle, mics 2 and 3 always have incremented addresses with nonzero delays
                if (rw_addr_mic2 == (delay_2)) begin
                    rw_addr_mic2 <= 0;
                end else begin
                    rw_addr_mic2 <= rw_addr_mic2 + 1;
                end

                if (rw_addr_mic3 == (delay_3)) begin
                    rw_addr_mic3 <= 0;
                end else begin
                    rw_addr_mic3 <= rw_addr_mic3 + 1;
                end

                // angle is 0-90 degrees: mic1 has no delay; can just transmit received audio
                if (delay_1 == 0) begin

                    // can read from all mics once you exceed the number of valid inputs as the max delay
                    if (num_cycles >= (delay_4)) begin
                        read_all <= 1;
                    end

                    // wrap around where you are writing to / reading from for mic 4
                    if (rw_addr_mic4 == (delay_4)) begin
                        rw_addr_mic4 <= 0;
                    end else begin
                        rw_addr_mic4 <= rw_addr_mic4 + 1;
                    end


                // angle is 90-180 degrees: mic4 has no delay; can just transmit received audio
                end else if (delay_4 == 0) begin

                    // can read from all mics once you exceed the number of valid inputs as the max delay
                    if (num_cycles >= (delay_1)) begin
                        read_all <= 1;
                    end

                    // wrap around where you are writing to / reading from for mic 1
                    if (rw_addr_mic1 == (delay_1)) begin
                        rw_addr_mic1 <= 0;
                    end else begin
                        rw_addr_mic1 <= rw_addr_mic1 + 1;
                    end

                end
            
            end

        end

        // pipeline valid_in signals to valid_out; account for 5-cycle input --> output delay
        // 3 cycles delay for BRAM read, 1 for sum, and 1 for shift
        summed_audio <= (audio_out_mic4 + audio_out_mic3 + audio_out_mic2 + audio_out_mic1);
        audio_out <= (summed_audio >> 2);
        valid_out_r1 <= valid_in;
        valid_out_r2 <= valid_out_r1;
        valid_out_r3 <= valid_out_r2;
        valid_out_r4 <= valid_out_r3;
        valid_out <= valid_out_r4;

        
    end

endmodule
