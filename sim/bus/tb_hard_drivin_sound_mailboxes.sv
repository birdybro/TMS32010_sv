`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_mailboxes;
  logic        clk;
  logic        initialize;
  logic        board_reset_n;
  logic        main_write_commit;
  logic [15:0] main_write_data;
  logic        sound_read_commit;
  logic [15:0] main_to_sound_data;
  logic        main_to_sound_data_valid;
  logic        main_flag;
  logic        main_flag_valid;
  logic        main_flag_conflict;
  logic        sound_write_commit;
  logic [15:0] sound_write_data;
  logic        main_read_commit;
  logic [15:0] sound_to_main_data;
  logic        sound_to_main_data_valid;
  logic        sound_flag;
  logic        sound_flag_valid;
  logic        sound_flag_conflict;

  hard_drivin_sound_mailboxes dut (
    .clk_i                       (clk),
    .initialize_i                (initialize),
    .board_reset_n_i             (board_reset_n),
    .main_write_commit_i         (main_write_commit),
    .main_write_data_i           (main_write_data),
    .sound_read_commit_i         (sound_read_commit),
    .main_to_sound_data_o        (main_to_sound_data),
    .main_to_sound_data_valid_o  (main_to_sound_data_valid),
    .main_flag_o                 (main_flag),
    .main_flag_valid_o           (main_flag_valid),
    .main_flag_conflict_o        (main_flag_conflict),
    .sound_write_commit_i        (sound_write_commit),
    .sound_write_data_i          (sound_write_data),
    .main_read_commit_i          (main_read_commit),
    .sound_to_main_data_o        (sound_to_main_data),
    .sound_to_main_data_valid_o  (sound_to_main_data_valid),
    .sound_flag_o                (sound_flag),
    .sound_flag_valid_o          (sound_flag_valid),
    .sound_flag_conflict_o       (sound_flag_conflict)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    @(posedge clk);
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  task automatic idle_commits;
    main_write_commit  = 1'b0;
    sound_read_commit  = 1'b0;
    sound_write_commit = 1'b0;
    main_read_commit   = 1'b0;
  endtask

  initial begin
    initialize = 1'b1;
    board_reset_n = 1'b1;
    main_write_data = 16'h0000;
    sound_write_data = 16'h0000;
    idle_commits();
    tick();
    initialize = 1'b0;
    tick();

    require(
      !main_to_sound_data_valid && !sound_to_main_data_valid &&
      !main_flag && !main_flag_valid &&
      !sound_flag && !sound_flag_valid,
      "FPGA initialization does not qualify latch or flag power-up state"
    );

    board_reset_n = 1'b0;
    tick();
    require(
      !main_flag && main_flag_valid &&
      !sound_flag && sound_flag_valid &&
      !main_to_sound_data_valid && !sound_to_main_data_valid,
      "board reset clears and qualifies flags without qualifying data"
    );
    board_reset_n = 1'b1;

    // One pair of clocks per word exhausts both sixteen-bit latch directions.
    for (int unsigned word = 0; word < 65536; word++) begin
      main_write_data = word[15:0];
      sound_write_data = ~word[15:0];
      main_write_commit = 1'b1;
      sound_write_commit = 1'b1;
      sound_read_commit = 1'b0;
      main_read_commit = 1'b0;
      tick();
      require(
        main_to_sound_data == word[15:0] &&
        sound_to_main_data == ~word[15:0] &&
        main_to_sound_data_valid && sound_to_main_data_valid &&
        main_flag && main_flag_valid &&
        sound_flag && sound_flag_valid &&
        !main_flag_conflict && !sound_flag_conflict,
        "whole-word writes capture both latches and set both pending flags"
      );

      main_write_commit = 1'b0;
      sound_write_commit = 1'b0;
      sound_read_commit = 1'b1;
      main_read_commit = 1'b1;
      tick();
      require(
        !main_flag && main_flag_valid &&
        !sound_flag && sound_flag_valid &&
        main_to_sound_data == word[15:0] &&
        sound_to_main_data == ~word[15:0] &&
        !main_flag_conflict && !sound_flag_conflict,
        "opposite-side reads clear both flags and preserve latch data"
      );
    end

    idle_commits();
    main_write_data = 16'h1234;
    sound_write_data = 16'h5678;
    tick();
    require(
      main_to_sound_data == 16'hffff &&
      sound_to_main_data == 16'h0000 &&
      !main_flag && !sound_flag,
      "uncommitted inputs cannot alter retained mailbox state"
    );

    // Simultaneous LS74 preset and read-clock clear has no invented priority.
    main_write_data = 16'ha55a;
    main_write_commit = 1'b1;
    sound_read_commit = 1'b1;
    tick();
    require(
      main_to_sound_data == 16'ha55a && main_to_sound_data_valid &&
      !main_flag && !main_flag_valid && main_flag_conflict &&
      !sound_flag && sound_flag_valid && !sound_flag_conflict,
      "main mailbox conflict captures data but invalidates only MAINFLAG"
    );
    idle_commits();
    tick();
    require(!main_flag && !main_flag_valid && !main_flag_conflict,
            "idle time retains an unresolved MAINFLAG state");

    sound_read_commit = 1'b1;
    tick();
    require(!main_flag && main_flag_valid,
            "a later sound read requalifies and clears MAINFLAG");
    sound_read_commit = 1'b0;
    main_write_commit = 1'b1;
    tick();
    require(main_flag && main_flag_valid,
            "a later main write requalifies and sets MAINFLAG");
    main_write_commit = 1'b0;
    sound_read_commit = 1'b1;
    tick();
    require(!main_flag && main_flag_valid,
            "a later sound read requalifies and clears MAINFLAG");

    idle_commits();
    sound_write_data = 16'h5aa5;
    sound_write_commit = 1'b1;
    main_read_commit = 1'b1;
    tick();
    require(
      sound_to_main_data == 16'h5aa5 && sound_to_main_data_valid &&
      !sound_flag && !sound_flag_valid && sound_flag_conflict &&
      !main_flag && main_flag_valid && !main_flag_conflict,
      "sound mailbox conflict captures data but invalidates only SOUNDFLAG"
    );
    idle_commits();
    main_read_commit = 1'b1;
    tick();
    require(!sound_flag && sound_flag_valid,
            "a later main read requalifies and clears SOUNDFLAG");
    main_read_commit = 1'b0;
    sound_write_commit = 1'b1;
    tick();
    require(sound_flag && sound_flag_valid,
            "a later sound write requalifies and sets SOUNDFLAG");
    sound_write_commit = 1'b0;
    main_read_commit = 1'b1;
    tick();
    require(!sound_flag && sound_flag_valid,
            "a later main read requalifies and clears SOUNDFLAG");

    // Reset drives LS74 clear while writes drive preset, but the LS374 data
    // clocks remain independent of reset and still capture their words.
    idle_commits();
    board_reset_n = 1'b0;
    main_write_data = 16'hcafe;
    sound_write_data = 16'hbeef;
    main_write_commit = 1'b1;
    sound_write_commit = 1'b1;
    tick();
    require(
      main_to_sound_data == 16'hcafe &&
      sound_to_main_data == 16'hbeef &&
      !main_flag && !main_flag_valid && main_flag_conflict &&
      !sound_flag && !sound_flag_valid && sound_flag_conflict,
      "reset/write conflicts capture latch data and invalidate both flags"
    );
    idle_commits();
    tick();
    require(
      main_to_sound_data == 16'hcafe &&
      sound_to_main_data == 16'hbeef &&
      !main_flag && main_flag_valid &&
      !sound_flag && sound_flag_valid,
      "a nonconflicting reset sample clears flags and preserves data"
    );

    board_reset_n = 1'b1;
    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    tick();
    require(
      main_to_sound_data == 16'h0000 && !main_to_sound_data_valid &&
      sound_to_main_data == 16'h0000 && !sound_to_main_data_valid &&
      !main_flag && !main_flag_valid &&
      !sound_flag && !sound_flag_valid,
      "FPGA reinitialization restores deterministic invalid carriers"
    );

    $display("PASS tb_hard_drivin_sound_mailboxes");
    $finish;
  end
endmodule

`default_nettype wire
