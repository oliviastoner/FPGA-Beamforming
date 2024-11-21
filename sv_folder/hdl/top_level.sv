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
  logic mic_trigger;

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      data_clk_count <= 0;
      data_clk <= 0;
    end else begin
      if (data_clk_count == CYCLES_PER_HALF_DATA_CLK - 1) begin
        data_clk_count <= 0;
        data_clk <= ~data_clk;
      end else begin
        data_clk_count <= data_clk_count + 1;
      end
    end
  end

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
  // TODO: TDM Microphone Input
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
  // TODO: Switch Angle Calc and LUT
  logic [31:0] display_val;

  always_ff @(posedge clk_100mhz) begin
    audio_valid_prev <= audio_valid_out;

    if (sys_rst) begin
      display_val <= 0;
    end
    else if (audio_valid_out && ~audio_valid_prev && ~btn[1]) begin
      display_val <= {8'b0, audio_out[0]};
    end
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

  // -- Output --
  // TODO: Outputs
  logic                      audio_sample_waiting;

  logic [15:0]               uart_data_in;
  logic                      uart_data_valid;
  logic                      uart_busy;

  always_ff @(posedge clk_100mhz) begin
    // When a new audio sample recieved it is waiting to be sent
    if (sys_rst) begin
      audio_sample_waiting <= 0;
      uart_data_in <= 0;
      uart_data_valid <= 0;
    end
    else if (audio_valid_out && ~audio_valid_prev) begin
      if (!uart_busy) begin
        // Sent via uart if not busy
        uart_data_in <= audio_out[0][23:8];
        uart_data_valid <= 1;
        audio_sample_waiting <= 0;
      end else begin
        // Flag that sample waiting if busy
        uart_data_in <= audio_out[0][23:8];
        audio_sample_waiting <= 1;
      end
    end else if (!uart_busy && audio_sample_waiting) begin
        // Trigger uart when no longer busy and sample waiting
        audio_sample_waiting <= 0;
        uart_data_valid <= 1;
    end else begin
        audio_sample_waiting <= 0;
        uart_data_valid <= 0;
    end
  end

  // UART Transmitter to FTDI2232
  // Done: instantiate the UART transmitter you just wrote, using the input signals from above.
  uart_byte_transmit #(.NUM_BYTES(2), .BAUD_RATE(921_600)) uart_transmit_m(
  .clk_in(clk_100mhz),
  .rst_in(sys_rst),
  .data_in(uart_data_in),
  .trigger_in(uart_data_valid),
  .busy_out(uart_busy),
  .tx_wire_out(uart_txd)
  );

  // assign led[0] = audio_valid_out;

  // logic [2:0] audio_sample_waiting;
  // logic [15:0] audio_sample_queue;

  // logic [7:0] uart_data_in;
  // logic       uart_data_valid;
  // logic       uart_busy;

  // always_ff @(posedge clk_100mhz) begin
  //     // When a new audio sample recieved, 3 bytes are waiting to be sent
  //     if (audio_valid_out && ~audio_valid_prev) begin
  //       audio_sample_waiting <= 3;
  //       audio_sample_queue <= audio_out1;
  //     end

  //     if (!uart_busy && audio_sample_waiting != 0 && sw[0]) begin
  //       audio_sample_waiting <= audio_sample_waiting - 1;
  //       uart_data_in <= audio_sample_queue[7:0];
  //       audio_sample_queue <= audio_sample_queue >> 8;
  //       uart_data_valid <= 1;
  //     end else begin
  //       uart_data_valid <= 0;
  //     end
  //  end

  // localparam INPUT_CLOCK_FREQ = 100000000;
  // localparam BAUD_RATE = 921600;

  // uart_transmit #(
  //     .INPUT_CLOCK_FREQ(INPUT_CLOCK_FREQ),
  //     .BAUD_RATE(BAUD_RATE)
  // ) uart_transmit_mod (
  //     .clk_in(clk_100mhz),
  //     .rst_in(sys_rst),
  //     .data_byte_in(uart_data_in),
  //     .trigger_in(uart_data_valid),
  //     .busy_out(uart_busy),
  //     .tx_wire_out(uart_txd)
  // );


  // Checkoff 1: Microphone->SPI->UART->Computer

  // 8kHz trigger using a week 1 counter!
