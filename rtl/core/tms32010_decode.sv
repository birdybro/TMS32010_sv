`default_nettype none

module tms32010_decode (
  input  logic [15:0]                       instruction_i,
  output logic                              valid_o,
  output tms32010_pkg::tms32010_operation_t operation_o,
  output logic [7:0]                        immediate_o
);
  import tms32010_pkg::*;

  always_comb begin
    valid_o     = 1'b1;
    operation_o = OP_NOP;
    immediate_o = instruction_i[7:0];

    casez (instruction_i)
      16'b0111_1110_????_????: operation_o = OP_LACK;
      16'h7f80:                operation_o = OP_NOP;
      16'h7f89:                operation_o = OP_ZAC;
      16'h7f8a:                operation_o = OP_ROVM;
      16'h7f8b:                operation_o = OP_SOVM;
      default: begin
        valid_o     = 1'b0;
        operation_o = OP_NOP;
        immediate_o = 8'h00;
      end
    endcase
  end
endmodule

`default_nettype wire
