`default_nettype none

module tb_hard_drivin_sound_local_reset_source;
  localparam int unsigned HOLD_TICKS = 6;
  localparam int unsigned INHIBIT_TICKS = 2;
  localparam int unsigned HOLD_WIDTH = $clog2(HOLD_TICKS + 1);

  logic clk;
  logic initialize;
  logic hold_tick;
  logic master_reset_n;
  logic sound_reset_access_n;
  logic sound_reset_test_n;
  logic board_reset_n;
  logic board_halt_n;
  logic monostable_hold_active;
  logic monostable_trigger_event;
  logic monostable_trigger_ignored;

  hard_drivin_sound_local_reset_source #(
    .MONOSTABLE_HOLD_TICKS               (HOLD_TICKS),
    .MONOSTABLE_RETRIGGER_INHIBIT_TICKS  (INHIBIT_TICKS)
  ) dut (
    .clk_i                       (clk),
    .initialize_i                (initialize),
    .hold_tick_i                 (hold_tick),
    .master_reset_n_i            (master_reset_n),
    .sound_reset_access_n_i      (sound_reset_access_n),
    .sound_reset_test_n_i        (sound_reset_test_n),
    .board_reset_n_o             (board_reset_n),
    .board_halt_n_o              (board_halt_n),
    .monostable_hold_active_o    (monostable_hold_active),
    .monostable_trigger_event_o  (monostable_trigger_event),
    .monostable_trigger_ignored_o (monostable_trigger_ignored)
  );

  always #5 clk = !clk;

  task automatic step(input logic tick);
    hold_tick = tick;
    @(posedge clk);
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $error(
        "FAIL %s init=%0b tick=%0b mres_n=%0b sres_n=%0b test_n=%0b reset_n=%0b halt_n=%0b hold=%0b trigger=%0b ignored=%0b remaining=%0d inhibit=%0d",
        message, initialize, hold_tick, master_reset_n, sound_reset_access_n,
        sound_reset_test_n, board_reset_n, board_halt_n,
        monostable_hold_active, monostable_trigger_event,
        monostable_trigger_ignored, dut.hold_remaining_q,
        dut.inhibit_remaining_q
      );
      $fatal(1);
    end
  endtask

  task automatic expect_paired_assertion(input string message);
    require(!board_reset_n && !board_halt_n, message);
  endtask

  initial begin
    clk = 1'b0;
    initialize = 1'b1;
    hold_tick = 1'b0;
    master_reset_n = 1'b1;
    sound_reset_access_n = 1'b1;
    sound_reset_test_n = 1'b1;

    step(1'b0);
    expect_paired_assertion("initialization seeds a deterministic hold");
    require(dut.hold_remaining_q == HOLD_WIDTH'(HOLD_TICKS),
            "initial hold uses the configured tick count");
    require(dut.inhibit_remaining_q == 2'(INHIBIT_TICKS),
            "initial hold seeds the documented retrigger inhibit interval");

    initialize = 1'b0;
    for (int unsigned tick_index = 0; tick_index < HOLD_TICKS - 1;
         tick_index++) begin
      step(1'b1);
      expect_paired_assertion("hold remains active before final tick");
    end
    step(1'b1);
    require(board_reset_n && board_halt_n && !monostable_hold_active,
            "paired outputs release after exactly the configured ticks");

    sound_reset_test_n = 1'b0;
    #1;
    expect_paired_assertion("SOUND.RESET directly asserts both outputs");
    sound_reset_test_n = 1'b1;
    #1;
    require(board_reset_n && board_halt_n,
            "SOUND.RESET releases without modifying the expired timer");

    master_reset_n = 1'b0;
    step(1'b0);
    require(monostable_trigger_event && monostable_hold_active,
            "falling /MRES input triggers the one-shot");
    expect_paired_assertion("/MRES trigger asserts paired outputs");

    master_reset_n = 1'b1;
    step(1'b0);
    master_reset_n = 1'b0;
    step(1'b0);
    require(!monostable_trigger_event && monostable_trigger_ignored &&
            dut.hold_remaining_q == HOLD_WIDTH'(HOLD_TICKS),
            "a falling edge inside the inhibit interval is reported and ignored");

    master_reset_n = 1'b1;
    step(1'b1);
    step(1'b1);
    require(dut.inhibit_remaining_q == 0 &&
            dut.hold_remaining_q == HOLD_WIDTH'(HOLD_TICKS - 2),
            "enabled ticks consume both hold and retrigger inhibit intervals");

    master_reset_n = 1'b0;
    step(1'b1);
    require(monostable_trigger_event && !monostable_trigger_ignored &&
            dut.hold_remaining_q == HOLD_WIDTH'(HOLD_TICKS),
            "a falling edge after the inhibit interval retriggers before decrement");

    master_reset_n = 1'b1;
    step(1'b1);
    step(1'b1);
    sound_reset_access_n = 1'b0;
    step(1'b1);
    require(monostable_trigger_event &&
            dut.hold_remaining_q == HOLD_WIDTH'(HOLD_TICKS),
            "falling decoded /SRES input uses the same LS08/LS123 path");

    sound_reset_access_n = 1'b1;
    for (int unsigned tick_index = 0; tick_index < HOLD_TICKS;
         tick_index++) begin
      step(1'b1);
    end
    require(board_reset_n && board_halt_n && !monostable_hold_active,
            "retriggered /SRES hold eventually releases both outputs");

    $display("PASS tb_hard_drivin_sound_local_reset_source");
    $finish;
  end
endmodule

`default_nettype wire
