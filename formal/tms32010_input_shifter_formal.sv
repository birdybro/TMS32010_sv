`default_nettype none

// Exhaustive symbolic contract for the signed input barrel shifter. The
// expected value is assembled bit by bit so the reference does not reuse the
// DUT's concatenation-and-shift expression.
module tms32010_input_shifter_formal (
  input logic [15:0] data_i,
  input logic [3:0]  shift_i
);
  logic [31:0] expected_result;
  logic [31:0] result;
  integer bit_index;
  integer source_index;

  always_comb begin
    expected_result = 32'h0000_0000;
    source_index = 0;
    for (bit_index = 0; bit_index < 32; bit_index = bit_index + 1) begin
      source_index = bit_index - shift_i;
      if (source_index < 0) begin
        expected_result[bit_index] = 1'b0;
      end else if (source_index < 16) begin
        expected_result[bit_index] = data_i[source_index];
      end else begin
        expected_result[bit_index] = data_i[15];
      end
    end
  end

  tms32010_input_shifter dut (
    .data_i   (data_i),
    .shift_i  (shift_i),
    .result_o (result)
  );

  always_comb begin
    assert (result == expected_result);

    cover (
      data_i == 16'h8000 && shift_i == 4'd0 &&
      result == 32'hffff_8000
    );
    cover (
      data_i == 16'h0001 && shift_i == 4'd15 &&
      result == 32'h0000_8000
    );
    cover (
      data_i == 16'hffff && shift_i == 4'd15 &&
      result == 32'hffff_8000
    );
    cover (
      data_i == 16'h7fff && shift_i == 4'd15 &&
      result == 32'h3fff_8000
    );
  end
endmodule

`default_nettype wire
