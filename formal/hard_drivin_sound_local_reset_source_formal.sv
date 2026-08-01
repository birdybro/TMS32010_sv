`default_nettype none

module hard_drivin_sound_local_reset_source_formal;
  localparam int unsigned HOLD_TICKS = 5;
  localparam int unsigned INHIBIT_TICKS = 2;

  (* gclk *) logic clk_i;
  (* anyseq *) logic initialize_i;
  (* anyseq *) logic hold_tick_i;
  (* anyseq *) logic master_reset_n_i;
  (* anyseq *) logic sound_reset_access_n_i;
  (* anyseq *) logic sound_reset_test_n_i;

  logic board_reset_n;
  logic board_halt_n;
  logic monostable_hold_active;
  logic monostable_trigger_event;
  logic monostable_trigger_ignored;
  logic past_valid_q;
  logic saw_release_q;
  logic saw_master_trigger_q;
  logic saw_access_trigger_q;
  logic [2:0] reference_remaining_q;
  logic [1:0] reference_inhibit_q;
  logic reference_trigger_n_q;
  logic reference_trigger_event_q;
  logic reference_trigger_ignored_q;
  logic reference_combined_trigger_n;

  assign reference_combined_trigger_n =
    master_reset_n_i && sound_reset_access_n_i;

  hard_drivin_sound_local_reset_source #(
    .MONOSTABLE_HOLD_TICKS               (HOLD_TICKS),
    .MONOSTABLE_RETRIGGER_INHIBIT_TICKS  (INHIBIT_TICKS)
  ) dut (
    .clk_i                       (clk_i),
    .initialize_i                (initialize_i),
    .hold_tick_i                 (hold_tick_i),
    .master_reset_n_i            (master_reset_n_i),
    .sound_reset_access_n_i      (sound_reset_access_n_i),
    .sound_reset_test_n_i        (sound_reset_test_n_i),
    .board_reset_n_o             (board_reset_n),
    .board_halt_n_o              (board_halt_n),
    .monostable_hold_active_o    (monostable_hold_active),
    .monostable_trigger_event_o  (monostable_trigger_event),
    .monostable_trigger_ignored_o (monostable_trigger_ignored)
  );

  initial begin
    past_valid_q = 1'b0;
    saw_release_q = 1'b0;
    saw_master_trigger_q = 1'b0;
    saw_access_trigger_q = 1'b0;
    reference_remaining_q = 3'd0;
    reference_inhibit_q = 2'd0;
    reference_trigger_n_q = 1'b1;
    reference_trigger_event_q = 1'b0;
    reference_trigger_ignored_q = 1'b0;
  end

  always_ff @(posedge clk_i) begin
    past_valid_q <= 1'b1;

    if (!past_valid_q) begin
      assume (initialize_i);
    end

    assert (board_reset_n == board_halt_n);
    assert (board_reset_n ==
            (sound_reset_test_n_i && !monostable_hold_active));

    if (past_valid_q) begin
      assert (monostable_hold_active == |reference_remaining_q);
      assert (monostable_trigger_event ==
              (!initialize_i && reference_trigger_event_q));
      assert (monostable_trigger_ignored ==
              (!initialize_i && reference_trigger_ignored_q));
    end

    if (initialize_i) begin
      reference_remaining_q <= 3'(HOLD_TICKS);
      reference_inhibit_q <= 2'(INHIBIT_TICKS);
      reference_trigger_n_q <= reference_combined_trigger_n;
      reference_trigger_event_q <= 1'b0;
      reference_trigger_ignored_q <= 1'b0;
    end else begin
      reference_trigger_n_q <= reference_combined_trigger_n;
      reference_trigger_event_q <=
        reference_trigger_n_q && !reference_combined_trigger_n &&
        !(|reference_inhibit_q);
      reference_trigger_ignored_q <=
        reference_trigger_n_q && !reference_combined_trigger_n &&
        (|reference_inhibit_q);
      if (reference_trigger_n_q && !reference_combined_trigger_n &&
          !(|reference_inhibit_q)) begin
        reference_remaining_q <= 3'(HOLD_TICKS);
        reference_inhibit_q <= 2'(INHIBIT_TICKS);
      end else if (hold_tick_i && |reference_remaining_q) begin
        reference_remaining_q <= reference_remaining_q - 1'b1;
      end
      if (!(reference_trigger_n_q && !reference_combined_trigger_n &&
            !(|reference_inhibit_q)) &&
          hold_tick_i && |reference_inhibit_q) begin
        reference_inhibit_q <= reference_inhibit_q - 1'b1;
      end
    end

    if (board_reset_n && board_halt_n) begin
      saw_release_q <= 1'b1;
    end
    if (monostable_trigger_event && !master_reset_n_i &&
        sound_reset_access_n_i) begin
      saw_master_trigger_q <= 1'b1;
    end
    if (monostable_trigger_event && !sound_reset_access_n_i &&
        master_reset_n_i) begin
      saw_access_trigger_q <= 1'b1;
    end

    cover (saw_release_q && monostable_trigger_event);
    cover (saw_master_trigger_q && monostable_hold_active);
    cover (saw_access_trigger_q && monostable_hold_active);
    cover (monostable_trigger_ignored && monostable_hold_active);
    cover (!sound_reset_test_n_i && !monostable_hold_active &&
           !board_reset_n && !board_halt_n);
  end
endmodule

`default_nettype wire
