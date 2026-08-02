`default_nettype none

// Symbolic SACH output-shifter contract. The legal result is assembled bit
// by bit so the reference does not reuse the DUT's part-select expressions.
module tms32010_output_shifter_formal (
  input logic [31:0] accumulator_i,
  input logic [2:0]  shift_i
);
  logic        expected_valid;
  logic [15:0] expected_result;
  logic        shift_valid;
  logic [15:0] result;
  integer bit_index;
  integer source_index;

  always_comb begin
    expected_valid =
      (shift_i == 3'd0) ||
      (shift_i == 3'd1) ||
      (shift_i == 3'd4);
    expected_result = 16'h0000;
    bit_index = 0;
    source_index = 0;
    if (expected_valid) begin
      for (bit_index = 0; bit_index < 16; bit_index = bit_index + 1) begin
        source_index = bit_index + 16 - shift_i;
        expected_result[bit_index] = accumulator_i[source_index];
      end
    end
  end

  tms32010_output_shifter dut (
    .accumulator_high_i (accumulator_i[31:12]),
    .shift_i            (shift_i),
    .shift_valid_o      (shift_valid),
    .result_o           (result)
  );

  always_comb begin
    assert (shift_valid == expected_valid);
    assert (result == expected_result);

    cover (
      accumulator_i == 32'ha34b_78cd && shift_i == 3'd4 &&
      shift_valid && result == 16'h34b7
    );
    cover (
      accumulator_i == 32'h0420_8001 && shift_i == 3'd1 &&
      shift_valid && result == 16'h0841
    );
    cover (
      accumulator_i == 32'h8000_ffff && shift_i == 3'd0 &&
      shift_valid && result == 16'h8000
    );
    cover (
      accumulator_i == 32'h0000_ffff && shift_i == 3'd4 &&
      shift_valid && result == 16'h000f
    );
    cover (shift_i == 3'd2 && !shift_valid && result == 16'h0000);
    cover (shift_i == 3'd7 && !shift_valid && result == 16'h0000);
  end
endmodule

`default_nettype wire
