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
      expected_valid =
        expected_lac ||
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
    if (valid_count != 3016) begin
      $fatal(1, "expected 3016 supported words, got %0d", valid_count);
    end
    $display("PASS tb_decode_exhaustive");
    $finish;
  end
endmodule

`default_nettype wire
