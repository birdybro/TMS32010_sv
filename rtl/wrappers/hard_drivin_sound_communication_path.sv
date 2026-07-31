`default_nettype none

// Combined same-clock communication-RAM and sound-address control boundary.
// Other physical I/O targets remain outside this module.
module hard_drivin_sound_communication_path (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        communication_host_enable_i,

  input  logic        host_select_n_i,
  input  logic        host_write_i,
  input  logic        host_commit_i,
  input  logic [8:0]  host_address_i,
  input  logic [15:0] host_write_data_i,
  output logic [15:0] host_read_data_o,
  output logic        host_ready_o,
  output logic        host_access_permitted_o,
  output logic        host_blocked_o,

  input  logic [2:0]  io_port_i,
  input  logic        io_read_i,
  input  logic        io_write_i,
  input  logic [15:0] io_write_data_i,
  input  logic        io_commit_i,
  output logic [15:0] port_1_read_data_o,
  output logic        port_1_ready_o,
  output logic        port_1_blocked_o,
  output logic        port_1_address_invalid_o,

  output logic [15:0] sound_address_o,
  output logic        sound_address_valid_o,
  output logic [3:0]  sound_rom_block_o,
  output logic        sound_rom_block_valid_o
);
  logic dsp_port_1_read;
  logic dsp_access_permitted;

  assign dsp_port_1_read =
    io_read_i && (io_port_i == 3'd1) && sound_address_valid_o;
  assign port_1_address_invalid_o =
    io_read_i && (io_port_i == 3'd1) && !sound_address_valid_o;

  hard_drivin_sound_address_control address_control (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .io_port_i                     (io_port_i),
    .io_read_i                     (io_read_i),
    .io_write_i                    (io_write_i),
    .io_write_data_i               (io_write_data_i),
    .io_commit_i                   (io_commit_i),
    .sound_address_o               (sound_address_o),
    .sound_address_valid_o         (sound_address_valid_o),
    .sound_rom_block_o             (sound_rom_block_o),
    .sound_rom_block_valid_o       (sound_rom_block_valid_o)
  );

  hard_drivin_sound_communication_ram communication_storage (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .communication_host_enable_i   (communication_host_enable_i),
    .host_select_n_i               (host_select_n_i),
    .host_write_i                  (host_write_i),
    .host_commit_i                 (host_commit_i),
    .host_address_i                (host_address_i),
    .host_write_data_i             (host_write_data_i),
    .host_read_data_o              (host_read_data_o),
    .host_ready_o                  (host_ready_o),
    .host_access_permitted_o       (host_access_permitted_o),
    .host_blocked_o                (host_blocked_o),
    .dsp_read_i                    (dsp_port_1_read),
    .dsp_address_i                 (sound_address_o[8:0]),
    .dsp_read_data_o               (port_1_read_data_o),
    .dsp_ready_o                   (port_1_ready_o),
    .dsp_access_permitted_o        (dsp_access_permitted),
    .dsp_blocked_o                 (port_1_blocked_o)
  );

  always_ff @(posedge clk_i) begin
    if (!initialize_i) begin
      assert (!port_1_ready_o || (
        io_read_i &&
        (io_port_i == 3'd1) &&
        sound_address_valid_o &&
        dsp_access_permitted
      ));
      assert (!port_1_address_invalid_o || !port_1_ready_o);
    end
  end
endmodule

`default_nettype wire
