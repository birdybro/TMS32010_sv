`default_nettype none

// Storage-free transcription of the SP-327 main-board /EXTBUS selection and
// A044427 Rev-A /SRES write decode. Address bits A13:A1 and the byte strobes
// are intentionally absent because neither physical decode consumes them.
module hard_drivin_main_sound_reset_decode (
  input  logic        main_address_strobe_n_i,
  input  logic        main_valid_address_strobe_n_i,
  input  logic        main_read_not_write_i,
  input  logic [23:14] main_address_i,
  output logic        external_bus_select_n_o,
  output logic        sound_reset_address_match_o,
  output logic        sound_reset_n_o
);
  assign external_bus_select_n_o =
    main_address_strobe_n_i || (main_address_i[23:21] != 3'b100);
  assign sound_reset_address_match_o =
    (main_address_i[20:14] == 7'b0010011);
  assign sound_reset_n_o =
    external_bus_select_n_o || main_valid_address_strobe_n_i ||
    main_read_not_write_i || !sound_reset_address_match_o;

  always_comb begin
    assert (external_bus_select_n_o ==
            (main_address_strobe_n_i ||
             (main_address_i[23:21] != 3'b100)));
    assert (sound_reset_address_match_o ==
            (main_address_i[20:14] == 7'b0010011));
    assert (sound_reset_n_o ==
            (external_bus_select_n_o ||
             main_valid_address_strobe_n_i ||
             main_read_not_write_i ||
             !sound_reset_address_match_o));
    assert (sound_reset_n_o ||
            (!main_address_strobe_n_i &&
             !main_valid_address_strobe_n_i &&
             !main_read_not_write_i &&
             (main_address_i == 10'b1000010011)));
  end
endmodule

`default_nettype wire
