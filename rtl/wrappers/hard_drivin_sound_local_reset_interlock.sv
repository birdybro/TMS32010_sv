`default_nettype none

// FPGA platform reset-release policy for a local MC68000 paired with the
// optional lane-valid SRAM. A044427's physical /RESET source remains the
// authority; the additional ready qualification exists only because the FPGA
// validity metadata needs 8192 fabric clocks to scrub.
module hard_drivin_sound_local_reset_interlock (
  input  logic initialize_i,
  input  logic board_reset_n_i,
  input  logic local_processor_halt_n_i,
  input  logic use_internal_local_ram_i,
  input  logic local_ram_storage_ready_i,
  output logic local_processor_reset_n_o,
  output logic local_processor_halt_n_o,
  output logic local_processor_release_blocked_o
);
  logic platform_release_permitted;

  assign platform_release_permitted =
    !initialize_i &&
    (!use_internal_local_ram_i || local_ram_storage_ready_i);

  assign local_processor_reset_n_o =
    board_reset_n_i && platform_release_permitted;
  assign local_processor_halt_n_o =
    local_processor_halt_n_i && platform_release_permitted;

  assign local_processor_release_blocked_o =
    board_reset_n_i && local_processor_halt_n_i &&
    !platform_release_permitted;

  always_comb begin
    assert (!local_processor_reset_n_o || board_reset_n_i);
    assert (!local_processor_reset_n_o || !initialize_i);
    assert (!local_processor_reset_n_o ||
            !use_internal_local_ram_i || local_ram_storage_ready_i);
    assert (!local_processor_halt_n_o || local_processor_halt_n_i);
    assert (!local_processor_halt_n_o || !initialize_i);
    assert (!local_processor_halt_n_o ||
            !use_internal_local_ram_i || local_ram_storage_ready_i);
    assert (!local_processor_release_blocked_o ||
            (!local_processor_reset_n_o && !local_processor_halt_n_o));
  end
endmodule

`default_nettype wire
