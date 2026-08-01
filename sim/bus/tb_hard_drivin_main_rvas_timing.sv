`default_nettype none

module tb_hard_drivin_main_rvas_timing;
  logic clk;
  logic initialize;
  logic main_8mhz_rise;
  logic main_8mhz_fall;
  logic main_8mhz_high;
  logic address_strobe_assert;
  logic dtack_n;
  logic rva;
  logic sampled_dtack_n;
  logic rvas0_n;
  logic rvas_n;
  logic rvas0_assert_event;
  logic rvas0_release_event;
  logic rvas_assert_event;
  logic rvas_release_event;

  hard_drivin_main_rvas_timing dut (
    .clk_i                    (clk),
    .initialize_i             (initialize),
    .main_8mhz_rise_i         (main_8mhz_rise),
    .main_8mhz_fall_i         (main_8mhz_fall),
    .main_8mhz_high_i         (main_8mhz_high),
    .address_strobe_assert_i  (address_strobe_assert),
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

  always #5 clk = !clk;

  task automatic step(
    input logic high_level,
    input logic rise_event,
    input logic fall_event,
    input logic as_event,
    input logic dtack_level_n
  );
    main_8mhz_high = high_level;
    main_8mhz_rise = rise_event;
    main_8mhz_fall = fall_event;
    address_strobe_assert = as_event;
    dtack_n = dtack_level_n;
    @(posedge clk);
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $error(
        "FAIL %s init=%0b high=%0b rise=%0b fall=%0b as=%0b dtack_n=%0b rva=%0b sampled=%0b rvas0_n=%0b rvas_n=%0b events=%0b%0b%0b%0b",
        message, initialize, main_8mhz_high, main_8mhz_rise,
        main_8mhz_fall, address_strobe_assert, dtack_n, rva,
        sampled_dtack_n, rvas0_n, rvas_n, rvas0_assert_event,
        rvas0_release_event, rvas_assert_event, rvas_release_event
      );
      $fatal(1);
    end
  endtask

  task automatic start_cycle;
    // The MC68000 asserts /AS during the high S2 interval. The following S3
    // falling edge presets /RVAS0 before S4 rising asserts RVA and /RVAS.
    step(1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    require(!rva && rvas0_n && rvas_n,
            "S2 rising edge begins the high phase before /AS assertion");
    step(1'b1, 1'b0, 1'b0, 1'b1, 1'b1);
    require(!rva && rvas0_n && rvas_n,
            "high-phase /AS assertion records /S4 without early preset");
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b1);
    require(!rva && !rvas0_n && rvas_n && rvas0_assert_event,
            "S3 falling edge asserts /RVAS0 before RVA");
    step(1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    require(rva && !rvas0_n && !rvas_n && rvas_assert_event,
            "S4 rising edge asserts RVA and asynchronously presets /RVAS");
  endtask

  initial begin
    clk = 1'b0;
    initialize = 1'b1;
    main_8mhz_rise = 1'b0;
    main_8mhz_fall = 1'b0;
    main_8mhz_high = 1'b0;
    address_strobe_assert = 1'b0;
    dtack_n = 1'b1;

    step(1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    require(!rva && sampled_dtack_n && rvas0_n && rvas_n,
            "deterministic FPGA initialization chooses idle timing state");

    initialize = 1'b0;
    start_cycle();
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
    require(rva && !sampled_dtack_n && !rvas0_n && !rvas_n &&
            !rvas_release_event,
            "S5 falling edge captures asserted /DTACK without release");
    step(1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    require(!rva && !rvas0_n && !rvas_n,
            "next rising 8 MHz ends RVA while /RVAS remains held");
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b1);
    require(sampled_dtack_n && rvas0_n && rvas_n &&
            rvas0_release_event && rvas_release_event,
            "sampled /DTACK low-to-high edge releases both held strobes");

    // The gate equation also defines an immediate asynchronous preset when
    // /AS is asserted during the low phase, even though normal MC68000 S2
    // timing uses the high-phase path above.
    step(1'b0, 1'b0, 1'b0, 1'b1, 1'b1);
    require(!rva && !rvas0_n && rvas_n && rvas0_assert_event,
            "low-phase /AS assertion immediately presets /RVAS0");
    step(1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    require(rva && !rvas0_n && !rvas_n,
            "low-phase request still enters the normal RVA hold chain");
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
    step(1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b1);
    require(rvas0_n && rvas_n,
            "low-phase assertion path releases after sampled completion");

    // If /DTACK never samples low, release cannot be inferred from elapsed
    // clocks or the end of RVA.
    start_cycle();
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b1);
    step(1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    repeat (3) begin
      step(1'b0, 1'b0, 1'b1, 1'b0, 1'b1);
      step(1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    end
    require(!rva && !rvas0_n && !rvas_n,
            "held-high /DTACK leaves both preset F74 outputs active");
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
    require(!sampled_dtack_n && !rvas0_n && !rvas_n,
            "a later low /DTACK sample arms release but does not release");
    step(1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b1);
    require(sampled_dtack_n && rvas0_n && rvas_n &&
            rvas0_release_event && rvas_release_event,
            "later sampled low-to-high transition releases both strobes");

    // Active asynchronous /PRE on /RVAS0 must dominate a simultaneous D=0
    // release clock. /RVAS has no such new preset and therefore releases.
    start_cycle();
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
    step(1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    step(1'b1, 1'b0, 1'b0, 1'b1, 1'b1);
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b1);
    require(!rvas0_n && rvas_n && !rvas0_release_event &&
            rvas_release_event,
            "/RVAS0 preset dominates coincident sampled release clock");
    step(1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
    step(1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    step(1'b0, 1'b0, 1'b1, 1'b0, 1'b1);
    require(rvas0_n && rvas_n,
            "preset-priority sequence remains recoverable");

    start_cycle();
    initialize = 1'b1;
    step(1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    require(!rva && sampled_dtack_n && rvas0_n && rvas_n &&
            !rvas0_assert_event && !rvas0_release_event &&
            !rvas_assert_event && !rvas_release_event,
            "FPGA reinitialization returns the standalone timing state idle");

    $display("PASS tb_hard_drivin_main_rvas_timing");
    $finish;
  end
endmodule

`default_nettype wire
