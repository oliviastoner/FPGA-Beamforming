`default_nettype none  // prevents system from inferring an undeclared logic (good practice)

module top_level (
    input  wire         clk_100mhz,  // 100 MHz onboard clock
    input  wire  [15:0] sw,          // all 16 input slide switches
    input  wire  [ 3:0] btn,         // all four momentary button switches
    output logic [15:0] led,         // 16 green output LEDs (located right above switches)
    output logic [ 2:0] rgb0,        // RGB channels of RGB LED0
    output logic [ 2:0] rgb1,        // RGB channels of RGB LED1
    inout  wire         tdm_data_in, // TDM INPUT IN PMODA
    output logic        tdm_ws_out,
    output logic        tdm_sck_out,
    input  wire         uart_rxd,    // UART computer-FPGA
    output logic        uart_txd,     // UART FPGA-computer
    output logic [3:0] ss0_an,  //anode control for upper four digits of seven-seg display
    output logic [3:0] ss1_an,  //anode control for lower four digits of seven-seg display
    output logic [6:0] ss0_c,  //cathode controls for the segments of upper four digits
    output logic [6:0] ss1_c  //cathode controls for the segments of lower four digits
);

  //shut up those rgb LEDs for now (active high):
  assign rgb1 = 0;  //set to 0.
  assign rgb0 = 0;  //set to 0.

  //have btnd control system reset
  logic sys_rst;
  assign sys_rst = btn[0];

  // -- CLOCKING --
  // Create a rough clock -- should be replaced by actual clock later
  localparam MICS = 2;
  localparam CYCLES_PER_DATA_CLK = 50;
  localparam CYCLES_PER_HALF_DATA_CLK = CYCLES_PER_DATA_CLK / 2;
  localparam DATA_CLK_CYCLES_PER_MIC_CLK = 64; // Audio will be clocked at 31.25 kHz
  localparam CYCLES_TILL_MIC_CLK_VALID = 2_000_000;

  logic [4:0] data_clk_count;
  logic [31:0] mic_trigger_count;
  logic [31:0] clk_elapsed;
  logic data_clk;
  logic data_clk_prev;
  logic data_clk_edge;
  logic mic_trigger;

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      data_clk_count <= 0;
      data_clk <= 0;
      data_clk_prev <= 0;
    end else begin
      if (data_clk_count == CYCLES_PER_HALF_DATA_CLK - 1) begin
        data_clk_count <= 0;
        data_clk <= ~data_clk;
      end else begin
        data_clk_count <= data_clk_count + 1;
      end

      data_clk_prev <= data_clk;
    end
  end

  assign data_clk_edge = data_clk && ~data_clk_prev;

  counter_neg counter_mic_trigger (
      .clk_in(data_clk),
      .rst_in(sys_rst),
      .period_in(DATA_CLK_CYCLES_PER_MIC_CLK),
      .count_out(mic_trigger_count)
  );

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) clk_elapsed <= 0;
    else if (clk_elapsed < CYCLES_TILL_MIC_CLK_VALID) clk_elapsed <= clk_elapsed + 1;
  end

  assign mic_trigger = mic_trigger_count == (DATA_CLK_CYCLES_PER_MIC_CLK - 1);

  assign tdm_sck_out = data_clk;
  assign tdm_ws_out = mic_trigger && (clk_elapsed == CYCLES_TILL_MIC_CLK_VALID);

  // -- TDM INPUT --
  // TDM Microphone Input
  logic [23:0] audio_out[MICS];
  logic audio_valid_prev;
  logic audio_valid_out;

  tdm_receive #(.SLOTS(2)) tdm(
    .sck_in(data_clk),
    .ws_in(mic_trigger),
    .sd_in(tdm_data_in),
    .rst_in(sys_rst),
    .audio_out(audio_out),
    .audio_valid_out(audio_valid_out)
  );

  // -- Switch Angle Calc --
  // Switch -> Angle -> Ascii and delays
  logic        [7:0] angle;
  logic        [11:0] ascii_rep;

  logic signed [7:0] delay_1;
  logic signed [7:0] delay_2;
  logic signed [7:0] delay_3;
  logic signed [7:0] delay_4;

  assign angle = sw[7:0];

  ang_to_ascii ang_to_ascii (
    .angle_in(angle),
    .ascii_out(ascii_rep)
  );

  angle_delay_lut angle_delay_lut (
    .angle_in(angle),
    .delay_1_out(delay_1),
    .delay_2_out(delay_2),
    .delay_3_out(delay_3),
    .delay_4_out(delay_4)
  );

  // Drive the 7 Segment Controller
  logic [31:0] display_val;

  always_ff @(posedge clk_100mhz) begin
    audio_valid_prev <= audio_valid_out;

    if (sys_rst) begin
      display_val <= 0;
    end
    // For Testing -- Display Audio Sample when sw[13] High
    else if (sw[13] && dss_valid_out && data_clk_edge && ~btn[1]) begin
      display_val <= {8'b0, dss_audio_out};
    end
    else if (~sw[13]) display_val <= {20'b0, ascii_rep};
  end

  logic [ 6:0] ss_c;  //used to grab output cathode signal for 7s leds
  seven_segment_controller mssc(.clk_in(clk_100mhz),
                                 .rst_in(sys_rst),
                                 .val_in(display_val),
                                 .cat_out(ss_c),
                                 .an_out({ss0_an, ss1_an}));

  assign ss0_c = ss_c;  //control upper four digit's cathodes!
  assign ss1_c = ss_c;  //same as above but for lower four digits!

  // -- Delay Sum Shift Alg --
  // TODO: Delay, Sum, Shift
  logic signed [23:0] dss_audio_out;
  logic dss_valid_out;

  delay_bram delay_sum_shift (
    .clk_in(data_clk),
    .rst_in(sys_rst),
    .valid_in(audio_valid_out),
    .delay_1(delay_1),
    .delay_2(delay_2),
    .delay_3(delay_3),
    .delay_4(delay_4),
    .audio_in_1(audio_out[0]),
    .audio_in_2(audio_out[1]),
    .audio_in_3(24'sb0),
    .audio_in_4(24'sb0),
    .audio_out(dss_audio_out),
    .valid_out(dss_valid_out)
  );

  // -- Output --
  // This block of the top level controls outputting via uart
  // Toggle sw[15] to enable uart transmission
  // There are two modes of uart transmission enabled by sw[14]
  //   - Single Mic [low]  transmits 31.25 kHz 16 bit data
  //   - Dual Mic   [high] transmits 15.27 kHz 16 bit data

  logic                      audio_sample_waiting;
  logic                      is_even_sample;  // flag allows for sending 1/2 sample rate when sw[15]
  logic                      enable_uart;
  logic                      use_dual_uart;

  logic [15:0]               uart_single_data_in;
  logic [31:0]               uart_dual_data_in;
  logic                      uart_data_valid;

  logic                      uart_busy;
  logic                      uart_single_busy;
  logic                      uart_dual_busy;

  logic                      uart_single_txd;
  logic                      uart_dual_txd;

  assign enable_uart = sw[15];
  assign use_dual_uart = sw[14];
  assign uart_busy = use_dual_uart ? uart_dual_busy : uart_single_busy;
  assign uart_txd = use_dual_uart ? uart_dual_txd : uart_single_txd;

  always_ff @(posedge clk_100mhz) begin
    // When a new audio sample received it is waiting to be sent
    if (sys_rst) begin
      audio_sample_waiting <= 0;
      uart_single_data_in <= 0;
      uart_dual_data_in <= 0;
      uart_data_valid <= 0;
      is_even_sample <= 0;
    end
    else if ((dss_valid_out && data_clk_edge && ~use_dual_uart) || (audio_valid_out && ~audio_valid_prev && use_dual_uart)) begin
      if (!uart_busy) begin
        // Sent via uart if not busy
        uart_data_valid <= 1;
        audio_sample_waiting <= 0;
      end else begin
        // Flag that sample waiting if busy
        audio_sample_waiting <= 1;
      end

      // Update uart data inputs with the new samples
      uart_single_data_in <= dss_audio_out[23:8];
      uart_dual_data_in <= {audio_out[1][23:8], audio_out[0][23:8]};
      // Toggle is_even_sample on each new sample
      is_even_sample <= ~is_even_sample;
    end else if (!uart_busy && audio_sample_waiting) begin
        // Trigger uart when no longer busy and sample waiting
        audio_sample_waiting <= 0;
        uart_data_valid <= 1;
    end else begin
        audio_sample_waiting <= 0;
        uart_data_valid <= 0;
    end
  end

  // UART Transmitter to Computer
  // Done: instantiate the UART transmitter you just wrote, using the input signals from above.
  uart_byte_transmit #(.NUM_BYTES(2), .BAUD_RATE(921_600)) uart_transmit_single_m (
  .clk_in(clk_100mhz),
  .rst_in(sys_rst),
  .data_in(uart_single_data_in),
  .trigger_in(uart_data_valid && ~use_dual_uart && enable_uart),
  .busy_out(uart_single_busy),
  .tx_wire_out(uart_single_txd)
  );

  uart_byte_transmit #(.NUM_BYTES(4), .BAUD_RATE(921_600)) uart_transmit_dual_m (
  .clk_in(clk_100mhz),
  .rst_in(sys_rst),
  .data_in(uart_dual_data_in),
  .trigger_in(uart_data_valid && use_dual_uart && is_even_sample && enable_uart),
  .busy_out(uart_dual_busy),
  .tx_wire_out(uart_dual_txd)
  );

endmodule  // top_level

`default_nettype wire
