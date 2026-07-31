`default_nettype none

// ISA-001/RTL-002 exhaustive safety contract for the partial RTL decoder.
// The compact validity predicate is intentionally structured differently
// from the decoder's priority chain. The primary-cited ISA database and hand
// fixtures remain the authority for mnemonic and operand identity.
module tms32010_decode_formal (
  input logic [15:0] instruction_i
);
  logic        valid;
  logic [5:0]  operation;
  logic [7:0]  immediate;
  logic [12:0] immediate_13;
  logic        auxiliary_register;
  logic [3:0]  shift;
  logic [2:0]  port;
  logic        indirect;
  logic [6:0]  addressing_field;
  logic        expected_valid;

  function automatic logic is_common_address_envelope(
    input logic [15:0] word
  );
    logic [7:0] high_byte;
    begin
      high_byte = word[15:8];
      is_common_address_envelope =
        (word[15:12] == 4'h0) ||
        (word[15:12] == 4'h1) ||
        (word[15:12] == 4'h2) ||
        (word[15:11] == 5'b00110) || // SAR envelope; AR0/AR1 below
        (word[15:11] == 5'b00111) || // LAR envelope; AR0/AR1 below
        (word[15:11] == 5'b01000) || // IN
        (word[15:11] == 5'b01001) || // OUT
        (high_byte == 8'h50) ||
        (word[15:11] == 5'b01011) || // SACH; sparse shifts below
        ((high_byte >= 8'h60) && (high_byte <= 8'h6d) &&
         (high_byte != 8'h6e)) ||
        (high_byte == 8'h6f) ||
        ((high_byte >= 8'h78) && (high_byte <= 8'h7d));
    end
  endfunction

  function automatic logic common_family_fields_legal(
    input logic [15:0] word
  );
    logic register_field_legal;
    logic sach_shift_legal;
    logic sst_direct_legal;
    begin
      register_field_legal = 1'b1;
      if ((word[15:11] == 5'b00110) ||
          (word[15:11] == 5'b00111)) begin
        register_field_legal = word[10:9] == 2'b00;
      end

      sach_shift_legal = 1'b1;
      if (word[15:11] == 5'b01011) begin
        sach_shift_legal =
          (word[10:8] == 3'd0) ||
          (word[10:8] == 3'd1) ||
          (word[10:8] == 3'd4);
      end

      sst_direct_legal = 1'b1;
      if ((word[15:8] == 8'h7c) && !word[7]) begin
        sst_direct_legal = word[6:4] == 3'b000;
      end

      common_family_fields_legal =
        register_field_legal && sach_shift_legal && sst_direct_legal;
    end
  endfunction

  function automatic logic common_address_fields_legal(
    input logic [15:0] word
  );
    begin
      common_address_fields_legal =
        !word[7] ||
        (!word[6] && (word[2:1] == 2'b00) &&
         (word[5:4] != 2'b11));
    end
  endfunction

  function automatic logic is_supported_fixed_control(
    input logic [15:0] word
  );
    begin
      case (word)
        16'h7f80,
        16'h7f81,
        16'h7f82,
        16'h7f88,
        16'h7f89,
        16'h7f8a,
        16'h7f8b,
        16'h7f8e,
        16'h7f8f,
        16'h7f90: is_supported_fixed_control = 1'b1;
        default: is_supported_fixed_control = 1'b0;
      endcase
    end
  endfunction

  function automatic logic is_two_word_control_prefix(
    input logic [7:0] high_byte
  );
    begin
      case (high_byte)
        8'hf4,
        8'hf5,
        8'hf6,
        8'hf8,
        8'hf9,
        8'hfa,
        8'hfb,
        8'hfc,
        8'hfd,
        8'hfe,
        8'hff: is_two_word_control_prefix = 1'b1;
        default: is_two_word_control_prefix = 1'b0;
      endcase
    end
  endfunction

  tms32010_decode dut (
    .instruction_i          (instruction_i),
    .valid_o                (valid),
    .operation_o            (operation),
    .immediate_o            (immediate),
    .immediate_13_o         (immediate_13),
    .auxiliary_register_o   (auxiliary_register),
    .shift_o                (shift),
    .port_o                 (port),
    .indirect_o             (indirect),
    .addressing_field_o     (addressing_field)
  );

  always_comb begin
    expected_valid =
      (is_common_address_envelope(instruction_i) &&
       common_family_fields_legal(instruction_i) &&
       common_address_fields_legal(instruction_i)) ||
      (instruction_i[15:13] == 3'b100) ||
      ((instruction_i[15:8] == 8'h6e) &&
       (instruction_i[7:1] == 7'h00)) ||
      (instruction_i[15:9] == 7'b0111000) ||
      (instruction_i[15:8] == 8'h7e) ||
      is_supported_fixed_control(instruction_i) ||
      (is_two_word_control_prefix(instruction_i[15:8]) &&
       (instruction_i[7:0] == 8'h00));

    // This one-step symbolic check exhausts the complete 16-bit word space.
    assert (valid == expected_valid);
    // The partial RTL operation enum is currently dense from 0 through 55;
    // the exhaustive simulation separately guards its package name mapping.
    assert (operation <= 6'd55);
    assert (immediate_13 == instruction_i[12:0]);

    // Operand projections are checked independently of mnemonic selection.
    if (valid && is_common_address_envelope(instruction_i)) begin
      assert (indirect == instruction_i[7]);
      assert (addressing_field == instruction_i[6:0]);
    end
    if (valid && (instruction_i[15:11] == 5'b01000 ||
                  instruction_i[15:11] == 5'b01001)) begin
      assert (port == instruction_i[10:8]);
    end
    if (valid && (instruction_i[15:12] == 4'h0 ||
                  instruction_i[15:12] == 4'h1 ||
                  instruction_i[15:12] == 4'h2)) begin
      assert (shift == instruction_i[11:8]);
    end
    if (valid && (instruction_i[15:11] == 5'b01011)) begin
      assert ((shift == 4'd0) || (shift == 4'd1) || (shift == 4'd4));
    end
    if (valid && (instruction_i[15:9] == 7'b0111000)) begin
      assert (immediate == instruction_i[7:0]);
      assert (auxiliary_register == instruction_i[8]);
    end
    if (valid && ((instruction_i[15:9] == 7'b0011000) ||
                  (instruction_i[15:9] == 7'b0011100))) begin
      assert (auxiliary_register == instruction_i[8]);
    end
    if (valid && (instruction_i[15:8] == 8'h7e)) begin
      assert (immediate == instruction_i[7:0]);
    end

    // Model/tool support for these four exact opcodes must not silently cross
    // into RTL before their native second-cycle ownership is qualified.
    if ((instruction_i == 16'h7f8c) || // CALA
        (instruction_i == 16'h7f8d) || // RET
        (instruction_i == 16'h7f9c) || // PUSH
        (instruction_i == 16'h7f9d)) begin // POP
      assert (!valid);
    end

    cover (instruction_i == 16'h007f && valid);
    cover (instruction_i == 16'h00a1 && valid);
    cover (instruction_i == 16'h00c8 && !valid);
    cover (instruction_i == 16'h00b0 && !valid);
    cover (instruction_i == 16'hf401 && !valid);
    cover (instruction_i == 16'h7f83 && !valid);
    cover (instruction_i == 16'h7f8c && !valid);
    cover (instruction_i == 16'h9fff && valid &&
           (immediate_13 == 13'h1fff));
  end
endmodule

`default_nettype wire
