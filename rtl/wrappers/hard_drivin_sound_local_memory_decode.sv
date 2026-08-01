`default_nettype none

// Storage-free transcription of the A044427 Rev-A local MC68000 ROM/RAM
// decode on sheet 3. This module exposes active-low board controls and the
// populated 27256/6264 address projections; it does not provide memory,
// DTACK timing, an open-bus value, or the optional larger-EPROM jumper mode.
module hard_drivin_sound_local_memory_decode (
  // A22:A17 are physically present but intentionally absent from both the
  // ROM gate and LS138 30P decode. Keep them at the interface to preserve and
  // test the board aliases.
  /* verilator lint_off UNUSEDSIGNAL */
  input  logic [23:1] address_i,
  /* verilator lint_on UNUSEDSIGNAL */
  input  logic        address_strobe_n_i,
  input  logic        rva_i,
  input  logic        rvas_n_i,
  input  logic        read_not_write_i,
  input  logic        upper_data_strobe_n_i,
  input  logic        lower_data_strobe_n_i,

  output logic [7:0]  high_bank_select_n_o,
  output logic        rom_select_n_o,
  output logic        rvf_select_n_o,
  output logic        program_bank_select_n_o,
  output logic        communication_bank_select_n_o,
  output logic        local_ram_select_n_o,
  output logic        host_program_select_n_o,
  output logic        host_communication_select_n_o,
  output logic        host_program_ram_chip_enable_n_o,
  output logic        host_program_ram_write_n_o,
  output logic        host_program_io_write_enable_n_o,
  output logic        host_program_io_data_enable_n_o,
  output logic        host_program_ram_read_o,
  output logic        host_program_ram_write_o,
  output logic        host_program_io_read_o,
  output logic        host_program_io_write_o,

  output logic        read_output_enable_n_o,
  output logic        read_write_strobe_n_o,
  output logic        upper_write_enable_n_o,
  output logic        lower_write_enable_n_o,
  output logic        rom_read_o,
  output logic        local_ram_read_o,
  output logic        local_ram_upper_write_o,
  output logic        local_ram_lower_write_o,
  output logic [15:0] rom_read_driven_mask_o,
  output logic [15:0] local_ram_read_driven_mask_o,

  output logic [14:0] populated_rom_word_address_o,
  output logic [11:0] host_program_word_address_o,
  output logic [12:0] local_ram_word_address_o
);
  // LS138 30P is enabled only by A23=1 and asserted /AS. Its selects are
  // A16:A14. Outputs Y4..Y7 are the only ones reached in the 0xffxxxx page;
  // retaining all eight outputs makes the physical alias behavior explicit.
  always_comb begin
    high_bank_select_n_o = 8'hff;
    if (!address_strobe_n_i && address_i[23]) begin
      high_bank_select_n_o[address_i[16:14]] = 1'b0;
    end
  end

  // ALS32 30R makes EPROM /CE = A23 OR /AS. A22:A16 therefore do not
  // participate in selection. The populated 27256 pair uses CPU A1:A15 as
  // its fifteen word-address bits; A16 reaches only the optional jumper.
  assign rom_select_n_o = address_i[23] || address_strobe_n_i;
  assign populated_rom_word_address_o = address_i[15:1];

  assign rvf_select_n_o = high_bank_select_n_o[4];
  assign program_bank_select_n_o = high_bank_select_n_o[5];
  assign communication_bank_select_n_o = high_bank_select_n_o[6];
  assign local_ram_select_n_o = high_bank_select_n_o[7];

  // The program/communication buffer selects are further qualified by the
  // held /RVAS interval. Local 6264 /CS1 is driven directly by LS138 Y7.
  assign host_program_select_n_o = program_bank_select_n_o || rvas_n_i;
  assign host_communication_select_n_o =
    communication_bank_select_n_o || rvas_n_i;

  // Y5's 16 KiB bank is subdecoded by A13. With the host buffer enabled,
  // lower-half cycles drive the program-RAM controls. Upper-half writes pulse
  // the TMS /PWE control from RVA; upper-half reads hold /PDEN through RVAS.
  // The board's pull-ups make all four buffered outputs inactive outside Y5.
  assign host_program_ram_chip_enable_n_o =
    host_program_select_n_o || address_i[13] || rvas_n_i;
  assign host_program_ram_write_n_o =
    host_program_select_n_o || read_not_write_i;
  assign host_program_io_write_enable_n_o =
    host_program_select_n_o ||
    !(rva_i && !read_not_write_i && address_i[13]);
  assign host_program_io_data_enable_n_o =
    host_program_select_n_o ||
    !(!rvas_n_i && read_not_write_i && address_i[13]);
  assign host_program_ram_read_o =
    !host_program_ram_chip_enable_n_o && read_not_write_i;
  assign host_program_ram_write_o =
    !host_program_ram_chip_enable_n_o &&
    !host_program_ram_write_n_o;
  assign host_program_io_read_o = !host_program_io_data_enable_n_o;
  assign host_program_io_write_o = !host_program_io_write_enable_n_o;

  // Two F04 stages provide complementary R/W forms. The first, /RWNB, drives
  // both EPROM and local-RAM /OE pins. ALS32 30R makes /RWS, then separately
  // qualifies the upper and lower 6264 /WE inputs with /UDS and /LDS.
  assign read_output_enable_n_o = !read_not_write_i;
  assign read_write_strobe_n_o = rvas_n_i || read_not_write_i;
  assign upper_write_enable_n_o =
    upper_data_strobe_n_i || read_write_strobe_n_o;
  assign lower_write_enable_n_o =
    lower_data_strobe_n_i || read_write_strobe_n_o;

  assign rom_read_o = !rom_select_n_o && !read_output_enable_n_o;
  assign local_ram_read_o =
    !local_ram_select_n_o && !read_output_enable_n_o;
  assign local_ram_upper_write_o =
    !local_ram_select_n_o && !upper_write_enable_n_o;
  assign local_ram_lower_write_o =
    !local_ram_select_n_o && !lower_write_enable_n_o;
  assign rom_read_driven_mask_o = rom_read_o ? 16'hffff : 16'h0000;
  assign local_ram_read_driven_mask_o =
    local_ram_read_o ? 16'hffff : 16'h0000;

  // The two 6264 slices share CPU A1:A13 and form 8K 16-bit words.
  assign host_program_word_address_o = address_i[12:1];
  assign local_ram_word_address_o = address_i[13:1];

  always_comb begin
    assert ($onehot0(~high_bank_select_n_o));
    assert (rom_select_n_o == (address_i[23] || address_strobe_n_i));
    assert (rvf_select_n_o == high_bank_select_n_o[4]);
    assert (program_bank_select_n_o == high_bank_select_n_o[5]);
    assert (communication_bank_select_n_o == high_bank_select_n_o[6]);
    assert (local_ram_select_n_o == high_bank_select_n_o[7]);
    assert (!(host_program_ram_read_o && host_program_ram_write_o));
    assert (!(host_program_ram_read_o && host_program_io_read_o));
    assert (!(host_program_ram_write_o && host_program_io_write_o));
    assert (!host_program_io_read_o ||
            (address_i[13] && read_not_write_i));
    assert (!host_program_io_write_o ||
            (address_i[13] && !read_not_write_i && rva_i));
    assert (!(rom_read_o && local_ram_read_o));
    assert (!local_ram_upper_write_o || !local_ram_select_n_o);
    assert (!local_ram_lower_write_o || !local_ram_select_n_o);
    assert (!read_not_write_i ||
            !(local_ram_upper_write_o || local_ram_lower_write_o));
    assert (rom_read_driven_mask_o ==
            (rom_read_o ? 16'hffff : 16'h0000));
    assert (local_ram_read_driven_mask_o ==
            (local_ram_read_o ? 16'hffff : 16'h0000));
  end
endmodule

`default_nettype wire
