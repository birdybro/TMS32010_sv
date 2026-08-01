`default_nettype none

// Digital reconstruction of the populated A044427 local-MC68000 reset source.
// /MRES and /SRES are ANDed into the active-low A trigger of LS123 100N;
// SOUND.RESET independently holds the final open-collector RESET/HALT outputs
// low. The caller supplies calibrated hold and retrigger-inhibit tick counts
// because the physical 47 kOhm/10 uF network is analog and board-specific.
module hard_drivin_sound_local_reset_source #(
  parameter int unsigned MONOSTABLE_HOLD_TICKS = 2,
  parameter int unsigned MONOSTABLE_RETRIGGER_INHIBIT_TICKS = 1
) (
  input  logic clk_i,
  input  logic initialize_i,
  input  logic hold_tick_i,
  input  logic master_reset_n_i,
  input  logic sound_reset_access_n_i,
  input  logic sound_reset_test_n_i,
  output logic board_reset_n_o,
  output logic board_halt_n_o,
  output logic monostable_hold_active_o,
  output logic monostable_trigger_event_o,
  output logic monostable_trigger_ignored_o
);
  localparam int unsigned HOLD_WIDTH =
    (MONOSTABLE_HOLD_TICKS > 1) ? $clog2(MONOSTABLE_HOLD_TICKS + 1) : 1;
  localparam logic [HOLD_WIDTH-1:0] HOLD_TICKS_VALUE =
    HOLD_WIDTH'(MONOSTABLE_HOLD_TICKS);
  localparam int unsigned INHIBIT_WIDTH =
    (MONOSTABLE_RETRIGGER_INHIBIT_TICKS > 1) ?
      $clog2(MONOSTABLE_RETRIGGER_INHIBIT_TICKS + 1) : 1;
  localparam logic [INHIBIT_WIDTH-1:0] INHIBIT_TICKS_VALUE =
    INHIBIT_WIDTH'(MONOSTABLE_RETRIGGER_INHIBIT_TICKS);

  logic combined_trigger_n;
  logic combined_trigger_n_q;
  logic [HOLD_WIDTH-1:0] hold_remaining_q;
  logic [INHIBIT_WIDTH-1:0] inhibit_remaining_q;
  logic monostable_trigger_event_q;
  logic monostable_trigger_ignored_q;
  logic trigger_falling;
  logic retrigger_inhibited;

  assign combined_trigger_n = master_reset_n_i && sound_reset_access_n_i;
  assign trigger_falling = combined_trigger_n_q && !combined_trigger_n;
  assign retrigger_inhibited = |inhibit_remaining_q;
  assign monostable_hold_active_o = |hold_remaining_q;
  assign monostable_trigger_event_o =
    !initialize_i && monostable_trigger_event_q;
  assign monostable_trigger_ignored_o =
    !initialize_i && monostable_trigger_ignored_q;
  assign board_reset_n_o =
    sound_reset_test_n_i && !monostable_hold_active_o;
  assign board_halt_n_o = board_reset_n_o;

  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      // Deterministic FPGA startup convention. The physical power-up edge and
      // RC tolerance remain an integration question, not an RTL timing claim.
      combined_trigger_n_q <= combined_trigger_n;
      hold_remaining_q <= HOLD_TICKS_VALUE;
      inhibit_remaining_q <= INHIBIT_TICKS_VALUE;
      monostable_trigger_event_q <= 1'b0;
      monostable_trigger_ignored_q <= 1'b0;
    end else begin
      combined_trigger_n_q <= combined_trigger_n;
      monostable_trigger_event_q <= trigger_falling && !retrigger_inhibited;
      monostable_trigger_ignored_q <= trigger_falling && retrigger_inhibited;

      if (trigger_falling && !retrigger_inhibited) begin
        hold_remaining_q <= HOLD_TICKS_VALUE;
        inhibit_remaining_q <= INHIBIT_TICKS_VALUE;
      end else if (hold_tick_i && monostable_hold_active_o) begin
        hold_remaining_q <= hold_remaining_q - HOLD_WIDTH'(1);
      end

      if (!(trigger_falling && !retrigger_inhibited) &&
          hold_tick_i && retrigger_inhibited) begin
        inhibit_remaining_q <= inhibit_remaining_q - INHIBIT_WIDTH'(1);
      end
    end
  end

  always_comb begin
    assert (MONOSTABLE_HOLD_TICKS > 0);
    assert (MONOSTABLE_RETRIGGER_INHIBIT_TICKS <=
            MONOSTABLE_HOLD_TICKS);
    assert (board_reset_n_o == board_halt_n_o);
    assert (board_reset_n_o ==
            (sound_reset_test_n_i && !monostable_hold_active_o));
    assert (!monostable_trigger_event_o || !initialize_i);
    assert (!monostable_trigger_ignored_o || !initialize_i);
    assert (!(monostable_trigger_event_o &&
              monostable_trigger_ignored_o));
  end
endmodule

`default_nettype wire
