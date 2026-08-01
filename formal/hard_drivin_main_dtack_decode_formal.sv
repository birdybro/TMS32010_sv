`default_nettype none

module hard_drivin_main_dtack_decode_formal (
  input logic       main_address_strobe_n_i,
  input logic [2:0] main_function_code_i,
  input logic       rva_i,
  input logic       high_speed_bus_select_n_i,
  input logic       duart_select_n_i,
  input logic       rvas0_n_i,
  input logic       rvas_n_i,
  input logic       gsp_wait_n_i,
  input logic       msp_wait_n_i,
  input logic       duart_dtack_n_i
);
  logic vpa_n;
  logic read_high_speed_bus_n;
  logic read_duart_n;
  logic default_dtack_term_n;
  logic high_speed_dtack_term_n;
  logic duart_dtack_term_n;
  logic dtack_n;

  hard_drivin_main_dtack_decode dut (
    .main_address_strobe_n_i       (main_address_strobe_n_i),
    .main_function_code_i          (main_function_code_i),
    .rva_i                         (rva_i),
    .high_speed_bus_select_n_i     (high_speed_bus_select_n_i),
    .duart_select_n_i              (duart_select_n_i),
    .rvas0_n_i                     (rvas0_n_i),
    .rvas_n_i                      (rvas_n_i),
    .gsp_wait_n_i                  (gsp_wait_n_i),
    .msp_wait_n_i                  (msp_wait_n_i),
    .duart_dtack_n_i               (duart_dtack_n_i),
    .vpa_n_o                       (vpa_n),
    .read_high_speed_bus_n_o       (read_high_speed_bus_n),
    .read_duart_n_o                (read_duart_n),
    .default_dtack_term_n_o        (default_dtack_term_n),
    .high_speed_dtack_term_n_o     (high_speed_dtack_term_n),
    .duart_dtack_term_n_o          (duart_dtack_term_n),
    .dtack_n_o                     (dtack_n)
  );

  always_comb begin
    assert (vpa_n ==
            !(main_function_code_i == 3'b111 &&
              !main_address_strobe_n_i));
    assert (read_high_speed_bus_n ==
            (high_speed_bus_select_n_i || rvas0_n_i));
    assert (read_duart_n == (duart_select_n_i || rvas_n_i));
    assert (default_dtack_term_n ==
            !(vpa_n && rva_i && high_speed_bus_select_n_i &&
              duart_select_n_i));
    assert (high_speed_dtack_term_n ==
            (read_high_speed_bus_n ||
             !(gsp_wait_n_i && msp_wait_n_i)));
    assert (duart_dtack_term_n ==
            (read_duart_n || duart_dtack_n_i));
    assert (dtack_n ==
            (default_dtack_term_n && high_speed_dtack_term_n &&
             duart_dtack_term_n));

    cover (!main_address_strobe_n_i &&
           (main_function_code_i != 3'b111) && rva_i &&
           high_speed_bus_select_n_i && duart_select_n_i && !dtack_n);
    cover (!main_address_strobe_n_i &&
           (main_function_code_i == 3'b111) && !vpa_n && dtack_n);
    cover (!high_speed_bus_select_n_i && !rvas0_n_i &&
           gsp_wait_n_i && msp_wait_n_i && !dtack_n);
    cover (!high_speed_bus_select_n_i && !rvas0_n_i &&
           (!gsp_wait_n_i || !msp_wait_n_i) && dtack_n);
    cover (!duart_select_n_i && !rvas_n_i && !duart_dtack_n_i &&
           !dtack_n);
    cover (!duart_select_n_i && !rvas_n_i && duart_dtack_n_i && dtack_n);
  end
endmodule

`default_nettype wire
