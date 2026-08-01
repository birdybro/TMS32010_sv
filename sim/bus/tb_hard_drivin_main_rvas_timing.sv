`default_nettype none

module tb_hard_drivin_main_rvas_timing;
  logic clk;
  logic initialize;
  logic main_8mhz_rise;
  logic main_8mhz_fall;
  logic address_strobe_assert;
  logic dtack_n;
  logic rva;
  logic sampled_dtack_n;
  logic rvas_n;
  logic rvas_assert_event;
  logic rvas_release_event;

  hard_drivin_main_rvas_timing dut (
    .clk_i                    (clk),
    .initialize_i             (initialize),
    .main_8mhz_rise_i         (main_8mhz_rise),
    .main_8mhz_fall_i         (main_8mhz_fall),
    .address_strobe_assert_i  (address_strobe_assert),
    .dtack_n_i                (dtack_n),
    .rva_o                    (rva),
    .sampled_dtack_n_o        (sampled_dtack_n),
    .rvas_n_o                 (rvas_n),
    .rvas_assert_event_o      (rvas_assert_event),
    .rvas_release_event_o     (rvas_release_event)
  );

  always #5 clk = !clk;

  task automatic step(
    input logic rise_event,
    input logic fall_event,
    input logic as_event,
    input logic dtack_level_n
  );
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
        "FAIL %s init=%0b rise=%0b fall=%0b as=%0b dtack_n=%0b rva=%0b sampled=%0b rvas_n=%0b assert=%0b release=%0b",
        message, initialize, main_8mhz_rise, main_8mhz_fall,
        address_strobe_assert, dtack_n, rva, sampled_dtack_n, rvas_n,
        rvas_assert_event, rvas_release_event
      );
      $fatal(1);
    end
  endtask

  task automatic start_cycle;
    step(1'b0, 1'b0, 1'b1, 1'b1);
    require(!rva && rvas_n,
            "/AS assertion is captured before the next 8 MHz rise");
    step(1'b1, 1'b0, 1'b0, 1'b1);
    require(rva && !rvas_n && rvas_assert_event,
            "rising 8 MHz asserts RVA and asynchronously presets /RVAS");
  endtask

  initial begin
    clk = 1'b0;
    initialize = 1'b1;
    main_8mhz_rise = 1'b0;
    main_8mhz_fall = 1'b0;
    address_strobe_assert = 1'b0;
    dtack_n = 1'b1;

    step(1'b0, 1'b0, 1'b0, 1'b1);
    require(!rva && sampled_dtack_n && rvas_n,
            "deterministic FPGA initialization chooses idle timing state");

    initialize = 1'b0;
    start_cycle();
    step(1'b0, 1'b1, 1'b0, 1'b0);
    require(rva && !sampled_dtack_n && !rvas_n &&
            !rvas_release_event,
            "falling 8 MHz captures asserted /DTACK without releasing /RVAS");
    step(1'b1, 1'b0, 1'b0, 1'b1);
    require(!rva && !rvas_n,
            "next rising 8 MHz ends RVA while /RVAS remains held");
    step(1'b0, 1'b1, 1'b0, 1'b1);
    require(sampled_dtack_n && rvas_n && rvas_release_event,
            "sampled /DTACK low-to-high edge releases /RVAS");

    // If /DTACK never samples low, release cannot be inferred from elapsed
    // clocks or the end of RVA.
    start_cycle();
    step(1'b0, 1'b1, 1'b0, 1'b1);
    step(1'b1, 1'b0, 1'b0, 1'b1);
    repeat (3) begin
      step(1'b0, 1'b1, 1'b0, 1'b1);
      step(1'b1, 1'b0, 1'b0, 1'b1);
    end
    require(!rva && !rvas_n,
            "held-high /DTACK leaves the preset /RVAS F74 active");
    step(1'b0, 1'b1, 1'b0, 1'b0);
    require(!sampled_dtack_n && !rvas_n,
            "a later low /DTACK sample arms release but does not release");
    step(1'b1, 1'b0, 1'b0, 1'b1);
    step(1'b0, 1'b1, 1'b0, 1'b1);
    require(sampled_dtack_n && rvas_n && rvas_release_event,
            "later sampled low-to-high /DTACK transition releases /RVAS");

    start_cycle();
    initialize = 1'b1;
    step(1'b0, 1'b0, 1'b0, 1'b0);
    require(!rva && sampled_dtack_n && rvas_n &&
            !rvas_assert_event && !rvas_release_event,
            "FPGA reinitialization returns the standalone timing state idle");

    $display("PASS tb_hard_drivin_main_rvas_timing");
    $finish;
  end
endmodule

`default_nettype wire
