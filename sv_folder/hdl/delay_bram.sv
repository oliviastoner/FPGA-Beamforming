module delay_bram 
    #(parameter NUM_MICS = 2,
    parameter BITS_AUDIO = 24)
    (
    input wire clk_in,                   // Clock signal
    input wire rst_in,                   // Reset signal
    input wire valid_in,                 // Signal indicating valid input data
    input wire [7:0] delay_1,           // Delay for microphone 1 in microseconds
    input wire [7:0] delay_2,           // Delay for microphone 2 in microseconds
    input wire [7:0] delay_3,           // Delay for microphone 3 in microseconds
    input wire [7:0] delay_4,           // Delay for microphone 4 in microseconds
    input wire signed [BITS_AUDIO-1:0] audio_in_1,        // Input mic 1 audio sample to store
    input wire signed [BITS_AUDIO-1:0] audio_in_2,        // Input mic 2 audio sample to store
    input wire signed [BITS_AUDIO-1:0] audio_in_3,        // Input mic 3 audio sample to store
    input wire signed [BITS_AUDIO-1:0] audio_in_4,        // Input mic 4 audio sample to store
    output logic signed [BITS_AUDIO-1:0] audio_out,        // Output audio (delayed & summed & shifted)
    output logic valid_out                // If audio_out is valid
    );

    logic signed [BITS_AUDIO-1:0] audio_out_mic1, audio_out_mic2, audio_out_mic3, audio_out_mic4; // Output audio from the read BRAM slot
    logic signed [BITS_AUDIO+1:0] summed_audio; // 18-bit audio: all audio summed together
    logic signed [BITS_AUDIO-1:0] shifted_audio; // divide audio by 4: shift right by 2 to preserve 16-bit audio transmission
    logic valid_out_r1, valid_out_r2, valid_out_r3 = 1'b0; // registers to pipeline the valid_in signal to account for 5-cycle delay from input audio to output audio

    logic [10:0] mic_reference_addr;

    logic [10:0] mic_1_delay_addr;
    logic [10:0] mic_2_delay_addr;
    logic [10:0] mic_3_delay_addr;
    logic [10:0] mic_4_delay_addr;

    logic [3:0] orig_delay_done;

    evt_counter count_cycles (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .evt_in(valid_in),
        .count_out(mic_reference_addr)
    );

    always_comb begin
        mic_1_delay_addr = mic_reference_addr - 1 - delay_1;
        mic_2_delay_addr = mic_reference_addr - 1 - delay_2;
        mic_3_delay_addr = mic_reference_addr - 1 - delay_3;
        mic_4_delay_addr = mic_reference_addr - 1 - delay_4;
    end

    xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(BITS_AUDIO),                       // Specify RAM data width
    .RAM_DEPTH(2048),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) mic_1_delay (
    // PORT A
    .addra(mic_1_delay_addr),
    .dina(24'b0), // we only use port A for reads!
    .clka(clk_in),
    .wea(1'b0), // read only
    .ena(1'b1),
    .rsta(rst_in),
    .regcea(1'b1),
    .douta(audio_out_mic1),
    // PORT B
    .addrb(mic_reference_addr),
    .dinb(audio_in_1),
    .clkb(clk_in),
    .web(1'b1), // write always
    .enb(1'b1),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb() // we only use port B for writes!
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(BITS_AUDIO),                       // Specify RAM data width
    .RAM_DEPTH(2048),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) mic_2_delay (
    // PORT A
    .addra(mic_2_delay_addr),
    .dina(24'b0), // we only use port A for reads!
    .clka(clk_in),
    .wea(1'b0), // read only
    .ena(1'b1),
    .rsta(rst_in),
    .regcea(1'b1),
    .douta(audio_out_mic2),
    // PORT B
    .addrb(mic_reference_addr),
    .dinb(audio_in_2),
    .clkb(clk_in),
    .web(1'b1), // write always
    .enb(1'b1),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb() // we only use port B for writes!
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(BITS_AUDIO),                       // Specify RAM data width
    .RAM_DEPTH(2048),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) mic_3_delay (
    // PORT A
    .addra(mic_3_delay_addr),
    .dina(24'b0), // we only use port A for reads!
    .clka(clk_in),
    .wea(1'b0), // read only
    .ena(1'b1),
    .rsta(rst_in),
    .regcea(1'b1),
    .douta(audio_out_mic3),
    // PORT B
    .addrb(mic_reference_addr),
    .dinb(audio_in_3),
    .clkb(clk_in),
    .web(1'b1), // write always
    .enb(1'b1),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb() // we only use port B for writes!
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(BITS_AUDIO),                       // Specify RAM data width
    .RAM_DEPTH(2048),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) mic_4_delay (
    // PORT A
    .addra(mic_4_delay_addr),
    .dina(24'b0), // we only use port A for reads!
    .clka(clk_in),
    .wea(1'b0), // read only
    .ena(1'b1),
    .rsta(rst_in),
    .regcea(1'b1),
    .douta(audio_out_mic4),
    // PORT B
    .addrb(mic_reference_addr),
    .dinb(audio_in_4),
    .clkb(clk_in),
    .web(1'b1), // write always
    .enb(1'b1),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb() // we only use port B for writes!
    );

    // Reset variables
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            summed_audio <= 0;
            audio_out <= 0;
            orig_delay_done <= 0;
            valid_out_r1 <= 0;
            valid_out_r2 <= 0;
            valid_out_r3 <= 0;
        end else begin
            if (mic_1_delay_addr == 0) orig_delay_done[0] <= 1'b1;
            if (mic_2_delay_addr == 0) orig_delay_done[1] <= 1'b1;
            if (mic_3_delay_addr == 0) orig_delay_done[2] <= 1'b1;
            if (mic_4_delay_addr == 0) orig_delay_done[3] <= 1'b1;

            // pipeline valid_in signals to valid_out; account for 5-cycle input --> output delay
            // 3 cycles delay for BRAM read, 1 for sum, and 1 for shift
            summed_audio <= ($signed(audio_out_mic4) + $signed(audio_out_mic3) + $signed(audio_out_mic2) + $signed(audio_out_mic1));
            audio_out <= (summed_audio >>> $clog2(NUM_MICS));
            valid_out_r1 <= orig_delay_done[NUM_MICS-1:0] == {NUM_MICS{1'b1}};
            valid_out_r2 <= valid_out_r1;
            valid_out_r3 <= valid_out_r2;
        end
    end

    assign valid_out = valid_out_r3;

endmodule
