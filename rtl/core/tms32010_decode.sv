`default_nettype none

module tms32010_decode (
  input  logic [15:0] instruction_i,
  output logic        valid_o,
  output logic [3:0]  operation_o,
  output logic [7:0]  immediate_o,
  output logic        auxiliary_register_o
);
  // Keep the module boundary a packed vector: Ubuntu 24.04's Yosys 0.33
  // cannot elaborate a package-qualified enum port. The exhaustive decoder
  // test compares these values with tms32010_pkg and prevents silent drift.
  localparam logic [3:0] OP_LACK = 4'd0;
  localparam logic [3:0] OP_NOP  = 4'd1;
  localparam logic [3:0] OP_ZAC  = 4'd2;
  localparam logic [3:0] OP_ROVM = 4'd3;
  localparam logic [3:0] OP_SOVM = 4'd4;
  localparam logic [3:0] OP_LARK = 4'd5;
  localparam logic [3:0] OP_LARP = 4'd6;
  localparam logic [3:0] OP_LDPK = 4'd7;

  always_comb begin
    valid_o              = 1'b1;
    operation_o          = OP_NOP;
    immediate_o          = instruction_i[7:0];
    auxiliary_register_o = instruction_i[8];

    casez (instruction_i)
      16'b0110_1000_1000_000?: operation_o = OP_LARP;
      16'b0110_1110_0000_000?: operation_o = OP_LDPK;
      16'b0111_000?_????_????: operation_o = OP_LARK;
      16'b0111_1110_????_????: operation_o = OP_LACK;
      16'h7f80:                operation_o = OP_NOP;
      16'h7f89:                operation_o = OP_ZAC;
      16'h7f8a:                operation_o = OP_ROVM;
      16'h7f8b:                operation_o = OP_SOVM;
      default: begin
        valid_o              = 1'b0;
        operation_o          = OP_NOP;
        immediate_o          = 8'h00;
        auxiliary_register_o = 1'b0;
      end
    endcase
  end
endmodule

`default_nettype wire
