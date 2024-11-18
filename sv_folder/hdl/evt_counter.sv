`default_nettype none
module evt_counter
  #(parameter MAX_COUNT = 100_000_000)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          evt_in,
    output logic[15:0]  count_out = 16'b0
  );
 
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        count_out <= 16'b0;
    end else begin
        if (evt_in == 1) begin
            if (count_out == (MAX_COUNT-1)) begin
              count_out <= 0;
            end else begin
              count_out <= count_out + 1;
            end
        end
    end
  end
endmodule
`default_nettype wire