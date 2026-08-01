`default_nettype none

module tb_hard_drivin_sound_local_reset_interlock;
  logic initialize;
  logic board_reset_n;
  logic local_processor_halt_n_input;
  logic use_internal_local_ram;
  logic local_ram_storage_ready;
  logic local_processor_reset_n;
  logic local_processor_halt_n;
  logic local_processor_release_blocked;

  hard_drivin_sound_local_reset_interlock dut (
    .initialize_i                       (initialize),
    .board_reset_n_i                    (board_reset_n),
    .local_processor_halt_n_i           (local_processor_halt_n_input),
    .use_internal_local_ram_i           (use_internal_local_ram),
    .local_ram_storage_ready_i          (local_ram_storage_ready),
    .local_processor_reset_n_o          (local_processor_reset_n),
    .local_processor_halt_n_o           (local_processor_halt_n),
    .local_processor_release_blocked_o  (
      local_processor_release_blocked
    )
  );

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $error(
        "FAIL %s init=%0b reset_n=%0b halt_n=%0b internal=%0b ready=%0b",
        message, initialize, board_reset_n, local_processor_halt_n_input,
        use_internal_local_ram, local_ram_storage_ready
      );
      $fatal(1);
    end
  endtask

  initial begin
    // Exhaust every policy input. Storage readiness is ignored only while
    // external storage remains selected.
    for (int unsigned state = 0; state < 32; state++) begin
      logic expected_release;
      logic expected_halt_release;
      logic expected_blocked;
      {initialize, board_reset_n, local_processor_halt_n_input,
       use_internal_local_ram, local_ram_storage_ready} = state[4:0];
      #1;
      expected_release =
        !initialize && board_reset_n &&
        (!use_internal_local_ram || local_ram_storage_ready);
      expected_halt_release =
        !initialize && local_processor_halt_n_input &&
        (!use_internal_local_ram || local_ram_storage_ready);
      expected_blocked =
        board_reset_n && local_processor_halt_n_input &&
        (initialize ||
         (use_internal_local_ram && !local_ram_storage_ready));
      require(local_processor_reset_n == expected_release,
              "exact reset-release equation");
      require(local_processor_halt_n == expected_halt_release,
              "exact halt-release equation");
      require(local_processor_release_blocked == expected_blocked,
              "exact blocked diagnostic equation");
    end

    $display("PASS tb_hard_drivin_sound_local_reset_interlock");
    $finish;
  end
endmodule

`default_nettype wire
