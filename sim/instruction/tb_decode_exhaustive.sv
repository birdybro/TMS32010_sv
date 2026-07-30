`default_nettype none

module tb_decode_exhaustive;
  import tms32010_pkg::*;

  logic [15:0]          instruction;
  logic                 valid;
  tms32010_operation_t  operation;
  logic [7:0]           immediate;
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
      expected_valid =
        expected_lac || expected_sacl || expected_sach ||
        expected_zalh || expected_zals || expected_adds ||
        expected_xor || expected_and || expected_or || expected_add ||
        expected_sub ||
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
    if (valid_count != 8896) begin
      $fatal(1, "expected 8896 supported words, got %0d", valid_count);
    end
    $display("PASS tb_decode_exhaustive");
    $finish;
  end
endmodule

`default_nettype wire
