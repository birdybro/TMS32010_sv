`default_nettype none

// Storage-free transcription of the SP-327 sheet-4 main MC68000 primary,
// RAM-bank, and high-speed-host address decoders. The physical processor
// exposes A23:A1; bits not consumed by these TTL devices remain at the module
// boundary so their broad address aliases can be tested explicitly.
module hard_drivin_main_address_decode (
  /* verilator lint_off UNUSEDSIGNAL */
  input  logic [23:1] address_i,
  /* verilator lint_on UNUSEDSIGNAL */
  input  logic        address_strobe_n_i,
  input  logic        rvas0_n_i,

  // Indexes preserve the populated decoder output numbers: vector bit N is
  // active-low YN. Y1/Y2 of the primary LS138 and Y2/Y3 of the HSBUS LS139
  // are physically unconnected but remain observable here.
  output logic [7:0]  primary_select_n_o,
  output logic [3:0]  ram_select_n_o,
  output logic [3:0]  high_speed_select_n_o,

  output logic        rom_enable_n_o,
  output logic        n_bus_select_n_o,
  output logic        external_bus_select_n_o,
  output logic        low_speed_bus_select_n_o,
  output logic        high_speed_bus_select_n_o,
  output logic        ram_enable_n_o,

  output logic        duart_select_n_o,
  output logic        zero_ram_select_n_o,
  output logic        ram0_select_n_o,
  output logic        ram1_select_n_o,

  output logic        read_high_speed_bus_n_o,
  output logic        gsp_select_n_o,
  output logic        msp_select_n_o
);
  // LS138 160K is enabled by pulled-high G1, asserted /AS on G2A, and
  // grounded G2B. Its C:B:A inputs are A23:A21.
  always_comb begin
    primary_select_n_o = 8'hff;
    if (!address_strobe_n_i) begin
      primary_select_n_o[address_i[23:21]] = 1'b0;
    end
  end

  assign rom_enable_n_o = primary_select_n_o[0];
  assign n_bus_select_n_o = primary_select_n_o[3];
  assign external_bus_select_n_o = primary_select_n_o[4];
  assign low_speed_bus_select_n_o = primary_select_n_o[5];
  assign high_speed_bus_select_n_o = primary_select_n_o[6];
  assign ram_enable_n_o = primary_select_n_o[7];

  // The first half of dual LS139 180E is enabled by /RAMEN. Its B:A inputs
  // are A15:A14 and every output is active low.
  always_comb begin
    ram_select_n_o = 4'hf;
    if (!ram_enable_n_o) begin
      ram_select_n_o[address_i[15:14]] = 1'b0;
    end
  end

  assign duart_select_n_o = ram_select_n_o[0];
  assign zero_ram_select_n_o = ram_select_n_o[1];
  assign ram0_select_n_o = ram_select_n_o[2];
  assign ram1_select_n_o = ram_select_n_o[3];

  // AS32 160H qualifies raw /HSBUS with the early held /RVAS0 strobe. The
  // second half of 180E then decodes A15:A14; only Y0=/GSP and Y1=/MSP are
  // connected on SP-327.
  assign read_high_speed_bus_n_o =
    high_speed_bus_select_n_o || rvas0_n_i;

  always_comb begin
    high_speed_select_n_o = 4'hf;
    if (!read_high_speed_bus_n_o) begin
      high_speed_select_n_o[address_i[15:14]] = 1'b0;
    end
  end

  assign gsp_select_n_o = high_speed_select_n_o[0];
  assign msp_select_n_o = high_speed_select_n_o[1];

  always_comb begin
    assert ($onehot0(~primary_select_n_o));
    assert ($onehot0(~ram_select_n_o));
    assert ($onehot0(~high_speed_select_n_o));
    assert (rom_enable_n_o == primary_select_n_o[0]);
    assert (n_bus_select_n_o == primary_select_n_o[3]);
    assert (external_bus_select_n_o == primary_select_n_o[4]);
    assert (low_speed_bus_select_n_o == primary_select_n_o[5]);
    assert (high_speed_bus_select_n_o == primary_select_n_o[6]);
    assert (ram_enable_n_o == primary_select_n_o[7]);
    assert (duart_select_n_o == ram_select_n_o[0]);
    assert (zero_ram_select_n_o == ram_select_n_o[1]);
    assert (ram0_select_n_o == ram_select_n_o[2]);
    assert (ram1_select_n_o == ram_select_n_o[3]);
    assert (read_high_speed_bus_n_o ==
            (high_speed_bus_select_n_o || rvas0_n_i));
    assert (gsp_select_n_o == high_speed_select_n_o[0]);
    assert (msp_select_n_o == high_speed_select_n_o[1]);
    assert (ram_enable_n_o || (ram_select_n_o != 4'hf));
    assert (!ram_enable_n_o || (ram_select_n_o == 4'hf));
    assert (read_high_speed_bus_n_o ||
            (high_speed_select_n_o != 4'hf));
    assert (!read_high_speed_bus_n_o ||
            (high_speed_select_n_o == 4'hf));
  end
endmodule

`default_nettype wire
