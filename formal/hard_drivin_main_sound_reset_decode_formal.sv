`default_nettype none

// One-step proof of the complete main-board high-address and control decode.
module hard_drivin_main_sound_reset_decode_formal (
  input logic        main_address_strobe_n_i,
  input logic        main_valid_address_strobe_n_i,
  input logic        main_read_not_write_i,
  input logic [23:14] main_address_i
);
  logic external_bus_select_n;
  logic sound_reset_address_match;
  logic sound_reset_n;

  hard_drivin_main_sound_reset_decode dut (
    .main_address_strobe_n_i       (main_address_strobe_n_i),
    .main_valid_address_strobe_n_i (main_valid_address_strobe_n_i),
    .main_read_not_write_i         (main_read_not_write_i),
    .main_address_i                (main_address_i),
    .external_bus_select_n_o       (external_bus_select_n),
    .sound_reset_address_match_o   (sound_reset_address_match),
    .sound_reset_n_o               (sound_reset_n)
  );

  always_comb begin
    assert (external_bus_select_n ==
            (main_address_strobe_n_i ||
             (main_address_i[23:21] != 3'b100)));
    assert (sound_reset_address_match ==
            (main_address_i[20:14] == 7'b0010011));
    assert (sound_reset_n ==
            (external_bus_select_n ||
             main_valid_address_strobe_n_i ||
             main_read_not_write_i ||
             !sound_reset_address_match));

    cover (!sound_reset_n &&
           (main_address_i == 10'(24'h84c000 >> 14)));
    cover (sound_reset_address_match && main_read_not_write_i &&
           sound_reset_n);
    cover (sound_reset_address_match &&
           !main_address_strobe_n_i &&
           main_valid_address_strobe_n_i && sound_reset_n);
    cover (main_address_i[23:21] != 3'b100 &&
           external_bus_select_n && sound_reset_n);
  end
endmodule

`default_nettype wire
