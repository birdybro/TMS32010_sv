`default_nettype none

// Signed 16-to-32-bit input barrel shifter used by LAC, ADD, and SUB.
// The selected data word is sign-extended before the encoded 0..15 left
// shift; the caller owns instruction decode, addressing, and ALU effects.
module tms32010_input_shifter (
  input  logic [15:0] data_i,
  input  logic [3:0]  shift_i,
  output logic [31:0] result_o
);
  always_comb begin
    result_o = {{16{data_i[15]}}, data_i} << shift_i;
  end
endmodule

`default_nettype wire
