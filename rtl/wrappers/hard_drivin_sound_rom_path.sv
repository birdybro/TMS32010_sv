`default_nettype none

// Storage-free same-clock adapter for A044427's parallel sample-ROM path.
// The integration supplies authorized byte data and an explicit presence bit
// for each of the twelve decoded board positions. Absent/invalid selections
// are reported and deliberately never acknowledged.
module hard_drivin_sound_rom_path (
  input  logic [2:0]  io_port_i,
  input  logic        io_read_i,
  input  logic [15:0] sound_address_i,
  input  logic        sound_address_valid_i,
  input  logic [3:0]  sound_rom_block_i,
  input  logic        sound_rom_block_valid_i,
  input  logic [11:0] sound_rom_present_i,

  output logic        sound_rom_request_o,
  output logic [3:0]  sound_rom_request_block_o,
  output logic [15:0] sound_rom_request_address_o,
  input  logic [7:0]  sound_rom_byte_i,
  input  logic        sound_rom_byte_ready_i,

  output logic [15:0] port_0_read_data_o,
  output logic        port_0_ready_o,
  output logic        sound_rom_selection_invalid_o
);
  logic        port_0_read;
  logic        block_supported;
  logic        block_present;
  logic [15:0] extended_presence;

  always_comb begin
    port_0_read      = io_read_i && (io_port_i == 3'd0);
    block_supported = sound_rom_block_i < 4'd12;
    extended_presence = {4'b0000, sound_rom_present_i};
    block_present   = extended_presence[sound_rom_block_i];

    sound_rom_request_block_o   = sound_rom_block_i;
    sound_rom_request_address_o = sound_address_i;
    sound_rom_request_o =
      port_0_read &&
      sound_address_valid_i &&
      sound_rom_block_valid_i &&
      block_supported &&
      block_present;

    // A044427 wires SD14 to both TDI15 and TDI14, SD13:SD7 to
    // TDI13:TDI7, and grounds TDI6:TDI0. This is signed byte << 7.
    port_0_read_data_o = {
      sound_rom_byte_i[7], sound_rom_byte_i, 7'b0000000
    };
    port_0_ready_o = sound_rom_request_o && sound_rom_byte_ready_i;
    sound_rom_selection_invalid_o =
      port_0_read && !sound_rom_request_o;

    assert (!sound_rom_request_o || (
      port_0_read &&
      sound_address_valid_i &&
      sound_rom_block_valid_i &&
      block_supported &&
      block_present
    ));
    assert (!port_0_ready_o || sound_rom_request_o);
    assert (!sound_rom_selection_invalid_o || !port_0_ready_o);
  end
endmodule

`default_nettype wire
