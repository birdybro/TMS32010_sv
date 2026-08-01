`default_nettype none

// Storage-free transcription of the complete SP-327 sheet-4 main /DTACK
// logic cone. Inputs retain the drawing's active-low names and no legal-cycle
// assumptions are hidden inside the Boolean implementation.
module hard_drivin_main_dtack_decode (
  input  logic       main_address_strobe_n_i,
  input  logic [2:0] main_function_code_i,
  input  logic       rva_i,
  input  logic       high_speed_bus_select_n_i,
  input  logic       duart_select_n_i,
  input  logic       rvas0_n_i,
  input  logic       rvas_n_i,
  input  logic       gsp_wait_n_i,
  input  logic       msp_wait_n_i,
  input  logic       duart_dtack_n_i,
  output logic       vpa_n_o,
  output logic       read_high_speed_bus_n_o,
  output logic       read_duart_n_o,
  output logic       default_dtack_term_n_o,
  output logic       high_speed_dtack_term_n_o,
  output logic       duart_dtack_term_n_o,
  output logic       dtack_n_o
);
  logic graphics_sound_wait_nand;

  // LS20 150K: /AS is inverted before entering this gate. FC=111 under an
  // asserted address strobe therefore produces active /VPA.
  assign vpa_n_o =
    !(main_function_code_i == 3'b111 && !main_address_strobe_n_i);

  // The other LS20 half acknowledges the ordinary RVA path only when CPU
  // space, high-speed-bus, and DUART exceptions are all inactive.
  assign default_dtack_term_n_o =
    !(vpa_n_o && rva_i && high_speed_bus_select_n_i && duart_select_n_i);

  // ALS32 160H qualifies each selected peripheral with its held-valid strobe.
  assign read_high_speed_bus_n_o = high_speed_bus_select_n_i || rvas0_n_i;
  assign read_duart_n_o = duart_select_n_i || rvas_n_i;

  // AS00 190E and AS32 135K. The raw wait inputs are intentionally not
  // renamed as ready signals; their board-level ownership remains external.
  assign graphics_sound_wait_nand = !(gsp_wait_n_i && msp_wait_n_i);
  assign high_speed_dtack_term_n_o =
    read_high_speed_bus_n_o || graphics_sound_wait_nand;
  assign duart_dtack_term_n_o = read_duart_n_o || duart_dtack_n_i;

  // F11 140K merges three independently active-low acknowledgement terms.
  assign dtack_n_o =
    default_dtack_term_n_o &&
    high_speed_dtack_term_n_o &&
    duart_dtack_term_n_o;

  always_comb begin
    assert (vpa_n_o ==
            !(main_function_code_i == 3'b111 &&
              !main_address_strobe_n_i));
    assert (default_dtack_term_n_o ==
            !(vpa_n_o && rva_i && high_speed_bus_select_n_i &&
              duart_select_n_i));
    assert (read_high_speed_bus_n_o ==
            (high_speed_bus_select_n_i || rvas0_n_i));
    assert (read_duart_n_o == (duart_select_n_i || rvas_n_i));
    assert (high_speed_dtack_term_n_o ==
            (read_high_speed_bus_n_o ||
             !(gsp_wait_n_i && msp_wait_n_i)));
    assert (duart_dtack_term_n_o ==
            (read_duart_n_o || duart_dtack_n_i));
    assert (dtack_n_o ==
            (default_dtack_term_n_o &&
             high_speed_dtack_term_n_o &&
             duart_dtack_term_n_o));
    assert (dtack_n_o ||
            !default_dtack_term_n_o ||
            !high_speed_dtack_term_n_o ||
            !duart_dtack_term_n_o);
  end
endmodule

`default_nettype wire
