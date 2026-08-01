`default_nettype none

// Exhaustive symbolic contract for the shared 32-bit accumulator arithmetic.
// The signed 33-bit mathematical result is an independently width-extended
// reference for wrap, overflow, and OVM-selected saturation.
module tms32010_accumulator_formal (
  input logic [31:0] accumulator_i,
  input logic [31:0] operand_i,
  input logic        subtract_i,
  input logic        overflow_mode_i
);
  logic signed [32:0] extended_accumulator;
  logic signed [32:0] extended_operand;
  logic signed [32:0] mathematical_result;
  logic signed [32:0] signed_minimum;
  logic signed [32:0] signed_maximum;
  logic        expected_overflow;
  logic [31:0] expected_result;
  logic [31:0] wrapped_result;
  logic        overflow;
  logic [31:0] result;

  assign extended_accumulator = {
    accumulator_i[31],
    accumulator_i
  };
  assign extended_operand = {operand_i[31], operand_i};
  assign mathematical_result = subtract_i
    ? (extended_accumulator - extended_operand)
    : (extended_accumulator + extended_operand);
  assign signed_minimum = -33'sh08000_0000;
  assign signed_maximum = 33'sh07fff_ffff;
  assign expected_overflow =
    (mathematical_result < signed_minimum) ||
    (mathematical_result > signed_maximum);

  always_comb begin
    expected_result = mathematical_result[31:0];
    if (expected_overflow && overflow_mode_i) begin
      expected_result =
        (mathematical_result < signed_minimum)
          ? 32'h8000_0000
          : 32'h7fff_ffff;
    end
  end

  tms32010_accumulator dut (
    .accumulator_i    (accumulator_i),
    .operand_i        (operand_i),
    .subtract_i       (subtract_i),
    .overflow_mode_i  (overflow_mode_i),
    .wrapped_result_o (wrapped_result),
    .overflow_o       (overflow),
    .result_o         (result)
  );

  always_comb begin
    assert (wrapped_result == mathematical_result[31:0]);
    assert (overflow == expected_overflow);
    assert (result == expected_result);
    assert (
      (result != wrapped_result) ==
      (overflow_mode_i && overflow)
    );

    if (!overflow_mode_i || !overflow) begin
      assert (result == wrapped_result);
    end
    if (overflow_mode_i && overflow) begin
      assert (
        (result == 32'h8000_0000) ||
        (result == 32'h7fff_ffff)
      );
    end

    cover (
      !subtract_i && overflow_mode_i &&
      accumulator_i == 32'h7fff_ffff &&
      operand_i == 32'h0000_0001 &&
      result == 32'h7fff_ffff
    );
    cover (
      !subtract_i && overflow_mode_i &&
      accumulator_i == 32'h8000_0000 &&
      operand_i == 32'hffff_ffff &&
      result == 32'h8000_0000
    );
    cover (
      subtract_i && overflow_mode_i &&
      accumulator_i == 32'h7fff_ffff &&
      operand_i == 32'hffff_ffff &&
      result == 32'h7fff_ffff
    );
    cover (
      subtract_i && overflow_mode_i &&
      accumulator_i == 32'h8000_0000 &&
      operand_i == 32'h0000_0001 &&
      result == 32'h8000_0000
    );
  end
endmodule

`default_nettype wire
