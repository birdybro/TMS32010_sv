`default_nettype none

module tb_hard_drivin_main_duart_timing;
  logic clk;
  logic initialize;
  logic main_8mhz_high;
  logic main_8mhz_rise;
  logic main_8mhz_fall;
  logic address_strobe_assert_event;
  logic main_address_strobe_n;
  logic duart_select_n;
  logic duart_dtack_n;
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
    .high_speed_bus_select_n_i     (1'b1),
    .duart_select_n_i              (duart_select_n),
    .rvas0_n_i                     (rvas0_n),
    .rvas_n_i                      (rvas_n),
    .gsp_wait_n_i                  (1'b1),
    .msp_wait_n_i                  (1'b1),
    .duart_dtack_n_i               (duart_dtack_n),
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
        "FAIL %s high=%0b rise=%0b fall=%0b /AS=%0b /DUART=%0b /DUDTACK=%0b rva=%0b sampled=%0b rvas0_n=%0b rvas_n=%0b /RDUART=%0b dtack_n=%0b terms=%0b%0b%0b",
        message, main_8mhz_high, main_8mhz_rise, main_8mhz_fall,
        main_address_strobe_n, duart_select_n, duart_dtack_n, rva,
        sampled_dtack_n, rvas0_n, rvas_n, read_duart_n, dtack_n,
        default_dtack_term_n, high_speed_dtack_term_n,
        duart_dtack_term_n
      );
      $fatal(1);
    end
  endtask

  initial begin
    clk = 1'b0;
    initialize = 1'b1;
    main_8mhz_high = 1'b0;
    main_8mhz_rise = 1'b0;
    main_8mhz_fall = 1'b0;
    address_strobe_assert_event = 1'b0;
    main_address_strobe_n = 1'b1;
    duart_select_n = 1'b1;
    duart_dtack_n = 1'b1;

    step(1'b0, 1'b0, 1'b0, 1'b0);
    require(dtack_n && rvas0_n && rvas_n && vpa_n &&
            read_high_speed_bus_n && read_duart_n,
            "deterministic FPGA initialization is idle");
    initialize = 1'b0;

    step(1'b1, 1'b1, 1'b0, 1'b0);
    main_address_strobe_n = 1'b0;
    duart_select_n = 1'b0;
    step(1'b1, 1'b0, 1'b0, 1'b1);
    require(dtack_n && rvas0_n && rvas_n && read_duart_n,
            "S2 raw DUART select waits for held /RVAS");

    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(dtack_n && !rvas0_n && rvas_n && read_duart_n &&
            rvas0_assert_event,
            "S3 early /RVAS0 does not select the DUART");

    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(rva && dtack_n && !rvas_n && !read_duart_n &&
            duart_dtack_term_n && rvas_assert_event,
            "S4 /RVAS asserts MC68681 CS but waits for /DUDTACK");

    step(1'b0, 1'b0, 1'b1, 1'b0);
    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(!rva && dtack_n && sampled_dtack_n && !rvas_n &&
            !read_duart_n,
            "external DUART latency retains /RVAS without false ACK");

    // The exact MC68681 publication permits acknowledge recognition to move
    // by one independent X1 clock when CS misses setup. The board gate model
    // therefore accepts completion as an external level, not a fixed delay.
    step(1'b1, 1'b0, 1'b0, 1'b0);
    require(dtack_n && !rvas_n,
            "arbitrary external DUART wait remains live");
    duart_dtack_n = 1'b0;
    step(1'b1, 1'b0, 1'b0, 1'b0);
    require(!dtack_n && !duart_dtack_term_n && !read_duart_n,
            "active /DUDTACK completes the selected DUART cycle");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!sampled_dtack_n && !dtack_n,
            "falling 8 MHz records the DUART acknowledge");

    // Raw /AS removal deasserts /DUART and therefore MC68681 CS. The board
    // /RDUART qualifier suppresses a still-low open-drain /DUDTACK while the
    // part completes its specified acknowledge release.
    main_address_strobe_n = 1'b1;
    duart_select_n = 1'b1;
    step(1'b0, 1'b0, 1'b0, 1'b0);
    require(dtack_n && read_duart_n && duart_dtack_term_n && !rvas_n,
            "raw DUART deselection releases main /DTACK before pin Hi-Z");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(sampled_dtack_n && rvas0_n && rvas_n &&
            rvas0_release_event && rvas_release_event,
            "sampled main /DTACK release ends both held strobes");

    duart_dtack_n = 1'b1;
    step(1'b0, 1'b0, 1'b0, 1'b0);
    require(dtack_n && read_duart_n && rvas0_n && rvas_n,
            "MC68681 open-drain release returns to idle");

    $display("PASS tb_hard_drivin_main_duart_timing");
    $finish;
  end
endmodule

`default_nettype wire
