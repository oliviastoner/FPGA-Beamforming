`timescale 1ns / 1ps
`default_nettype none

module uart_transmit #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
) (
    input  wire        clk_in,
    input  wire        rst_in,
    input  wire  [7:0] data_byte_in,
    input  wire        trigger_in,
    output logic       busy_out,
    output logic       tx_wire_out
);

localparam UART_BIT_PERIOD = int'($floor(INPUT_CLOCK_FREQ / BAUD_RATE));
localparam UART_RATE_COUNTER_SIZE = $clog2(UART_BIT_PERIOD);
localparam [UART_RATE_COUNTER_SIZE:0] UART_RATE_COUNTER_LIMIT = UART_BIT_PERIOD - 1;

logic [UART_RATE_COUNTER_SIZE:0] uart_rate_count;
logic [4:0] uart_bit_count;
logic [8:0] data_to_transmit;

always_ff @(posedge clk_in) begin
// Handle rst
if (rst_in) begin
    busy_out <= 0;
    tx_wire_out <= 1;
    uart_rate_count <= 0;
    uart_bit_count <= 0;
    data_to_transmit <= 0;
end else begin
    if (!busy_out && trigger_in) begin
        data_to_transmit <= {1'b1, data_byte_in};   // Stop bit padded
        busy_out <= 1;
        tx_wire_out <= 0;                           // TX low = start
        uart_bit_count <= 0;
        uart_rate_count <= 0;
    end

    if (busy_out && uart_rate_count == UART_BIT_PERIOD - 1) begin
        if (uart_bit_count == 9) begin
            busy_out <= 0;
            uart_bit_count <= 0;
        end else begin
            tx_wire_out <= data_to_transmit[0];
            data_to_transmit <= data_to_transmit >> 1;
            uart_bit_count <= uart_bit_count + 1;
        end
        uart_rate_count <= 0;
    end else if (busy_out) begin
        uart_rate_count <= uart_rate_count + 1;
    end
end

end



endmodule  // uart_transmit

`default_nettype wire
