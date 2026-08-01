`default_nettype none

// Convert one original-MC68000 write-cycle bus value into the complete word
// captured by an unqualified 16-bit board target. Motorola Table 3-1 documents
// that the selected byte is driven on both halves of D15:D0 for a byte write on
// the MC68000 implementation. Board-specific documentation separately proves
// which A044427 targets lack UDS/LDS-derived lane enables.
module hard_drivin_mc68000_write_word (
  input  logic [15:0] bus_data_i,
  input  logic        upper_data_strobe_n_i,
  input  logic        lower_data_strobe_n_i,
  output logic [15:0] captured_word_o,
  output logic        transfer_valid_o,
  output logic        byte_transfer_o
);
  always_comb begin
    captured_word_o = 16'h0000;
    transfer_valid_o = 1'b1;
    byte_transfer_o = 1'b0;

    unique case ({upper_data_strobe_n_i, lower_data_strobe_n_i})
      2'b00: captured_word_o = bus_data_i;
      2'b01: begin
        captured_word_o = {2{bus_data_i[15:8]}};
        byte_transfer_o = 1'b1;
      end
      2'b10: begin
        captured_word_o = {2{bus_data_i[7:0]}};
        byte_transfer_o = 1'b1;
      end
      default: transfer_valid_o = 1'b0;
    endcase
  end

  always_comb begin
    assert (transfer_valid_o || (captured_word_o == 16'h0000));
    assert (!byte_transfer_o || transfer_valid_o);
    assert (!transfer_valid_o ||
            !(upper_data_strobe_n_i && lower_data_strobe_n_i));
  end
endmodule

`default_nettype wire
