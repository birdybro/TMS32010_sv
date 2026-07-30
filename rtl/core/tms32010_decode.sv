`default_nettype none

module tms32010_decode (
  input  logic [15:0] instruction_i,
  output logic        valid_o,
  output logic [4:0]  operation_o,
  output logic [7:0]  immediate_o,
  output logic        auxiliary_register_o,
  output logic [3:0]  shift_o,
  output logic        indirect_o,
  output logic [6:0]  addressing_field_o
);
  // Keep the module boundary a packed vector: Ubuntu 24.04's Yosys 0.33
  // cannot elaborate a package-qualified enum port. The exhaustive decoder
  // test compares these values with tms32010_pkg and prevents silent drift.
  localparam logic [4:0] OP_LACK = 5'd0;
  localparam logic [4:0] OP_NOP  = 5'd1;
  localparam logic [4:0] OP_ZAC  = 5'd2;
  localparam logic [4:0] OP_ROVM = 5'd3;
  localparam logic [4:0] OP_SOVM = 5'd4;
  localparam logic [4:0] OP_LARK = 5'd5;
  localparam logic [4:0] OP_LARP = 5'd6;
  localparam logic [4:0] OP_LDPK = 5'd7;
  localparam logic [4:0] OP_LAC  = 5'd8;
  localparam logic [4:0] OP_SACL = 5'd9;
  localparam logic [4:0] OP_SACH = 5'd10;
  localparam logic [4:0] OP_ZALH = 5'd11;
  localparam logic [4:0] OP_ZALS = 5'd12;
  localparam logic [4:0] OP_ADDS = 5'd13;
  localparam logic [4:0] OP_XOR  = 5'd14;
  localparam logic [4:0] OP_AND  = 5'd15;
  localparam logic [4:0] OP_OR   = 5'd16;

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
    end else if (
      (instruction_i[15:11] == 5'b01011) &&
      (
        (instruction_i[10:8] == 3'd0) ||
        (instruction_i[10:8] == 3'd1) ||
        (instruction_i[10:8] == 3'd4)
      )
    ) begin
      operation_o = OP_SACH;
      shift_o     = {1'b0, instruction_i[10:8]};
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (instruction_i[15:8] == 8'h61) begin
      operation_o = OP_ADDS;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (
      (instruction_i[15:8] == 8'h65) ||
      (instruction_i[15:8] == 8'h66)
    ) begin
      operation_o =
        (instruction_i[15:8] == 8'h65) ? OP_ZALH : OP_ZALS;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (
      (instruction_i[15:8] == 8'h78) ||
      (instruction_i[15:8] == 8'h79) ||
      (instruction_i[15:8] == 8'h7a)
    ) begin
      case (instruction_i[15:8])
        8'h78: operation_o = OP_XOR;
        8'h79: operation_o = OP_AND;
        default: operation_o = OP_OR;
      endcase
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
