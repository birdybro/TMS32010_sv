`default_nettype none

module tms32010_multiplier (
  input  logic [15:0] multiplicand_i,
  input  logic [15:0] multiplier_i,
  output logic [31:0] product_o
);
  logic signed [15:0] signed_multiplicand;
  logic signed [15:0] signed_multiplier;

  always_comb begin
    signed_multiplicand = $signed(multiplicand_i);
    signed_multiplier   = $signed(multiplier_i);
    product_o           = signed_multiplicand * signed_multiplier;

    // SPRU001B p. 3-43 documents this original hardware exception.
    if (
      (multiplicand_i == 16'h8000) &&
      (multiplier_i == 16'h8000)
    ) begin
      product_o = 32'hc000_0000;
    end
  end
endmodule

`default_nettype wire
