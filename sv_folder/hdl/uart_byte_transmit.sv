`timescale 1ns / 1ps
`default_nettype none

module uart_byte_transmit #(
    parameter NUM_BYTES = 2,
    parameter BAUD_RATE = 9600,
    parameter INPUT_CLOCK_FREQ = 100_000_000
) (
    input wire clk_in,
    input wire rst_in,
    input wire [NUM_BYTES-1:0][6:0] data_in,
    input wire trigger_in,
    output logic busy_out,
    output logic tx_wire_out
);

logic [$clog2(NUM_BYTES):0] queue_position;
logic [NUM_BYTES-1:0][7:0]    byte_queue;

logic [7:0]                 uart_data_in;
logic                       uart_data_valid;
logic                       uart_busy;

always_ff @(posedge clk_in) begin
    // When a new audio sample recieved it is waiting to be sent
    if (rst_in) begin
        queue_position <= 0;
        byte_queue <= 0;
        uart_data_in <= 0;
        uart_data_valid <= 0;
        busy_out <= 0;
    end
    else if (!uart_busy) begin
        if (trigger_in) begin
            // Send first byte (lsb) to uart
            uart_data_in <= {1'b0, data_in[0]}; // lower byte sends a 0 alignment bit
            byte_queue <= {8'b0, {1'b1, data_in[NUM_BYTES-1:1]}}; // high byte sends a 1 alignment bit NOTE: WILL ONLY WORK WITH 2 BYTE
            queue_position <= NUM_BYTES - 1;
            uart_data_valid <= 1;
            busy_out <= 1;
        end
        else if (queue_position != 0 && ~uart_data_valid) begin
            // Handle remaining bytes of transmission (lsb to msb)
            uart_data_in <= byte_queue[0];
            byte_queue <= byte_queue >> 8;
            queue_position <= queue_position - 1;
            uart_data_valid <= 1;
        end
        else if (queue_position == 0 && ~uart_data_valid) begin
            // Transmission End
            busy_out <= 0;
            uart_data_valid <= 0;
        end else begin
            // Make sure uart_data_valid 1 cycle
            uart_data_valid <= 0;
        end
    end
    else begin
        uart_data_valid <= 0;
    end
  end

uart_transmit #(.BAUD_RATE(BAUD_RATE), .INPUT_CLOCK_FREQ(INPUT_CLOCK_FREQ)) uart_transmit_m(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .data_byte_in(uart_data_in),
  .trigger_in(uart_data_valid),
  .busy_out(uart_busy),
  .tx_wire_out(tx_wire_out)
);

endmodule

`default_nettype wire
