`default_nettype none

module tb_hard_drivin_main_sound_reset_timing;
  logic        clk;
  logic        initialize;
  logic        main_8mhz_rise;
  logic        main_8mhz_fall;
  logic        main_8mhz_high;
  logic        address_strobe_assert_event;
  logic        main_address_strobe_n;
  logic [23:14] main_address;
  logic        main_read_not_write;
  logic        rva;
  logic        sampled_dtack_n;
  logic        rvas0_n;
  logic        rvas_n;
  logic        rvas0_assert_event;
  logic        rvas0_release_event;
  logic        rvas_assert_event;
  logic        rvas_release_event;
  logic        dtack_n;
  logic        vpa_n;
  logic        read_high_speed_bus_n;
  logic        read_duart_n;
  logic        default_dtack_term_n;
  logic        high_speed_dtack_term_n;
  logic        duart_dtack_term_n;
  logic        external_bus_select_n;
  logic        sound_reset_address_match;
  logic        sound_reset_n;

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
    .duart_select_n_i              (1'b1),
    .rvas0_n_i                     (rvas0_n),
    .rvas_n_i                      (rvas_n),
    .gsp_wait_n_i                  (1'b0),
    .msp_wait_n_i                  (1'b0),
    .duart_dtack_n_i               (1'b1),
    .vpa_n_o                       (vpa_n),
    .read_high_speed_bus_n_o       (read_high_speed_bus_n),
    .read_duart_n_o                (read_duart_n),
    .default_dtack_term_n_o        (default_dtack_term_n),
    .high_speed_dtack_term_n_o     (high_speed_dtack_term_n),
    .duart_dtack_term_n_o          (duart_dtack_term_n),
    .dtack_n_o                     (dtack_n)
  );

  hard_drivin_main_sound_reset_decode reset_decode (
    .main_address_strobe_n_i       (main_address_strobe_n),
    .main_valid_address_strobe_n_i (rvas_n),
    .main_read_not_write_i         (main_read_not_write),
    .main_address_i                (main_address),
    .external_bus_select_n_o       (external_bus_select_n),
    .sound_reset_address_match_o   (sound_reset_address_match),
    .sound_reset_n_o               (sound_reset_n)
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
        "FAIL %s high=%0b rise=%0b fall=%0b as_event=%0b rva=%0b dtack_n=%0b sampled=%0b rvas0_n=%0b rvas_n=%0b sres_n=%0b",
        message, main_8mhz_high, main_8mhz_rise, main_8mhz_fall,
        address_strobe_assert_event, rva, dtack_n, sampled_dtack_n,
        rvas0_n, rvas_n, sound_reset_n
      );
      $fatal(1);
    end
  endtask

  initial begin
    clk = 1'b0;
    initialize = 1'b1;
    main_8mhz_rise = 1'b0;
    main_8mhz_fall = 1'b0;
    main_8mhz_high = 1'b0;
    address_strobe_assert_event = 1'b0;
    main_address_strobe_n = 1'b1;
    main_address = 10'(24'h84c000 >> 14);
    main_read_not_write = 1'b0;

    step(1'b0, 1'b0, 1'b0, 1'b0);
    require(!rva && dtack_n && rvas0_n && rvas_n && sound_reset_n &&
            external_bus_select_n && sound_reset_address_match,
            "initialized composition is idle");

    initialize = 1'b0;
    step(1'b1, 1'b1, 1'b0, 1'b0);
    main_address_strobe_n = 1'b0;
    step(1'b1, 1'b0, 1'b0, 1'b1);
    require(!rva && dtack_n && rvas0_n && rvas_n && sound_reset_n,
            "S2 /AS capture alone does not acknowledge or reset sound");

    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!rva && dtack_n && !rvas0_n && rvas_n && sound_reset_n &&
            rvas0_assert_event,
            "S3 early /RVAS0 does not affect the ordinary reset-write path");

    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(rva && !dtack_n && !rvas_n && !sound_reset_n &&
            rvas_assert_event && vpa_n && read_high_speed_bus_n &&
            read_duart_n && !default_dtack_term_n &&
            high_speed_dtack_term_n && duart_dtack_term_n,
            "rising 8 MHz asserts RVA, /DTACK, /RVAS, and decoded /SRES");

    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(rva && !dtack_n && !sampled_dtack_n && !rvas_n &&
            !sound_reset_n,
            "falling 8 MHz records asserted /DTACK while /SRES remains active");

    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(!rva && dtack_n && !sampled_dtack_n && !rvas_n &&
            !sound_reset_n,
            "next rising 8 MHz removes RVA/DTACK but holds /RVAS and /SRES");

    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!rva && dtack_n && sampled_dtack_n && rvas_n && sound_reset_n &&
            rvas0_n && rvas0_release_event && rvas_release_event,
            "sampled /DTACK release ends /RVAS and /SRES");

    $display("PASS tb_hard_drivin_main_sound_reset_timing");
    $finish;
  end
endmodule

`default_nettype wire
