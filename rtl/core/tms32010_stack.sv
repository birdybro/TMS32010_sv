`default_nettype none

// Portable four-level, 12-bit stack transition relation. PUSH and POP are
// architectural transforms; table_i selects the final state after the
// documented temporary PC push/pop in TBLR/TBLW. The caller owns timing and
// register commit. Simultaneous controls are invalid and fail closed to hold.
module tms32010_stack (
  input  logic [11:0] top_i,
  input  logic [11:0] level_1_i,
  input  logic [11:0] level_2_i,
  input  logic [11:0] bottom_i,
  input  logic [11:0] push_data_i,
  input  logic        push_i,
  input  logic        pop_i,
  input  logic        table_i,
  output logic        control_valid_o,
  output logic [11:0] top_o,
  output logic [11:0] level_1_o,
  output logic [11:0] level_2_o,
  output logic [11:0] bottom_o
);
  always_comb begin
    control_valid_o = !(
      (push_i && pop_i) ||
      (push_i && table_i) ||
      (pop_i && table_i)
    );

    top_o     = top_i;
    level_1_o = level_1_i;
    level_2_o = level_2_i;
    bottom_o  = bottom_i;

    if (control_valid_o) begin
      if (push_i) begin
        top_o     = push_data_i;
        level_1_o = top_i;
        level_2_o = level_1_i;
        bottom_o  = level_2_i;
      end else if (pop_i) begin
        top_o     = level_1_i;
        level_1_o = level_2_i;
        level_2_o = bottom_i;
        bottom_o  = bottom_i;
      end else if (table_i) begin
        // Final relation after push sequential PC, select ACC address, then
        // pop the saved PC: old level 2 is duplicated into the old bottom.
        bottom_o = level_2_i;
      end
    end
  end
endmodule

`default_nettype wire
