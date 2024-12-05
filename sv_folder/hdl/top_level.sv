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
    output logic [6:0] ss1_c,  //cathode controls for the segments of lower four digits
    output logic spkl,
    output logic spkr,
    // DDR3 ports
    inout wire [15:0]  ddr3_dq,
    inout wire [1:0]   ddr3_dqs_n,
    inout wire [1:0]   ddr3_dqs_p,
    output wire [12:0] ddr3_addr,
    output wire [2:0]  ddr3_ba,
    output wire        ddr3_ras_n,
    output wire        ddr3_cas_n,
    output wire        ddr3_we_n,
    output wire        ddr3_reset_n,
    output wire        ddr3_ck_p,
    output wire        ddr3_ck_n,
    output wire        ddr3_cke,
    output wire [1:0]  ddr3_dm,
    output wire        ddr3_odt
);

  //shut up those rgb LEDs for now (active high):
  assign rgb1 = 0;  //set to 0.
  assign rgb0 = 0;  //set to 0.

  //have btnd control system reset
  logic sys_rst;
  assign sys_rst = btn[0];

  logic          clk_migref;
  logic          sys_rst_migref;
  
  logic          clk_ui;
  logic          sys_rst_ui;

  logic          clk_100_passthrough;

  logic          clk_xc;
  logic          clk_camera;

  assign sys_rst_migref = btn[0];

  cw_fast_clk_wiz wizard_migcam(
    .clk_in1(clk_100mhz),
    .clk_camera(clk_camera),
    .clk_mig(clk_migref),
    .clk_xc(clk_xc),
    .clk_100(clk_100_passthrough),
    .reset(0));

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

  always_ff @(posedge clk_100_passthrough) begin
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

  always_ff @(posedge clk_100_passthrough) begin
    if (sys_rst) clk_elapsed <= 0;
    else if (clk_elapsed < CYCLES_TILL_MIC_CLK_VALID) clk_elapsed <= clk_elapsed + 1;
  end

  assign mic_trigger = mic_trigger_count == (DATA_CLK_CYCLES_PER_MIC_CLK - 1);

  assign tdm_sck_out = data_clk;
  assign tdm_ws_out = mic_trigger && (clk_elapsed == CYCLES_TILL_MIC_CLK_VALID);

  // -- TDM INPUT --
  // TDM Microphone Input
  logic [23:0] audio_out[MICS];
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

  always_ff @(posedge clk_100_passthrough) begin

    if (sys_rst) begin
      display_val <= 0;
    end
    // For Testing -- Display Audio Sample when sw[13] High
    else if (sw[12] && audio_valid_out) begin
      display_val <= {8'b0, audio_out[0]};
    end else if (sw[13] && dss_valid_out && ~btn[1]) begin
      display_val <= {8'b0, dss_audio_out};
    end
    else if (~sw[13]) display_val <= {20'b0, ascii_rep};
  end

  logic [ 6:0] ss_c;  //used to grab output cathode signal for 7s leds
  seven_segment_controller mssc(.clk_in(clk_100_passthrough),
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
  logic [26:0] dss_count_out;

  delay_bram delay_sum_shift (
    .clk_in(clk_100_passthrough),
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
    .valid_out(dss_valid_out),
    .audio_count_out(dss_count_out)
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

  always_ff @(posedge clk_100_passthrough) begin
    // When a new audio sample received it is waiting to be sent
    if (sys_rst) begin
      audio_sample_waiting <= 0;
      uart_single_data_in <= 0;
      uart_dual_data_in <= 0;
      uart_data_valid <= 0;
      is_even_sample <= 0;
    end
    else if ((dss_valid_out && ~use_dual_uart) || (audio_valid_out && use_dual_uart)) begin
      if (!uart_busy) begin
        // Sent via uart if not busy
        uart_data_valid <= 1;
        audio_sample_waiting <= 0;
      end else begin
        // Flag that sample waiting if busy
        audio_sample_waiting <= 1;
      end

      // Update uart data inputs with the new samples
      uart_single_data_in <= audio_buff_out; // this will either be from the dram or directly from mics
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
  .clk_in(clk_100_passthrough),
  .rst_in(sys_rst),
  .data_in(uart_single_data_in),
  .trigger_in(uart_data_valid && ~use_dual_uart && enable_uart),
  .busy_out(uart_single_busy),
  .tx_wire_out(uart_single_txd)
  );

  // uart_byte_transmit #(.NUM_BYTES(4), .BAUD_RATE(921_600)) uart_transmit_dual_m (
  // .clk_in(clk_100_passthrough),
  // .rst_in(sys_rst),
  // .data_in(uart_dual_data_in),
  // .trigger_in(uart_data_valid && use_dual_uart && is_even_sample && enable_uart),
  // .busy_out(uart_dual_busy),
  // .tx_wire_out(uart_dual_txd)
  // );



  // ************************** //
  // NEW DRAM STUFF STARTS HERE //
  // save audio when sw[10] is high

  logic [15:0] audio_buff_dram; // data out of DRAM audio buffer
  logic [13:0] audio_buff_out; // select between the two!
  assign audio_buff_out = sw[10] ? audio_buff_dram[13:0] : dss_audio_out[23:10];

  logic [127:0] audio_chunk;
  logic [127:0] audio_axis_tdata;
  logic         audio_axis_tlast;
  logic         audio_axis_tready;
  logic         audio_axis_tvalid;

  // TODO: make delay_bram have a counter that counts how many audio samples it receives.
  // make the audio tlast be when the count is equal to the last audio sample.

  // takes our 16-bit values and deserialize/stack them into 128-bit messages to write to DRAM
  // the data pipeline is designed such that we can fairly safely assume its always ready.
  stacker stacker_inst(
    .clk_in(clk_100_passthrough),
    .rst_in(sys_rst),
    .audio_tvalid(dss_valid_out),
    .audio_tready(),
    .audio_tdata(dss_audio_out),
    .audio_tlast(dss_count_out == 23436),
    .audio_chunk_tvalid(audio_axis_tvalid),
    .audio_chunk_tready(audio_axis_tready),
    .audio_chunk_tdata(audio_axis_tdata),
    .audio_chunk_tlast(audio_axis_tlast));
  
  logic [127:0] audio_ui_axis_tdata;
  logic         audio_ui_axis_tlast;
  logic         audio_ui_axis_tready;
  logic         audio_ui_axis_tvalid;
  logic         audio_ui_axis_prog_empty;

  // FIFO data queue of 128-bit messages, crosses clock domains to the 81.25MHz
  // UI clock of the memory interface
  ddr_fifo_wrap audio_data_fifo(
    .sender_rst(sys_rst),
    .sender_clk(clk_100_passthrough),
    .sender_axis_tvalid(audio_axis_tvalid),
    .sender_axis_tready(audio_axis_tready),
    .sender_axis_tdata(audio_axis_tdata),
    .sender_axis_tlast(audio_axis_tlast),
    .receiver_clk(clk_ui),
    .receiver_axis_tvalid(audio_ui_axis_tvalid),
    .receiver_axis_tready(audio_ui_axis_tready),
    .receiver_axis_tdata(audio_ui_axis_tdata),
    .receiver_axis_tlast(audio_ui_axis_tlast),
    .receiver_axis_prog_empty(audio_ui_axis_prog_empty));

  logic [127:0] display_ui_axis_tdata;
  logic         display_ui_axis_tlast;
  logic         display_ui_axis_tready;
  logic         display_ui_axis_tvalid;
  logic         display_ui_axis_prog_full;

  // these are the signals that the MIG IP needs for us to define!
  // MIG UI --> generic outputs
  logic [26:0]  app_addr;
  logic [2:0]   app_cmd;
  logic         app_en;
  // MIG UI --> write outputs
  logic [127:0] app_wdf_data;
  logic         app_wdf_end;
  logic         app_wdf_wren;
  logic [15:0]  app_wdf_mask;
  // MIG UI --> read inputs
  logic [127:0] app_rd_data;
  logic         app_rd_data_end;
  logic         app_rd_data_valid;
  // MIG UI --> generic inputs
  logic         app_rdy;
  logic         app_wdf_rdy;
  // MIG UI --> misc
  logic         app_sr_req; 
  logic         app_ref_req;
  logic         app_zq_req; 
  logic         app_sr_active;
  logic         app_ref_ack;
  logic         app_zq_ack;
  logic         init_calib_complete;
  

  // this traffic generator handles reads and writes issued to the MIG IP,
  // which in turn handles the bus to the DDR chip.
  traffic_generator readwrite_looper(
    // Outputs
    .app_addr         (app_addr[26:0]),
    .app_cmd          (app_cmd[2:0]),
    .app_en           (app_en),
    .app_wdf_data     (app_wdf_data[127:0]),
    .app_wdf_end      (app_wdf_end),
    .app_wdf_wren     (app_wdf_wren),
    .app_wdf_mask     (app_wdf_mask[15:0]),
    .app_sr_req       (app_sr_req),
    .app_ref_req      (app_ref_req),
    .app_zq_req       (app_zq_req),
    .write_axis_ready (audio_ui_axis_tready),
    .read_axis_data   (display_ui_axis_tdata),
    .read_axis_tlast  (display_ui_axis_tlast),
    .read_axis_valid  (display_ui_axis_tvalid),
    // Inputs
    .clk_in           (clk_ui),
    .rst_in           (sys_rst_ui),
    .app_rd_data      (app_rd_data[127:0]),
    .app_rd_data_end  (app_rd_data_end),
    .app_rd_data_valid(app_rd_data_valid),
    .app_rdy          (app_rdy),
    .app_wdf_rdy      (app_wdf_rdy),
    .app_sr_active    (app_sr_active),
    .app_ref_ack      (app_ref_ack),
    .app_zq_ack       (app_zq_ack),
    .init_calib_complete(init_calib_complete),
    .write_axis_data  (audio_ui_axis_tdata),
    .write_axis_tlast (audio_ui_axis_tlast),
    .write_axis_valid (audio_ui_axis_tvalid),
    .write_axis_smallpile(audio_ui_axis_prog_empty),
    .read_axis_af     (display_ui_axis_prog_full),
    .read_axis_ready  (display_ui_axis_tready)
  );

  // the MIG IP!
  ddr3_mig ddr3_mig_inst 
    (
    .ddr3_dq(ddr3_dq),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dqs_p(ddr3_dqs_p),
    .ddr3_addr(ddr3_addr),
    .ddr3_ba(ddr3_ba),
    .ddr3_ras_n(ddr3_ras_n),
    .ddr3_cas_n(ddr3_cas_n),
    .ddr3_we_n(ddr3_we_n),
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_ck_p(ddr3_ck_p),
    .ddr3_ck_n(ddr3_ck_n),
    .ddr3_cke(ddr3_cke),
    .ddr3_dm(ddr3_dm),
    .ddr3_odt(ddr3_odt),
    .sys_clk_i(clk_migref),
    .app_addr(app_addr),
    .app_cmd(app_cmd),
    .app_en(app_en),
    .app_wdf_data(app_wdf_data),
    .app_wdf_end(app_wdf_end),
    .app_wdf_wren(app_wdf_wren),
    .app_rd_data(app_rd_data),
    .app_rd_data_end(app_rd_data_end),
    .app_rd_data_valid(app_rd_data_valid),
    .app_rdy(app_rdy),
    .app_wdf_rdy(app_wdf_rdy), 
    .app_sr_req(app_sr_req),
    .app_ref_req(app_ref_req),
    .app_zq_req(app_zq_req),
    .app_sr_active(app_sr_active),
    .app_ref_ack(app_ref_ack),
    .app_zq_ack(app_zq_ack),
    .ui_clk(clk_ui), 
    .ui_clk_sync_rst(sys_rst_ui),
    .app_wdf_mask(app_wdf_mask),
    .init_calib_complete(init_calib_complete),
    .sys_rst(!sys_rst_migref) // active low
  );
  
  logic [127:0] display_axis_tdata;
  logic         display_axis_tlast;
  logic         display_axis_tready;
  logic         display_axis_tvalid;
  logic         display_axis_prog_empty;
  
  ddr_fifo_wrap pdfifo(
    .sender_rst(sys_rst_ui),
    .sender_clk(clk_ui),
    .sender_axis_tvalid(display_ui_axis_tvalid),
    .sender_axis_tready(display_ui_axis_tready),
    .sender_axis_tdata(display_ui_axis_tdata),
    .sender_axis_tlast(display_ui_axis_tlast),
    .sender_axis_prog_full(display_ui_axis_prog_full),
    .receiver_clk(clk_100_passthrough),
    .receiver_axis_tvalid(display_axis_tvalid),
    .receiver_axis_tready(display_axis_tready),
    .receiver_axis_tdata(display_axis_tdata),
    .receiver_axis_tlast(display_axis_tlast),
    .receiver_axis_prog_empty(display_axis_prog_empty));

  logic audio_buff_tvalid;
  logic audio_buff_tready;
  logic [15:0] audio_buff_tdata;
  logic        audio_buff_tlast;

  unstacker unstacker_inst(
    .clk_in(clk_100_passthrough),
    .rst_in(sys_rst),
    .audio_chunk_tvalid(display_axis_tvalid),
    .audio_chunk_tready(display_axis_tready),
    .audio_chunk_tdata(display_axis_tdata),
    .audio_chunk_tlast(display_axis_tlast),
    .audio_tvalid(audio_buff_tvalid),
    .audio_tready(audio_buff_tready),
    .audio_tdata(audio_buff_tdata),
    .audio_tlast(audio_buff_tlast));

  assign audio_buff_tready = (!audio_buff_tlast); // slight change from before: drop the very last sample
  
  assign audio_buff_dram = audio_buff_tvalid ? audio_buff_tdata : 16'h0;

  // NEW DRAM STUFF ENDS HERE


endmodule  // top_level

`default_nettype wire
