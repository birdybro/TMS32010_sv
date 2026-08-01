`default_nettype none

// Storage-free FPGA boundary for A044427 Rev-A /SWITCHES. Non-inverting
// LS244 10H maps {J3-11,J3-9,J3-8,J3-7} to host D15:D12. The drawing does
// not establish cabinet semantics or a source for D11:D0, so connector value
// validity and deterministic carrier filler remain explicit and separate.
module hard_drivin_sound_switches (
  input  logic [3:0]  j3_switch_i,
  input  logic [3:0]  j3_switch_valid_i,
  output logic [15:0] host_read_data_o,
  output logic [15:0] host_driven_mask_o,
  output logic [15:0] host_valid_mask_o
);
  always_comb begin
    host_read_data_o = {
      j3_switch_i & j3_switch_valid_i,
      12'h000
    };
    host_driven_mask_o = 16'hf000;
    host_valid_mask_o = {
      j3_switch_valid_i,
      12'h000
    };

    assert (host_driven_mask_o == 16'hf000);
    assert ((host_valid_mask_o & ~host_driven_mask_o) == 16'h0000);
    assert ((host_read_data_o & ~host_valid_mask_o) == 16'h0000);
    assert (host_read_data_o[11:0] == 12'h000);
    assert (host_read_data_o[15:12] ==
            (j3_switch_i & j3_switch_valid_i));
    assert (host_valid_mask_o[15:12] == j3_switch_valid_i);
  end
endmodule

`default_nettype wire
