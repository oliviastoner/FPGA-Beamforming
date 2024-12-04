module pdm #( parameter BIT_WIDTH = 24)
(   input wire clk_in, //100MHz clock
    input wire sample_in,                 // oversampled clock/data clock (128*fs)
    input logic rst_in,                 // Active-high reset
    input logic signed [BIT_WIDTH-1:0] audio_in, // 24-bit signed input audio signal
    output logic pdm_out             // 1-bit PDM output
);
    localparam signed [BIT_WIDTH-1:0] NEG_FEEDBACK = 1<<(BIT_WIDTH-1); // minimum
    localparam signed [BIT_WIDTH-1:0] POS_FEEDBACK = (1<<(BIT_WIDTH-1)) - 1; // maximum
    
    // Internal registers
    
    logic signed [BIT_WIDTH:0] error;  // 25-bit error feedback
    logic prev_sample_in;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            
            error <= 0;
            pdm_out <= 0;
            prev_sample_in<=0;
        end else begin
            // only do stuff on rising edge
            if(sample_in && !prev_sample_in)begin
            // Determine PDM output based on current error
            pdm_out <= (error >= audio_in) ? 1'b0 : 1'b1;
            error   <= error - audio_in + ((audio_in >= error) ? POS_FEEDBACK : NEG_FEEDBACK); // Apply  feedback
            end
            prev_sample_in<=sample_in;
        end
    end
endmodule
