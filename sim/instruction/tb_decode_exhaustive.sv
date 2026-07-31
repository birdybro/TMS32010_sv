`default_nettype none

module tb_decode_exhaustive;
  import tms32010_pkg::*;

  logic [15:0]          instruction;
  logic                 valid;
  tms32010_operation_t  operation;
  logic [7:0]           immediate;
  logic [12:0]          immediate_13;
  logic                 auxiliary_register;
  logic [3:0]           shift;
  logic                 indirect;
  logic [6:0]           addressing_field;
  int unsigned          valid_count;

  tms32010_decode dut (
    .instruction_i (instruction),
    .valid_o       (valid),
    .operation_o   (operation),
    .immediate_o   (immediate),
    .immediate_13_o (immediate_13),
    .auxiliary_register_o (auxiliary_register),
    .shift_o       (shift),
    .indirect_o    (indirect),
    .addressing_field_o (addressing_field)
  );

  initial begin
    valid_count = 0;
    for (int unsigned word = 0; word < 65536; word++) begin
      logic expected_valid;
      logic expected_lac;
      logic expected_sacl;
      logic expected_sach;
      logic expected_zalh;
      logic expected_zals;
      logic expected_adds;
      logic expected_xor;
      logic expected_and;
      logic expected_or;
      logic expected_add;
      logic expected_sub;
      logic expected_subs;
      logic expected_lar;
      logic expected_sar;
      logic expected_mar;
      logic expected_ldp;
      logic expected_dmov;
      logic expected_lt;
      logic expected_ltd;
      logic expected_lta;
      logic expected_mpy;
      logic expected_mpyk;
      logic expected_pac;
      logic expected_apac;
      logic expected_spac;
      instruction = word[15:0];
      #1;
      expected_lac =
        (instruction[15:12] == 4'h2) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_sacl =
        (instruction[15:8] == 8'h50) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_sach =
        (instruction[15:11] == 5'b01011) &&
        (
          (instruction[10:8] == 3'd0) ||
          (instruction[10:8] == 3'd1) ||
          (instruction[10:8] == 3'd4)
        ) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_zalh =
        (instruction[15:8] == 8'h65) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_zals =
        (instruction[15:8] == 8'h66) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_adds =
        (instruction[15:8] == 8'h61) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_xor =
        (instruction[15:8] == 8'h78) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_and =
        (instruction[15:8] == 8'h79) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_or =
        (instruction[15:8] == 8'h7a) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_add =
        (instruction[15:12] == 4'h0) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_sub =
        (instruction[15:12] == 4'h1) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_subs =
        (instruction[15:8] == 8'h63) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_lar =
        (instruction[15:9] == 7'b0011100) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_sar =
        (instruction[15:9] == 7'b0011000) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_mar =
        (instruction[15:8] == 8'h68) &&
        ((instruction & 16'hfffe) != 16'h6880) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_ldp =
        (instruction[15:8] == 8'h6f) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_dmov =
        (instruction[15:8] == 8'h69) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_lt =
        (instruction[15:8] == 8'h6a) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_ltd =
        (instruction[15:8] == 8'h6b) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_lta =
        (instruction[15:8] == 8'h6c) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_mpy =
        (instruction[15:8] == 8'h6d) &&
        (
          !instruction[7] ||
          (
            !instruction[6] &&
            (instruction[2:1] == 2'b00) &&
            (instruction[5:4] != 2'b11)
          )
        );
      expected_mpyk = instruction[15:13] == 3'b100;
      expected_pac = instruction == 16'h7f8e;
      expected_apac = instruction == 16'h7f8f;
      expected_spac = instruction == 16'h7f90;
      expected_valid =
        expected_lac || expected_sacl || expected_sach ||
        expected_zalh || expected_zals || expected_adds ||
        expected_xor || expected_and || expected_or || expected_add ||
        expected_sub || expected_subs || expected_lar || expected_sar ||
        expected_mar || expected_ldp || expected_dmov ||
        expected_lt || expected_ltd ||
        expected_lta ||
        expected_mpy ||
        expected_mpyk || expected_pac || expected_apac || expected_spac ||
        ((instruction & 16'hfffe) == 16'h6880) ||
        ((instruction & 16'hfffe) == 16'h6e00) ||
        ((instruction & 16'hfe00) == 16'h7000) ||
        ((instruction & 16'hff00) == 16'h7e00) ||
        (instruction == 16'h7f80) ||
        (instruction == 16'h7f89) ||
        (instruction == 16'h7f8a) ||
        (instruction == 16'h7f8b);
      if (valid !== expected_valid) begin
        $fatal(1, "decode validity mismatch at %04x", word);
      end
      if (valid) begin
        valid_count++;
      end
      if (expected_lac) begin
        if (operation != OP_LAC ||
            shift != word[11:8] ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "LAC decode mismatch at %04x", word);
        end
      end
      if (expected_sacl) begin
        if (operation != OP_SACL ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "SACL decode mismatch at %04x", word);
        end
      end
      if (expected_sach) begin
        if (operation != OP_SACH ||
            shift != {1'b0, word[10:8]} ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "SACH decode mismatch at %04x", word);
        end
      end
      if (expected_zalh) begin
        if (operation != OP_ZALH ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "ZALH decode mismatch at %04x", word);
        end
      end
      if (expected_zals) begin
        if (operation != OP_ZALS ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "ZALS decode mismatch at %04x", word);
        end
      end
      if (expected_adds) begin
        if (operation != OP_ADDS ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "ADDS decode mismatch at %04x", word);
        end
      end
      if (expected_xor || expected_and || expected_or) begin
        if (operation !=
              (expected_xor ? OP_XOR : (expected_and ? OP_AND : OP_OR)) ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "logic decode mismatch at %04x", word);
        end
      end
      if (expected_add) begin
        if (operation != OP_ADD ||
            shift != word[11:8] ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "ADD decode mismatch at %04x", word);
        end
      end
      if (expected_sub) begin
        if (operation != OP_SUB ||
            shift != word[11:8] ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "SUB decode mismatch at %04x", word);
        end
      end
      if (expected_subs) begin
        if (operation != OP_SUBS ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "SUBS decode mismatch at %04x", word);
        end
      end
      if (expected_lar) begin
        if (operation != OP_LAR ||
            auxiliary_register != word[8] ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "LAR decode mismatch at %04x", word);
        end
      end
      if (expected_sar) begin
        if (operation != OP_SAR ||
            auxiliary_register != word[8] ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "SAR decode mismatch at %04x", word);
        end
      end
      if (expected_mar) begin
        if (operation != OP_MAR ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "MAR decode mismatch at %04x", word);
        end
      end
      if (expected_ldp) begin
        if (operation != OP_LDP ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "LDP decode mismatch at %04x", word);
        end
      end
      if (expected_dmov) begin
        if (operation != OP_DMOV ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "DMOV decode mismatch at %04x", word);
        end
      end
      if (expected_lt) begin
        if (operation != OP_LT ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "LT decode mismatch at %04x", word);
        end
      end
      if (expected_ltd) begin
        if (operation != OP_LTD ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "LTD decode mismatch at %04x", word);
        end
      end
      if (expected_mpy) begin
        if (operation != OP_MPY ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "MPY decode mismatch at %04x", word);
        end
      end
      if (expected_lta) begin
        if (operation != OP_LTA ||
            indirect != word[7] ||
            addressing_field != word[6:0]) begin
          $fatal(1, "LTA decode mismatch at %04x", word);
        end
      end
      if (expected_mpyk) begin
        if (operation != OP_MPYK || immediate_13 != word[12:0]) begin
          $fatal(1, "MPYK decode mismatch at %04x", word);
        end
      end
      if (expected_pac && operation != OP_PAC) begin
        $fatal(1, "PAC decode mismatch at %04x", word);
      end
      if (expected_apac && operation != OP_APAC) begin
        $fatal(1, "APAC decode mismatch at %04x", word);
      end
      if (expected_spac && operation != OP_SPAC) begin
        $fatal(1, "SPAC decode mismatch at %04x", word);
      end
      if ((instruction & 16'hff00) == 16'h7e00) begin
        if (operation != OP_LACK || immediate != word[7:0]) begin
          $fatal(1, "LACK decode mismatch at %04x", word);
        end
      end
      if ((instruction & 16'hfe00) == 16'h7000) begin
        if (operation != OP_LARK ||
            auxiliary_register != word[8] ||
            immediate != word[7:0]) begin
          $fatal(1, "LARK decode mismatch at %04x", word);
        end
      end
      if ((instruction & 16'hfffe) == 16'h6880) begin
        if (operation != OP_LARP || immediate[0] != word[0]) begin
          $fatal(1, "LARP decode mismatch at %04x", word);
        end
      end
      if ((instruction & 16'hfffe) == 16'h6e00) begin
        if (operation != OP_LDPK || immediate[0] != word[0]) begin
          $fatal(1, "LDPK decode mismatch at %04x", word);
        end
      end
    end
    if (valid_count != 18769) begin
      $fatal(1, "expected 18769 supported words, got %0d", valid_count);
    end
    $display("PASS tb_decode_exhaustive");
    $finish;
  end
endmodule

`default_nettype wire
