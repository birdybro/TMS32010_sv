`default_nettype none

// SACH output shifter. The original instruction exposes only left shifts
// zero, one, and four; invalid selections fail closed at this local boundary.
module tms32010_output_shifter (
  // ACC[31:12]; lower bits cannot reach the stored word at shift <= 4.
  input  logic [19:0] accumulator_high_i,
  input  logic [2:0]  shift_i,
  output logic        shift_valid_o,
  output logic [15:0] result_o
);
  always_comb begin
    shift_valid_o = 1'b1;
    case (shift_i)
      3'd0: result_o = accumulator_high_i[19:4];
      3'd1: result_o = accumulator_high_i[18:3];
      3'd4: result_o = accumulator_high_i[15:0];
      default: begin
        shift_valid_o = 1'b0;
        result_o      = 16'h0000;
      end
    endcase
  end
endmodule

`default_nettype wire
