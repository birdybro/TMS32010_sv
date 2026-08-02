`default_nettype none

// Portable low-nine-bit auxiliary-register counter relation. The caller owns
// register selection, access ordering, ARP updates, and the commit boundary.
// Simultaneous increment/decrement is unsupported and fails closed to hold.
module tms32010_auxiliary_counter (
  input  logic [15:0] value_i,
  input  logic        increment_i,
  input  logic        decrement_i,
  output logic        control_valid_o,
  output logic [15:0] value_o
);
  always_comb begin
    control_valid_o = !(increment_i && decrement_i);
    value_o         = value_i;

    if (control_valid_o) begin
      if (increment_i) begin
        value_o = {value_i[15:9], value_i[8:0] + 9'd1};
      end else if (decrement_i) begin
        value_o = {value_i[15:9], value_i[8:0] - 9'd1};
      end
    end
  end
endmodule

`default_nettype wire
