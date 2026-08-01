`default_nettype none

module tb_hard_drivin_main_hsbus_timing;
  logic clk;
  logic initialize;
  logic main_8mhz_high;
  logic main_8mhz_rise;
  logic main_8mhz_fall;
  logic address_strobe_assert_event;
  logic main_address_strobe_n;
  logic high_speed_bus_select_n;
  logic gsp_wait_n;
  logic msp_wait_n;
  logic rva;
  logic sampled_dtack_n;
  logic rvas0_n;
  logic rvas_n;
  logic rvas0_assert_event;
  logic rvas0_release_event;
  logic rvas_assert_event;
  logic rvas_release_event;
  logic vpa_n;
  logic read_high_speed_bus_n;
  logic read_duart_n;
  logic default_dtack_term_n;
  logic high_speed_dtack_term_n;
  logic duart_dtack_term_n;
  logic dtack_n;

  hard_drivin_main_rvas_timing timing (
    .clk_i                    (clk),
    .initialize_i             (initialize),
    .main_8mhz_rise_i         (main_8mhz_rise),
    .main_8mhz_fall_i         (main_8mhz_fall),
    .main_8mhz_high_i         (main_8mhz_high),
    .address_strobe_assert_i  (address_strobe_assert_event),
    .dtack_n_i                (dtack_n),
    .rva_o                    (rva),
    .sampled_dtack_n_o        (sampled_dtack_n),
    .rvas0_n_o                (rvas0_n),
    .rvas_n_o                 (rvas_n),
    .rvas0_assert_event_o     (rvas0_assert_event),
    .rvas0_release_event_o    (rvas0_release_event),
    .rvas_assert_event_o      (rvas_assert_event),
    .rvas_release_event_o     (rvas_release_event)
  );

  hard_drivin_main_dtack_decode dtack_decode (
    .main_address_strobe_n_i       (main_address_strobe_n),
    .main_function_code_i          (3'b001),
    .rva_i                         (rva),
    .high_speed_bus_select_n_i     (high_speed_bus_select_n),
    .duart_select_n_i              (1'b1),
    .rvas0_n_i                     (rvas0_n),
    .rvas_n_i                      (rvas_n),
    .gsp_wait_n_i                  (gsp_wait_n),
    .msp_wait_n_i                  (msp_wait_n),
    .duart_dtack_n_i               (1'b1),
    .vpa_n_o                       (vpa_n),
    .read_high_speed_bus_n_o       (read_high_speed_bus_n),
    .read_duart_n_o                (read_duart_n),
    .default_dtack_term_n_o        (default_dtack_term_n),
    .high_speed_dtack_term_n_o     (high_speed_dtack_term_n),
    .duart_dtack_term_n_o          (duart_dtack_term_n),
    .dtack_n_o                     (dtack_n)
  );

  always #5 clk = !clk;

  task automatic step(
    input logic high_level,
    input logic rise_event,
    input logic fall_event,
    input logic as_event
  );
    main_8mhz_high = high_level;
    main_8mhz_rise = rise_event;
    main_8mhz_fall = fall_event;
    address_strobe_assert_event = as_event;
    @(posedge clk);
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $error(
        "FAIL %s high=%0b rise=%0b fall=%0b as_event=%0b /AS=%0b /HSBUS=%0b waits=%0b%0b rva=%0b sampled=%0b rvas0_n=%0b rvas_n=%0b dtack_n=%0b terms=%0b%0b%0b",
        message, main_8mhz_high, main_8mhz_rise, main_8mhz_fall,
        address_strobe_assert_event, main_address_strobe_n,
        high_speed_bus_select_n, gsp_wait_n, msp_wait_n, rva,
        sampled_dtack_n, rvas0_n, rvas_n, dtack_n,
        default_dtack_term_n, high_speed_dtack_term_n,
        duart_dtack_term_n
      );
      $fatal(1);
    end
  endtask

  task automatic begin_hsbus_cycle;
    step(1'b1, 1'b1, 1'b0, 1'b0);
    main_address_strobe_n = 1'b0;
    high_speed_bus_select_n = 1'b0;
    step(1'b1, 1'b0, 1'b0, 1'b1);
    require(rvas0_n && dtack_n && read_high_speed_bus_n && vpa_n &&
            read_duart_n && duart_dtack_term_n,
            "S2 selected HSBUS waits for the early valid strobe");
    step(1'b0, 1'b0, 1'b1, 1'b0);
  endtask

  task automatic end_hsbus_cycle;
    // The MC68000 begins negating /AS after the S7 falling edge. The raw
    // address decode then releases /HSBUS and /DTACK before the next sample.
    main_address_strobe_n = 1'b1;
    high_speed_bus_select_n = 1'b1;
    step(1'b0, 1'b0, 1'b0, 1'b0);
    require(dtack_n && read_high_speed_bus_n,
            "raw /AS deassertion removes the HSBUS acknowledgement term");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(sampled_dtack_n && rvas0_n && rvas_n &&
            rvas0_release_event && rvas_release_event,
            "next sampled high /DTACK releases both held strobes");
  endtask

  initial begin
    clk = 1'b0;
    initialize = 1'b1;
    main_8mhz_high = 1'b0;
    main_8mhz_rise = 1'b0;
    main_8mhz_fall = 1'b0;
    address_strobe_assert_event = 1'b0;
    main_address_strobe_n = 1'b1;
    high_speed_bus_select_n = 1'b1;
    gsp_wait_n = 1'b1;
    msp_wait_n = 1'b1;

    step(1'b0, 1'b0, 1'b0, 1'b0);
    require(dtack_n && rvas0_n && rvas_n,
            "deterministic FPGA initialization is idle");
    initialize = 1'b0;

    begin_hsbus_cycle();
    require(!rvas0_n && !dtack_n && rvas0_assert_event &&
            !read_high_speed_bus_n && !high_speed_dtack_term_n,
            "S3 /RVAS0 assertion enables zero-wait HSBUS /DTACK");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(rva && !rvas_n && !dtack_n && rvas_assert_event,
            "S4 RVA path does not disturb the selected HSBUS term");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!sampled_dtack_n && !dtack_n,
            "S5 falling edge records the HSBUS acknowledgement");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(!rva && !dtack_n && !rvas0_n && !rvas_n,
            "S6 ends RVA while the selected HSBUS cycle remains active");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!sampled_dtack_n && !dtack_n,
            "S7 samples the still-selected HSBUS acknowledgement low");
    end_hsbus_cycle();

    // Either active-low wait input suppresses acknowledgement after /RVAS0.
    gsp_wait_n = 1'b0;
    begin_hsbus_cycle();
    require(!rvas0_n && dtack_n && high_speed_dtack_term_n,
            "asserted /GSPWAIT holds /DTACK inactive after S3");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(dtack_n && sampled_dtack_n && !rvas0_n && !rvas_n,
            "wait extension retains both strobes without a false low sample");
    gsp_wait_n = 1'b1;
    step(1'b1, 1'b0, 1'b0, 1'b0);
    require(!dtack_n && !high_speed_dtack_term_n,
            "wait release permits the live HSBUS acknowledgement");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!sampled_dtack_n,
            "first falling edge after wait release records /DTACK low");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    end_hsbus_cycle();

    // A044425 sheet 15 connects /MSPWAIT to the MSP TMS34010 HRDY output.
    // Exercise that independently from the sheet-10 GSP source so the
    // composed timing evidence covers both inputs of AS00 190E.
    msp_wait_n = 1'b0;
    begin_hsbus_cycle();
    require(!rvas0_n && dtack_n && high_speed_dtack_term_n,
            "asserted /MSPWAIT holds /DTACK inactive after S3");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(dtack_n && sampled_dtack_n && !rvas0_n && !rvas_n,
            "MSP wait extension retains both strobes without a false sample");
    msp_wait_n = 1'b1;
    step(1'b1, 1'b0, 1'b0, 1'b0);
    require(!dtack_n && !high_speed_dtack_term_n,
            "MSP HRDY release permits the live HSBUS acknowledgement");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!sampled_dtack_n,
            "first falling edge after MSP ready records /DTACK low");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    end_hsbus_cycle();

    $display("PASS tb_hard_drivin_main_hsbus_timing");
    $finish;
  end
endmodule

`default_nettype wire
