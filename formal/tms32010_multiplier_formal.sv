`default_nettype none

// RTL-001 exhaustive symbolic contract for the original-part multiplier.
// Every 16-bit input pair remains unconstrained. The mathematical reference
// is deliberately expressed with explicit 32-bit sign extension so this
// proof guards the RTL's operand signedness and result width as well as TI's
// one documented nonmathematical result.
module tms32010_multiplier_formal (
  input logic [15:0] multiplicand_i,
  input logic [15:0] multiplier_i
);
  logic signed [31:0] extended_multiplicand;
  logic signed [31:0] extended_multiplier;
  logic signed [31:0] mathematical_product;
  logic        [31:0] product;
  logic        [31:0] swapped_product;
  logic               exceptional_pair;

  assign extended_multiplicand = {
    {16{multiplicand_i[15]}},
    multiplicand_i
  };
  assign extended_multiplier = {
    {16{multiplier_i[15]}},
    multiplier_i
  };
  assign mathematical_product =
    extended_multiplicand * extended_multiplier;
  assign exceptional_pair =
    (multiplicand_i == 16'h8000) &&
    (multiplier_i == 16'h8000);

  tms32010_multiplier dut (
    .multiplicand_i (multiplicand_i),
    .multiplier_i   (multiplier_i),
    .product_o      (product)
  );

  tms32010_multiplier swapped_dut (
    .multiplicand_i (multiplier_i),
    .multiplier_i   (multiplicand_i),
    .product_o      (swapped_product)
  );

  always_comb begin
    if (exceptional_pair) begin
      assert (product == 32'hc000_0000);
    end else begin
      assert (product == mathematical_product);
    end

    // The TI exception is the only permitted departure from signed
    // mathematical multiplication, and operand order remains immaterial.
    assert ((product != mathematical_product) == exceptional_pair);
    assert (product == swapped_product);

    // These identities make zero and unity boundaries visible independently
    // of the full reference-product equality.
    if (multiplicand_i == 16'h0000 || multiplier_i == 16'h0000) begin
      assert (product == 32'h0000_0000);
    end
    if (multiplicand_i == 16'h0001) begin
      assert (product == extended_multiplier);
    end
    if (multiplier_i == 16'h0001) begin
      assert (product == extended_multiplicand);
    end

    cover (
      exceptional_pair &&
      product == 32'hc000_0000
    );
    cover (
      multiplicand_i == 16'h7fff &&
      multiplier_i == 16'h7fff &&
      product == 32'h3fff_0001
    );
    cover (
      multiplicand_i == 16'h8000 &&
      multiplier_i == 16'h0001 &&
      product == 32'hffff_8000
    );
    cover (
      multiplicand_i == 16'hffff &&
      multiplier_i == 16'h8000 &&
      product == 32'h0000_8000
    );
  end
endmodule

`default_nettype wire
