`default_nettype none

// Symbolic contract for every 16-bit value and control combination. The
// independent reference forms increment carry and decrement borrow bit by bit.
module tms32010_auxiliary_counter_formal (
  input logic [15:0] value_i,
  input logic        increment_i,
  input logic        decrement_i
);
  logic [15:0] expected_value;
  logic [15:0] result_value;
  logic        expected_valid;
  logic        control_valid;
  logic        carry;
  logic        borrow;
  integer      bit_index;

  always_comb begin
    expected_valid = !(increment_i && decrement_i);
    expected_value = value_i;
    carry           = 1'b1;
    borrow          = 1'b1;

    for (bit_index = 0; bit_index < 9; bit_index = bit_index + 1) begin
      if (expected_valid && increment_i) begin
        expected_value[bit_index] = value_i[bit_index] ^ carry;
      end else if (expected_valid && decrement_i) begin
        expected_value[bit_index] = value_i[bit_index] ^ borrow;
      end
      carry  = carry && value_i[bit_index];
      borrow = borrow && !value_i[bit_index];
    end
  end

  tms32010_auxiliary_counter dut (
    .value_i         (value_i),
    .increment_i     (increment_i),
    .decrement_i     (decrement_i),
    .control_valid_o (control_valid),
    .value_o         (result_value)
  );

  always_comb begin
    assert (control_valid == expected_valid);
    assert (result_value == expected_value);
    assert (result_value[15:9] == value_i[15:9]);

    cover (
      increment_i && !decrement_i &&
      value_i == 16'ha1ff && result_value == 16'ha000
    );
    cover (
      !increment_i && decrement_i &&
      value_i == 16'ha000 && result_value == 16'ha1ff
    );
    cover (
      increment_i && !decrement_i &&
      value_i == 16'h0155 && result_value == 16'h0156
    );
    cover (
      !increment_i && decrement_i &&
      value_i == 16'h0155 && result_value == 16'h0154
    );
    cover (!increment_i && !decrement_i && result_value == value_i);
    cover (increment_i && decrement_i && !control_valid && result_value == value_i);
  end
endmodule

`default_nettype wire
