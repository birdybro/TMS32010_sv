`default_nettype none

module hard_drivin_sound_local_reset_interlock_formal (
  input logic initialize_i,
  input logic board_reset_n_i,
  input logic local_processor_halt_n_i,
  input logic use_internal_local_ram_i,
  input logic local_ram_storage_ready_i
);
  logic local_processor_reset_n;
  logic local_processor_halt_n;
  logic local_processor_release_blocked;

  hard_drivin_sound_local_reset_interlock dut (
    .initialize_i                       (initialize_i),
    .board_reset_n_i                    (board_reset_n_i),
    .local_processor_halt_n_i           (local_processor_halt_n_i),
    .use_internal_local_ram_i           (use_internal_local_ram_i),
    .local_ram_storage_ready_i          (local_ram_storage_ready_i),
    .local_processor_reset_n_o          (local_processor_reset_n),
    .local_processor_halt_n_o           (local_processor_halt_n),
    .local_processor_release_blocked_o  (
      local_processor_release_blocked
    )
  );

  always_comb begin
    assert (local_processor_reset_n ==
            (!initialize_i && board_reset_n_i &&
             (!use_internal_local_ram_i || local_ram_storage_ready_i)));
    assert (local_processor_halt_n ==
            (!initialize_i && local_processor_halt_n_i &&
             (!use_internal_local_ram_i || local_ram_storage_ready_i)));
    assert (local_processor_release_blocked ==
            (board_reset_n_i && local_processor_halt_n_i &&
             (initialize_i ||
              (use_internal_local_ram_i &&
               !local_ram_storage_ready_i))));

    cover (board_reset_n_i && !initialize_i &&
           local_processor_halt_n_i && !use_internal_local_ram_i &&
           !local_ram_storage_ready_i && local_processor_reset_n &&
           local_processor_halt_n);
    cover (board_reset_n_i && local_processor_halt_n_i && !initialize_i &&
           use_internal_local_ram_i && !local_ram_storage_ready_i &&
           local_processor_release_blocked);
    cover (board_reset_n_i && local_processor_halt_n_i && !initialize_i &&
           use_internal_local_ram_i && local_ram_storage_ready_i &&
           local_processor_reset_n && local_processor_halt_n);
    cover (!board_reset_n_i && !local_processor_halt_n_i &&
           !local_processor_reset_n && !local_processor_halt_n &&
           !local_processor_release_blocked);
  end
endmodule

`default_nettype wire
