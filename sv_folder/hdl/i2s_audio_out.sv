module i2s_single_channel (
    input logic clk,                  // System clock (100 MHz)
    input logic rst,                // Active-high reset
    input logic sck,                  // External serial clock (~40 kHz)
    input logic [23:0] audio_sample,  // Single 24-bit audio sample input
    input logic sample_valid,         // Indicates new audio sample is available
    output logic sd                   // Serial data output
);

    // Internal state variables
    logic [23:0] shift_reg;           // Shift register for serializing data
    logic [4:0] bit_counter;          // Counter for tracking bit position (0 to 23)

    // Edge detection for SCK
    logic prev_sck;                // previous sck, last cycle
    logic sck_rising_edge;            // High for one clk cycle on SCK rising edge

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_sck <= 0;
        end else begin
            prev_sck <= sck;
        end
    end

    assign sck_rising_edge = sck & ~prev_sck; // Rising edge detection

    // Load new sample into the shift register
    always_ff @(posedge clk) begin
        if (rst) begin
            shift_reg <= 24'b0;
        end else if (sample_valid) begin
            shift_reg <= audio_sample; // Load new audio sample
        end
    end

    // Bit counter to track the current bit being transmitted
    always_ff @(posedge clk) begin
        if (rst) begin
            bit_counter <= 0;
        end else if (sck_rising_edge) begin
            if (bit_counter == 23) begin
                bit_counter <= 0; // Reset counter after transmitting 24 bits
            end else begin
                bit_counter <= bit_counter + 1;
            end
        end
    end

    // Serialize data onto the SD line (MSB first)
    always_ff @(posedge clk) begin
        if (rst) begin
            sd <= 0;
        end else if (sck_rising_edge) begin
            sd <= shift_register[23]; // Output bits MSB-first
            shift_register<={shift_register[22:0],1'b0};//shift the sample
        end
    end

endmodule
