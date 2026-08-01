`default_nettype none

// Address-driven composition of the independently verified SP-327 sheet-4
// main-bus decode, held-valid strobes, and /DTACK cone. This block retains the
// event-domain boundary of hard_drivin_main_rvas_timing and does not invent
// TMS34010 HRDY, MC68681 DTACK, raw-pin CDC, or electrical-delay behavior.
module hard_drivin_main_bus_control (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic [23:1] main_address_i,
  input  logic        main_address_strobe_n_i,
  input  logic [2:0]  main_function_code_i,
  input  logic        main_8mhz_rise_i,
  input  logic        main_8mhz_fall_i,
  input  logic        main_8mhz_high_i,
  input  logic        address_strobe_assert_i,
  input  logic        gsp_wait_n_i,
  input  logic        msp_wait_n_i,
  input  logic        duart_dtack_n_i,

  output logic [7:0]  primary_select_n_o,
  output logic [3:0]  ram_select_n_o,
  output logic [3:0]  high_speed_select_n_o,
  output logic        rom_enable_n_o,
  output logic        n_bus_select_n_o,
  output logic        external_bus_select_n_o,
  output logic        low_speed_bus_select_n_o,
  output logic        high_speed_bus_select_n_o,
  output logic        ram_enable_n_o,
  output logic        duart_select_n_o,
  output logic        zero_ram_select_n_o,
  output logic        ram0_select_n_o,
  output logic        ram1_select_n_o,
  output logic        gsp_select_n_o,
  output logic        msp_select_n_o,
  output logic        read_high_speed_bus_n_o,
  output logic        read_duart_n_o,
  output logic        vpa_n_o,
  output logic        rva_o,
  output logic        sampled_dtack_n_o,
  output logic        rvas0_n_o,
  output logic        rvas_n_o,
  output logic        dtack_n_o,
  output logic        default_dtack_term_n_o,
  output logic        high_speed_dtack_term_n_o,
  output logic        duart_dtack_term_n_o,
  output logic        rvas0_assert_event_o,
  output logic        rvas0_release_event_o,
  output logic        rvas_assert_event_o,
  output logic        rvas_release_event_o
);
  logic address_read_high_speed_bus_n;

  hard_drivin_main_address_decode address_decode (
    .address_i                    (main_address_i),
    .address_strobe_n_i           (main_address_strobe_n_i),
    .rvas0_n_i                    (rvas0_n_o),
    .primary_select_n_o           (primary_select_n_o),
    .ram_select_n_o               (ram_select_n_o),
    .high_speed_select_n_o        (high_speed_select_n_o),
    .rom_enable_n_o               (rom_enable_n_o),
    .n_bus_select_n_o             (n_bus_select_n_o),
    .external_bus_select_n_o      (external_bus_select_n_o),
    .low_speed_bus_select_n_o     (low_speed_bus_select_n_o),
    .high_speed_bus_select_n_o    (high_speed_bus_select_n_o),
    .ram_enable_n_o               (ram_enable_n_o),
    .duart_select_n_o             (duart_select_n_o),
    .zero_ram_select_n_o          (zero_ram_select_n_o),
    .ram0_select_n_o              (ram0_select_n_o),
    .ram1_select_n_o              (ram1_select_n_o),
    .read_high_speed_bus_n_o      (address_read_high_speed_bus_n),
    .gsp_select_n_o               (gsp_select_n_o),
    .msp_select_n_o               (msp_select_n_o)
  );

  hard_drivin_main_rvas_timing rvas_timing (
    .clk_i                    (clk_i),
    .initialize_i             (initialize_i),
    .main_8mhz_rise_i         (main_8mhz_rise_i),
    .main_8mhz_fall_i         (main_8mhz_fall_i),
    .main_8mhz_high_i         (main_8mhz_high_i),
    .address_strobe_assert_i  (address_strobe_assert_i),
    .dtack_n_i                (dtack_n_o),
    .rva_o                    (rva_o),
    .sampled_dtack_n_o        (sampled_dtack_n_o),
    .rvas0_n_o                (rvas0_n_o),
    .rvas_n_o                 (rvas_n_o),
    .rvas0_assert_event_o     (rvas0_assert_event_o),
    .rvas0_release_event_o    (rvas0_release_event_o),
    .rvas_assert_event_o      (rvas_assert_event_o),
    .rvas_release_event_o     (rvas_release_event_o)
  );

  hard_drivin_main_dtack_decode dtack_decode (
    .main_address_strobe_n_i       (main_address_strobe_n_i),
    .main_function_code_i          (main_function_code_i),
    .rva_i                         (rva_o),
    .high_speed_bus_select_n_i     (high_speed_bus_select_n_o),
    .duart_select_n_i              (duart_select_n_o),
    .rvas0_n_i                     (rvas0_n_o),
    .rvas_n_i                      (rvas_n_o),
    .gsp_wait_n_i                  (gsp_wait_n_i),
    .msp_wait_n_i                  (msp_wait_n_i),
    .duart_dtack_n_i               (duart_dtack_n_i),
    .vpa_n_o                       (vpa_n_o),
    .read_high_speed_bus_n_o       (read_high_speed_bus_n_o),
    .read_duart_n_o                (read_duart_n_o),
    .default_dtack_term_n_o        (default_dtack_term_n_o),
    .high_speed_dtack_term_n_o     (high_speed_dtack_term_n_o),
    .duart_dtack_term_n_o          (duart_dtack_term_n_o),
    .dtack_n_o                     (dtack_n_o)
  );

  always_comb begin
    // Both source blocks transcribe the same AS32 /RHSBUS gate. Keeping this
    // equality explicit catches accidental divergence at the composition.
    assert (address_read_high_speed_bus_n == read_high_speed_bus_n_o);
    assert (rom_enable_n_o == primary_select_n_o[0]);
    assert (n_bus_select_n_o == primary_select_n_o[3]);
    assert (external_bus_select_n_o == primary_select_n_o[4]);
    assert (low_speed_bus_select_n_o == primary_select_n_o[5]);
    assert (high_speed_bus_select_n_o == primary_select_n_o[6]);
    assert (ram_enable_n_o == primary_select_n_o[7]);
    assert (duart_select_n_o == ram_select_n_o[0]);
    assert (zero_ram_select_n_o == ram_select_n_o[1]);
    assert (ram0_select_n_o == ram_select_n_o[2]);
    assert (ram1_select_n_o == ram_select_n_o[3]);
  end
endmodule

`default_nettype wire
