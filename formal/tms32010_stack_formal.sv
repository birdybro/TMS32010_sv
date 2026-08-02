`default_nettype none

// Symbolic contract for all hold, push, pop, table-final, and invalid-control
// transitions. The reference uses direct array indexing and an independently
// selected source index for every destination level.
module tms32010_stack_formal (
  input logic [11:0] top_i,
  input logic [11:0] level_1_i,
  input logic [11:0] level_2_i,
  input logic [11:0] bottom_i,
  input logic [11:0] push_data_i,
  input logic        push_i,
  input logic        pop_i,
  input logic        table_i
);
  logic [11:0] old_stack [0:3];
  logic [11:0] expected_stack [0:3];
  logic [11:0] result_stack [0:3];
  logic        expected_valid;
  logic        control_valid;
  integer      level_index;
  integer      assert_index;

  always_comb begin
    old_stack[0] = top_i;
    old_stack[1] = level_1_i;
    old_stack[2] = level_2_i;
    old_stack[3] = bottom_i;

    expected_valid = !(
      (push_i && pop_i) ||
      (push_i && table_i) ||
      (pop_i && table_i)
    );

    for (level_index = 0; level_index < 4; level_index = level_index + 1) begin
      expected_stack[level_index] = old_stack[level_index];
    end

    if (expected_valid && push_i) begin
      expected_stack[0] = push_data_i;
      for (level_index = 1; level_index < 4; level_index = level_index + 1) begin
        expected_stack[level_index] = old_stack[level_index - 1];
      end
    end else if (expected_valid && pop_i) begin
      for (level_index = 0; level_index < 3; level_index = level_index + 1) begin
        expected_stack[level_index] = old_stack[level_index + 1];
      end
      expected_stack[3] = old_stack[3];
    end else if (expected_valid && table_i) begin
      expected_stack[3] = old_stack[2];
    end
  end

  tms32010_stack dut (
    .top_i           (top_i),
    .level_1_i       (level_1_i),
    .level_2_i       (level_2_i),
    .bottom_i        (bottom_i),
    .push_data_i     (push_data_i),
    .push_i          (push_i),
    .pop_i           (pop_i),
    .table_i         (table_i),
    .control_valid_o (control_valid),
    .top_o           (result_stack[0]),
    .level_1_o       (result_stack[1]),
    .level_2_o       (result_stack[2]),
    .bottom_o        (result_stack[3])
  );

  always_comb begin
    assert (control_valid == expected_valid);
    for (assert_index = 0; assert_index < 4; assert_index = assert_index + 1) begin
      assert (result_stack[assert_index] == expected_stack[assert_index]);
    end

    cover (
      push_i && !pop_i && !table_i &&
      push_data_i == 12'h555 &&
      top_i == 12'h444 && level_1_i == 12'h333 &&
      level_2_i == 12'h222 && bottom_i == 12'h111 &&
      result_stack[0] == 12'h555 && result_stack[3] == 12'h222
    );
    cover (
      !push_i && pop_i && !table_i &&
      top_i == 12'h444 && level_1_i == 12'h333 &&
      level_2_i == 12'h222 && bottom_i == 12'h111 &&
      result_stack[0] == 12'h333 && result_stack[3] == 12'h111
    );
    cover (
      !push_i && pop_i && !table_i &&
      top_i == 12'h111 && level_1_i == 12'h111 &&
      level_2_i == 12'h111 && bottom_i == 12'h111
    );
    cover (
      !push_i && !pop_i && table_i &&
      level_2_i == 12'h222 && bottom_i == 12'h111 &&
      result_stack[2] == 12'h222 && result_stack[3] == 12'h222
    );
    cover (!push_i && !pop_i && !table_i && control_valid);
    cover (push_i && pop_i && table_i && !control_valid);
  end
endmodule

`default_nettype wire
