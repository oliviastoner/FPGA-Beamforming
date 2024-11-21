module i2s_audio_out
    #( parameter BIT_WIDTH = 24

    ) 
    (
    input logic rst,                // Active-high reset
    input logic sck,                  // External serial clock (~40 kHz)
    input logic [BIT_WIDTH-1:0] audio_sample,  // Single 24-bit audio sample input
    input logic sample_valid,         // Indicates new audio sample is available
    output logic sd                   // Serial data output
);

    // Internal state variables
    logic [23:0] shift_reg;           // Shift register for serializing data
    logic [4:0] bit_counter;          // Counter for tracking bit position (0 to 23)
    logic transmit;

    // Load new sample into the shift register
    always_ff @(posedge sck) begin
        if (rst) begin
            shift_reg <= 24'b0;
            bit_counter <= 0;
            sd <= 0;
            transmit<=0;
            
        end else begin

            // transmitting audio sample
            if(transmit)begin
                // Keep counter of how many bits of audio we transmitted
                if (bit_counter == BIT_WIDTH-1) begin
                    bit_counter <= 0; // Reset counter after transmitting 24 bits
                    transmit<=0;
                end else begin
                    bit_counter <= bit_counter + 1;
                end

                // send out MSB of audio sample
                sd <= shift_reg[BIT_WIDTH-1];
                shift_reg<={shift_reg[BIT_WIDTH-2:0],1'b0};//shift the sample
            end
            // waiting for sample
            else begin
                // Load new audio sample
                if (sample_valid) begin
                    sd<=audio_sample[BIT_WIDTH-1];
                    shift_reg<={audio_sample[BIT_WIDTH-2:0],1'b0};//shift the sample
                    transmit<=1;
                    bit_counter <= 1;
                end
                else begin
                sd<=0; // send silence
                end
            end


        end
    end


endmodule
