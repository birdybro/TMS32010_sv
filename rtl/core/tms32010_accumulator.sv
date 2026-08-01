`default_nettype none

// Shared signed 32-bit accumulator arithmetic for ADD/SUB, SUBH,
// APAC/SPAC, and the previous-product accumulation in LTA/LTD. The caller
// owns sticky-OV state; this block reports only the current operation's
// overflow and OVM-selected result.
module tms32010_accumulator (
  input  logic [31:0] accumulator_i,
  input  logic [31:0] operand_i,
  input  logic        subtract_i,
  input  logic        overflow_mode_i,
  output logic [31:0] wrapped_result_o,
  output logic        overflow_o,
  output logic [31:0] result_o
);
  always_comb begin
    if (subtract_i) begin
      wrapped_result_o = accumulator_i - operand_i;
      overflow_o =
        (accumulator_i[31] ^ operand_i[31]) &&
        (accumulator_i[31] ^ wrapped_result_o[31]);
    end else begin
      wrapped_result_o = accumulator_i + operand_i;
      overflow_o =
        ~(accumulator_i[31] ^ operand_i[31]) &&
        (accumulator_i[31] ^ wrapped_result_o[31]);
    end

    result_o = wrapped_result_o;
    if (overflow_o && overflow_mode_i) begin
      result_o = accumulator_i[31]
        ? 32'h8000_0000
        : 32'h7fff_ffff;
    end
  end
endmodule

`default_nettype wire
