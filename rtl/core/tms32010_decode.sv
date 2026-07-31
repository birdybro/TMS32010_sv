`default_nettype none

module tms32010_decode (
  input  logic [15:0] instruction_i,
  output logic        valid_o,
  output logic [5:0]  operation_o,
  output logic [7:0]  immediate_o,
  output logic [12:0] immediate_13_o,
  output logic        auxiliary_register_o,
  output logic [3:0]  shift_o,
  output logic        indirect_o,
  output logic [6:0]  addressing_field_o
);
  // Keep the module boundary a packed vector: Ubuntu 24.04's Yosys 0.33
  // cannot elaborate a package-qualified enum port. The exhaustive decoder
  // test compares these values with tms32010_pkg and prevents silent drift.
  localparam logic [5:0] OP_LACK = 6'd0;
  localparam logic [5:0] OP_NOP  = 6'd1;
  localparam logic [5:0] OP_ZAC  = 6'd2;
  localparam logic [5:0] OP_ROVM = 6'd3;
  localparam logic [5:0] OP_SOVM = 6'd4;
  localparam logic [5:0] OP_LARK = 6'd5;
  localparam logic [5:0] OP_LARP = 6'd6;
  localparam logic [5:0] OP_LDPK = 6'd7;
  localparam logic [5:0] OP_LAC  = 6'd8;
  localparam logic [5:0] OP_SACL = 6'd9;
  localparam logic [5:0] OP_SACH = 6'd10;
  localparam logic [5:0] OP_ZALH = 6'd11;
  localparam logic [5:0] OP_ZALS = 6'd12;
  localparam logic [5:0] OP_ADDS = 6'd13;
  localparam logic [5:0] OP_XOR  = 6'd14;
  localparam logic [5:0] OP_AND  = 6'd15;
  localparam logic [5:0] OP_OR   = 6'd16;
  localparam logic [5:0] OP_ADD  = 6'd17;
  localparam logic [5:0] OP_SUB  = 6'd18;
  localparam logic [5:0] OP_SUBS = 6'd19;
  localparam logic [5:0] OP_LAR  = 6'd20;
  localparam logic [5:0] OP_SAR  = 6'd21;
  localparam logic [5:0] OP_MAR  = 6'd22;
  localparam logic [5:0] OP_LDP  = 6'd23;
  localparam logic [5:0] OP_LT   = 6'd24;
  localparam logic [5:0] OP_MPY  = 6'd25;
  localparam logic [5:0] OP_MPYK = 6'd26;
  localparam logic [5:0] OP_PAC  = 6'd27;
  localparam logic [5:0] OP_APAC = 6'd28;
  localparam logic [5:0] OP_SPAC = 6'd29;
  localparam logic [5:0] OP_LTA  = 6'd30;
  localparam logic [5:0] OP_LTD  = 6'd31;
  localparam logic [5:0] OP_DMOV = 6'd32;
  localparam logic [5:0] OP_DINT = 6'd33;
  localparam logic [5:0] OP_EINT = 6'd34;
  localparam logic [5:0] OP_LST  = 6'd35;
  localparam logic [5:0] OP_SUBC = 6'd36;
  localparam logic [5:0] OP_BANZ = 6'd37;
  localparam logic [5:0] OP_B    = 6'd38;
  localparam logic [5:0] OP_BGEZ = 6'd39;
  localparam logic [5:0] OP_BGZ  = 6'd40;
  localparam logic [5:0] OP_BLEZ = 6'd41;
  localparam logic [5:0] OP_BLZ  = 6'd42;
  localparam logic [5:0] OP_BNZ  = 6'd43;
  localparam logic [5:0] OP_BZ   = 6'd44;
  localparam logic [5:0] OP_BV   = 6'd45;

  always_comb begin
    valid_o              = 1'b0;
    operation_o          = OP_NOP;
    immediate_o          = instruction_i[7:0];
    immediate_13_o       = instruction_i[12:0];
    auxiliary_register_o = instruction_i[8];
    shift_o              = instruction_i[11:8];
    indirect_o           = instruction_i[7];
    addressing_field_o   = instruction_i[6:0];

    if (
      (instruction_i[15:12] == 4'h0) ||
      (instruction_i[15:12] == 4'h1)
    ) begin
      operation_o =
        (instruction_i[15:12] == 4'h0) ? OP_ADD : OP_SUB;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (instruction_i[15:12] == 4'h2) begin
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
    end else if (instruction_i[15:9] == 7'b0011000) begin
      operation_o = OP_SAR;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (instruction_i[15:9] == 7'b0011100) begin
      operation_o = OP_LAR;
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
    end else if (
      (instruction_i[15:8] == 8'h61) ||
      (instruction_i[15:8] == 8'h63) ||
      (instruction_i[15:8] == 8'h64)
    ) begin
      case (instruction_i[15:8])
        8'h61: operation_o = OP_ADDS;
        8'h63: operation_o = OP_SUBS;
        default: operation_o = OP_SUBC;
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
    end else if (instruction_i[15:8] == 8'h7b) begin
      operation_o = OP_LST;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (instruction_i[15:8] == 8'h68) begin
      if ((instruction_i & 16'hfffe) == 16'h6880) begin
        valid_o     = 1'b1;
        operation_o = OP_LARP;
      end else begin
        operation_o = OP_MAR;
        if (!instruction_i[7]) begin
          valid_o = 1'b1;
        end else if (
          (instruction_i[6] == 1'b0) &&
          (instruction_i[2:1] == 2'b00) &&
          (instruction_i[5:4] != 2'b11)
        ) begin
          valid_o     = 1'b1;
        end
      end
    end else if (instruction_i[15:8] == 8'h6f) begin
      operation_o = OP_LDP;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (instruction_i[15:8] == 8'h69) begin
      operation_o = OP_DMOV;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (instruction_i[15:8] == 8'h6a) begin
      operation_o = OP_LT;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (instruction_i[15:8] == 8'h6b) begin
      operation_o = OP_LTD;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (instruction_i[15:8] == 8'h6c) begin
      operation_o = OP_LTA;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (instruction_i[15:8] == 8'h6d) begin
      operation_o = OP_MPY;
      if (!instruction_i[7]) begin
        valid_o = 1'b1;
      end else if (
        (instruction_i[6] == 1'b0) &&
        (instruction_i[2:1] == 2'b00) &&
        (instruction_i[5:4] != 2'b11)
      ) begin
        valid_o = 1'b1;
      end
    end else if (instruction_i[15:13] == 3'b100) begin
      valid_o     = 1'b1;
      operation_o = OP_MPYK;
    end else begin
      casez (instruction_i)
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
        16'h7f81: begin
          valid_o     = 1'b1;
          operation_o = OP_DINT;
        end
        16'h7f82: begin
          valid_o     = 1'b1;
          operation_o = OP_EINT;
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
        16'h7f8e: begin
          valid_o     = 1'b1;
          operation_o = OP_PAC;
        end
        16'h7f8f: begin
          valid_o     = 1'b1;
          operation_o = OP_APAC;
        end
        16'h7f90: begin
          valid_o     = 1'b1;
          operation_o = OP_SPAC;
        end
        16'hf400: begin
          valid_o     = 1'b1;
          operation_o = OP_BANZ;
        end
        16'hf500: begin
          valid_o     = 1'b1;
          operation_o = OP_BV;
        end
        16'hf900: begin
          valid_o     = 1'b1;
          operation_o = OP_B;
        end
        16'hfa00: begin
          valid_o     = 1'b1;
          operation_o = OP_BLZ;
        end
        16'hfb00: begin
          valid_o     = 1'b1;
          operation_o = OP_BLEZ;
        end
        16'hfc00: begin
          valid_o     = 1'b1;
          operation_o = OP_BGZ;
        end
        16'hfd00: begin
          valid_o     = 1'b1;
          operation_o = OP_BGEZ;
        end
        16'hfe00: begin
          valid_o     = 1'b1;
          operation_o = OP_BNZ;
        end
        16'hff00: begin
          valid_o     = 1'b1;
          operation_o = OP_BZ;
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