/*
  // DONE: set this parameter to the number of clock cycles between each cycle of an 8kHz trigger
  localparam CYCLES_PER_TRIGGER = 12500;  //  CHANGED

  logic [31:0] trigger_count;
  logic        spi_trigger;

  counter counter_8khz_trigger (
      .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .period_in(CYCLES_PER_TRIGGER),
      .count_out(trigger_count)
  );

  // DONE: use the trigger_count output to make spi_trigger a single-cycle high with 8kHz frequency
  assign spi_trigger = trigger_count == (CYCLES_PER_TRIGGER - 1);  //  CHANGED

  // SPI Controller on our ADC

  // DONE: bring in the instantiation of your SPI controller from the end of last week's lab!
  // you updated some parameter values based on the MCP3008's specification, bring those updates here.
  // see: "The Whole Thing", last checkoff from Week 02
  parameter ADC_DATA_WIDTH = 17;  // CHANGED
  parameter ADC_DATA_CLK_PERIOD = 50;  // CHANGED

  // SPI interface controls
  logic [ADC_DATA_WIDTH-1:0] spi_write_data;
  logic [ADC_DATA_WIDTH-1:0] spi_read_data;
  logic                      spi_read_data_valid;

  // Since now we're only ever reading from one channel, spi_write_data can stay constant.
  // DONE: Assign it a proper value for accessing CH7!
  assign spi_write_data = 17'b11111_0000_0000_0000;  // MUST CHANGE

  //built last week:
  spi_con #(
      .DATA_WIDTH(ADC_DATA_WIDTH),
      .DATA_CLK_PERIOD(ADC_DATA_CLK_PERIOD)
  ) my_spi_con (
      .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .data_in(spi_write_data),
      .trigger_in(spi_trigger),
      .data_out(spi_read_data),
      .data_valid_out(spi_read_data_valid),  //high when output data is present.
      .chip_data_out(copi),  //(serial dout preferably)
      .chip_data_in(cipo),  //(serial din preferably)
      .chip_clk_out(dclk),
      .chip_sel_out(cs)
  );

  logic [7:0] audio_sample;
  // DONE: store your audio sample from the SPI controller, only when the data is valid!
  always_comb begin
    if (spi_read_data_valid) audio_sample = spi_read_data[9:2];
  end


  // Line out Audio
  logic [7:0] line_out_audio;

  // for checkoff 1: pass-through the audio sample we captured from SPI!
  // also, make the value much much smaller so that we don't kill our ears :)
  assign line_out_audio = audio_sample >> 3;

  logic spk_out;
  // DONE: instantiate a pwm module to drive spk_out based on the
  pwm speak_mod (
      .clk_in (clk_100mhz),
      .rst_in (sys_rst),
      .dc_in  (douta),
      .sig_out(spk_out)
  );


  // set both output channels equal to the same PWM signal!
  assign spkl = spk_out;
  assign spkr = spk_out;



  // Data Buffer SPI-UART
  // TODO: write some sequential logic to keep track of whether the
  //  current audio_sample is waiting to be sent,
  //  and to set the uart_transmit inputs appropriately.
  //  **be sure to only ever set uart_data_valid high if sw[0] is on,
  //  so we only send data on UART when we're trying to receive it!
  logic       audio_sample_waiting;

  logic [7:0] uart_data_in;
  logic       uart_data_valid;
  logic       uart_busy;

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      audio_sample_waiting <= 0;
      uart_data_valid <= 0;
    end  // SPI spits out new sample
    else if (spi_read_data_valid && !audio_sample_waiting) begin
      audio_sample_waiting <= 1;
      uart_data_in <= audio_sample;


    end else if (!uart_busy && audio_sample_waiting && sw[0]) begin
      // set to one when not busy
      uart_data_valid <= 1;
      audio_sample_waiting <= 0;
    end else uart_data_valid <= 0;




  end

  // UART Transmitter to FTDI2232
  // DONE: instantiate the UART transmitter you just wrote, using the input signals from above.
  localparam INPUT_CLOCK_FREQ = 100000000;
  localparam BAUD_RATE = 115200;
  uart_transmit #(
      .INPUT_CLOCK_FREQ(INPUT_CLOCK_FREQ),
      .BAUD_RATE(BAUD_RATE)
  ) uart_transmit_mod (
      .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .data_byte_in(uart_data_in),
      .trigger_in(uart_data_valid),
      .busy_out(uart_busy),
      .tx_wire_out(uart_txd)
  );


  // Checkoff 2: leave this stuff commented until you reach the second checkoff page!


  // Synchronizer
  // TODO: pass your uart_rx data through a couple buffers,
  // save yourself the pain of metastability!
  logic uart_rx_buf0, uart_rx_buf1;

  // UART Receiver
  // TODO: instantiate your uart_receive module, connected up to the buffered uart_rx signal
  // declare any signals you need to keep track of!
  logic uart_receive_out;
  logic [7:0] uart_receive_byte;

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      uart_rx_buf0 <= 0;
      uart_rx_buf1 <= 0;
    end else begin
      uart_rx_buf0 <= uart_rxd;
      uart_rx_buf1 <= uart_rx_buf0;
    end
  end

  uart_receive #(
      .INPUT_CLOCK_FREQ(INPUT_CLOCK_FREQ),
      .BAUD_RATE(BAUD_RATE)
  ) uart_receive_mod (
      .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .rx_wire_in(uart_rx_buf1),
      .new_data_out(uart_receive_out),
      .data_byte_out(uart_receive_byte)
  );

  // BRAM Memory
  // We've configured this for you, but you'll need to hook up your address and data ports to the rest of your logic!

  parameter BRAM_WIDTH = 8;
  parameter BRAM_DEPTH = 40_000;  // 40_000 samples = 5 seconds of samples at 8kHz sample
  parameter ADDR_WIDTH = $clog2(BRAM_DEPTH);

  // only using port a for reads: we only use dout
  logic [BRAM_WIDTH-1:0] douta;
  logic [ADDR_WIDTH-1:0] addra;

  // only using port b for writes: we only use din
  logic [BRAM_WIDTH-1:0] dinb;
  logic [ADDR_WIDTH-1:0] addrb;

  assign dinb = uart_receive_byte;

  xilinx_true_dual_port_read_first_2_clock_ram #(
      .RAM_WIDTH(BRAM_WIDTH),
      .RAM_DEPTH(BRAM_DEPTH)
  ) audio_bram (
      // PORT A
      .addra(addra),
      .dina(0),  // we only use port A for reads!
      .clka(clk_100mhz),
      .wea(1'b0),  // read only
      .ena(1'b1),
      .rsta(sys_rst),
      .regcea(1'b1),
      .douta(douta),
      // PORT B
      .addrb(addrb),
      .dinb(dinb),
      .clkb(clk_100mhz),
      .web(1'b1),  // write always
      .enb(1'b1),
      .rstb(sys_rst),
      .regceb(1'b1),
      .doutb()  // we only use port B for writes!
  );


  // Memory addressing
  // TODO: instantiate an event counter that increments once every 8000th of a second
  // for addressing the (port A) data we want to send out to LINE OUT!

  evt_counter #(
      .MAX_COUNT(BRAM_DEPTH)
  ) addra_counter (
      .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .evt_in(spi_trigger),
      .count_out(addra)
  );


  // TODO: instantiate another event counter that increments with each new UART data byte
  // for addressing the (port B) place to send our UART_RX data!
  evt_counter #(
      .MAX_COUNT(BRAM_DEPTH)
  ) addrb_counter (
      .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .evt_in(uart_receive_out),
      .count_out(addrb)
  );

  // reminder TODO: go up to your PWM module, wire up the speaker to play the data from port A dout.
  */


endmodule  // top_level

`default_nettype wire
