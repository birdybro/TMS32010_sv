`default_nettype none

// Storage-free FPGA boundary for A044427 Rev-A /READSTAT. LS244 10K drives
// only host D15:D12; D11:D0 have no source in this selected target. Each raw
// high-nibble input therefore carries independent validity, while the low
// twelve zero bits remain deterministic interface filler outside the masks.
module hard_drivin_sound_read_status (
  input  logic        main_flag_i,
  input  logic        main_flag_valid_i,
  input  logic        sound_flag_i,
  input  logic        sound_flag_valid_i,
  input  logic        sound_test_i,
  input  logic        sound_test_valid_i,
  input  logic        tirdy_n_i,
  input  logic        tirdy_n_valid_i,
  output logic [15:0] host_read_data_o,
  output logic [15:0] host_driven_mask_o,
  output logic [15:0] host_valid_mask_o
);
  always_comb begin
    // Invalid sources use zero only as an explicit deterministic carrier.
    // Consumers must honor host_valid_mask_o before interpreting any bit.
    host_read_data_o = {
      main_flag_valid_i  ? main_flag_i  : 1'b0,
      sound_flag_valid_i ? sound_flag_i : 1'b0,
      sound_test_valid_i ? sound_test_i : 1'b0,
      tirdy_n_valid_i    ? tirdy_n_i    : 1'b0,
      12'h000
    };
    host_driven_mask_o = 16'hf000;
    host_valid_mask_o = {
      main_flag_valid_i,
      sound_flag_valid_i,
      sound_test_valid_i,
      tirdy_n_valid_i,
      12'h000
    };

    assert (host_driven_mask_o == 16'hf000);
    assert ((host_valid_mask_o & ~host_driven_mask_o) == 16'h0000);
    assert ((host_read_data_o & ~host_valid_mask_o) == 16'h0000);
    assert (host_read_data_o[11:0] == 12'h000);
    assert (host_read_data_o[15] ==
            (main_flag_valid_i && main_flag_i));
    assert (host_read_data_o[14] ==
            (sound_flag_valid_i && sound_flag_i));
    assert (host_read_data_o[13] ==
            (sound_test_valid_i && sound_test_i));
    assert (host_read_data_o[12] ==
            (tirdy_n_valid_i && tirdy_n_i));
  end
endmodule

`default_nettype wire
