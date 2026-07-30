`default_nettype none

module tms32010_decode (
  input  logic [15:0] instruction_i,
  output logic        valid_o,
  output logic [3:0]  operation_o,
  output logic [7:0]  immediate_o,
  output logic        auxiliary_register_o,
  output logic [3:0]  shift_o,
  output logic        indirect_o,
  output logic [6:0]  addressing_field_o
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
  localparam logic [3:0] OP_LAC  = 4'd8;
  localparam logic [3:0] OP_SACL = 4'd9;

  always_comb begin
    valid_o              = 1'b0;
    operation_o          = OP_NOP;
    immediate_o          = instruction_i[7:0];
    auxiliary_register_o = instruction_i[8];
    shift_o              = instruction_i[11:8];
    indirect_o           = instruction_i[7];
    addressing_field_o   = instruction_i[6:0];

    if (instruction_i[15:12] == 4'h2) begin
      operation_o = OP_LAC;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (instruction_i[15:8] == 8'h50) begin
      operation_o = OP_SACL;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else begin
      casez (instruction_i)
        16'b0110_1000_1000_000?: begin
          valid_o     = 1'b1;
          operation_o = OP_LARP;
        end
        16'b0110_1110_0000_000?: begin
          valid_o     = 1'b1;
          operation_o = OP_LDPK;
        end
        16'b0111_000?_????_????: begin
          valid_o     = 1'b1;
          operation_o = OP_LARK;
        end
        16'b0111_1110_????_????: begin
          valid_o     = 1'b1;
          operation_o = OP_LACK;
        end
        16'h7f80: begin
          valid_o     = 1'b1;
          operation_o = OP_NOP;
        end
        16'h7f89: begin
          valid_o     = 1'b1;
          operation_o = OP_ZAC;
        end
        16'h7f8a: begin
          valid_o     = 1'b1;
          operation_o = OP_ROVM;
        end
        16'h7f8b: begin
          valid_o     = 1'b1;
          operation_o = OP_SOVM;
        end
        default: begin
          immediate_o          = 8'h00;
          auxiliary_register_o = 1'b0;
          shift_o              = 4'h0;
          indirect_o           = 1'b0;
          addressing_field_o   = 7'h00;
        end
      endcase
    end
  end
endmodule

`default_nettype wire
