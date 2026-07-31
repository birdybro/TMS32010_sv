`default_nettype none

// Board-specific combinational glue transcribed from Atari A044427 Rev A,
// sheets 3 through 5. This module does not arbitrate or store program RAM.
// It exposes the physical decode, including the unsafe overlap that occurs if
// the 68000 selects DSP program RAM while /320RES is released.
module hard_drivin_sound_bus_decode (
  input  logic        dsp_reset_n_i,
  input  logic        host_program_select_n_i,

  input  logic [11:0] tms_address_i,
  input  logic        tms_men_n_i,
  input  logic        tms_den_n_i,
  input  logic        tms_we_n_i,

  output logic        dsp_path_enable_o,
  output logic        host_path_enable_o,
  output logic        ownership_conflict_o,

  output logic        port_region_o,
  output logic [2:0]  io_port_o,
  output logic        io_read_o,
  output logic        io_write_o,
  output logic        dsp_program_read_o,
  output logic        dsp_program_write_o,
  output logic        dsp_program_ram_select_n_o
);
  // /320RES is also inverted to enable the TMS-side LS244 buffers. The host
  // buffers have the independent active-low /320RAM enable; no mutual-
  // exclusion gate exists on the drawing.
  assign dsp_path_enable_o = dsp_reset_n_i;
  assign host_path_enable_o = !host_program_select_n_i;
  assign ownership_conflict_o =
    dsp_path_enable_o && host_path_enable_o;

  // PORT is high only when TA11:TA3 are all zero. The output and input
  // decoders then use TA2:TA0.
  assign port_region_o = tms_address_i[11:3] == 9'd0;
  assign io_port_o = tms_address_i[2:0];
  assign io_read_o = !tms_den_n_i && port_region_o;
  assign io_write_o = !tms_we_n_i && port_region_o;

  // /RAMEN = /MEN AND (/TWE OR PORT). Consequently MEN reads select program
  // RAM at every address, while WE writes select it only outside ports 0..7.
  // A low-address TBLW is therefore decoded exactly like OUT by this board.
  assign dsp_program_read_o = !tms_men_n_i;
  assign dsp_program_write_o = !tms_we_n_i && !port_region_o;
  assign dsp_program_ram_select_n_o =
    tms_men_n_i && (tms_we_n_i || port_region_o);
endmodule

`default_nettype wire
