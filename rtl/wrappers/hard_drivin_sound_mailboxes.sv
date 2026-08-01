`default_nettype none

// Same-clock FPGA boundary for the two A044427 Rev-A interprocessor word
// latches and their LS74 pending flags. The board uses asynchronous preset to
// set each flag and the trailing edge of the opposite-side read strobe to
// clock grounded D and clear it. Coincident set/clear conditions are not
// assigned a priority: the deterministic carrier is zero and validity drops.
module hard_drivin_sound_mailboxes (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        board_reset_n_i,

  input  logic        main_write_commit_i,
  input  logic [15:0] main_write_data_i,
  input  logic        sound_read_commit_i,
  output logic [15:0] main_to_sound_data_o,
  output logic        main_to_sound_data_valid_o,
  output logic        main_flag_o,
  output logic        main_flag_valid_o,
  output logic        main_flag_conflict_o,

  input  logic        sound_write_commit_i,
  input  logic [15:0] sound_write_data_i,
  input  logic        main_read_commit_i,
  output logic [15:0] sound_to_main_data_o,
  output logic        sound_to_main_data_valid_o,
  output logic        sound_flag_o,
  output logic        sound_flag_valid_o,
  output logic        sound_flag_conflict_o
);
  logic        history_valid;
  logic        previous_board_reset_n;
  logic        previous_main_write_commit;
  logic [15:0] previous_main_write_data;
  logic        previous_sound_read_commit;
  logic        previous_sound_write_commit;
  logic [15:0] previous_sound_write_data;
  logic        previous_main_read_commit;
  logic [15:0] previous_main_to_sound_data;
  logic        previous_main_to_sound_data_valid;
  logic [15:0] previous_sound_to_main_data;
  logic        previous_sound_to_main_data_valid;
  logic        previous_main_flag;
  logic        previous_main_flag_valid;
  logic        previous_sound_flag;
  logic        previous_sound_flag_valid;

  function automatic logic next_flag_value(
    input logic old_value,
    input logic reset_n,
    input logic set_request,
    input logic clear_request
  );
    begin
      if (!reset_n || (set_request && clear_request)) begin
        next_flag_value = 1'b0;
      end else if (set_request) begin
        next_flag_value = 1'b1;
      end else if (clear_request) begin
        next_flag_value = 1'b0;
      end else begin
        next_flag_value = old_value;
      end
    end
  endfunction

  function automatic logic next_flag_valid(
    input logic old_valid,
    input logic reset_n,
    input logic set_request,
    input logic clear_request
  );
    begin
      if (!reset_n) begin
        // LS74 preset and clear asserted together is an invalid condition.
        next_flag_valid = !set_request;
      end else if (set_request && clear_request) begin
        next_flag_valid = 1'b0;
      end else if (set_request || clear_request) begin
        next_flag_valid = 1'b1;
      end else begin
        next_flag_valid = old_valid;
      end
    end
  endfunction

  assign main_flag_conflict_o =
    !initialize_i && main_write_commit_i &&
    (!board_reset_n_i || sound_read_commit_i);
  assign sound_flag_conflict_o =
    !initialize_i && sound_write_commit_i &&
    (!board_reset_n_i || main_read_commit_i);

  // Neither pair of LS374 data latches has a board-reset connection. Their
  // data can therefore change on a completed write even while reset is low.
  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      main_to_sound_data_o       <= 16'h0000;
      main_to_sound_data_valid_o <= 1'b0;
      sound_to_main_data_o       <= 16'h0000;
      sound_to_main_data_valid_o <= 1'b0;
    end else begin
      if (main_write_commit_i) begin
        main_to_sound_data_o       <= main_write_data_i;
        main_to_sound_data_valid_o <= 1'b1;
      end
      if (sound_write_commit_i) begin
        sound_to_main_data_o       <= sound_write_data_i;
        sound_to_main_data_valid_o <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      // Deterministic FPGA values are not physical power-up evidence.
      main_flag_o        <= 1'b0;
      main_flag_valid_o  <= 1'b0;
      sound_flag_o       <= 1'b0;
      sound_flag_valid_o <= 1'b0;
    end else begin
      main_flag_o <= next_flag_value(
        main_flag_o,
        board_reset_n_i,
        main_write_commit_i,
        sound_read_commit_i
      );
      main_flag_valid_o <= next_flag_valid(
        main_flag_valid_o,
        board_reset_n_i,
        main_write_commit_i,
        sound_read_commit_i
      );
      sound_flag_o <= next_flag_value(
        sound_flag_o,
        board_reset_n_i,
        sound_write_commit_i,
        main_read_commit_i
      );
      sound_flag_valid_o <= next_flag_valid(
        sound_flag_valid_o,
        board_reset_n_i,
        sound_write_commit_i,
        main_read_commit_i
      );
    end
  end

  // Retained checks compare each completed transition with the previous
  // request/state tuple. They cover data-latch reset independence, exact
  // whole-word capture, flag set/clear behavior, and explicit invalidity.
  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      history_valid                    <= 1'b0;
      previous_board_reset_n           <= board_reset_n_i;
      previous_main_write_commit       <= 1'b0;
      previous_main_write_data         <= 16'h0000;
      previous_sound_read_commit       <= 1'b0;
      previous_sound_write_commit      <= 1'b0;
      previous_sound_write_data        <= 16'h0000;
      previous_main_read_commit        <= 1'b0;
      previous_main_to_sound_data      <= 16'h0000;
      previous_main_to_sound_data_valid <= 1'b0;
      previous_sound_to_main_data      <= 16'h0000;
      previous_sound_to_main_data_valid <= 1'b0;
      previous_main_flag               <= 1'b0;
      previous_main_flag_valid         <= 1'b0;
      previous_sound_flag              <= 1'b0;
      previous_sound_flag_valid        <= 1'b0;
    end else begin
      if (history_valid) begin
        assert (
          main_to_sound_data_o ==
          (previous_main_write_commit ? previous_main_write_data :
                                        previous_main_to_sound_data)
        );
        assert (
          main_to_sound_data_valid_o ==
          (previous_main_write_commit ? 1'b1 :
                                        previous_main_to_sound_data_valid)
        );
        assert (
          sound_to_main_data_o ==
          (previous_sound_write_commit ? previous_sound_write_data :
                                         previous_sound_to_main_data)
        );
        assert (
          sound_to_main_data_valid_o ==
          (previous_sound_write_commit ? 1'b1 :
                                         previous_sound_to_main_data_valid)
        );
        assert (
          main_flag_o == next_flag_value(
            previous_main_flag,
            previous_board_reset_n,
            previous_main_write_commit,
            previous_sound_read_commit
          )
        );
        assert (
          main_flag_valid_o == next_flag_valid(
            previous_main_flag_valid,
            previous_board_reset_n,
            previous_main_write_commit,
            previous_sound_read_commit
          )
        );
        assert (
          sound_flag_o == next_flag_value(
            previous_sound_flag,
            previous_board_reset_n,
            previous_sound_write_commit,
            previous_main_read_commit
          )
        );
        assert (
          sound_flag_valid_o == next_flag_valid(
            previous_sound_flag_valid,
            previous_board_reset_n,
            previous_sound_write_commit,
            previous_main_read_commit
          )
        );
      end

      assert (main_flag_valid_o || !main_flag_o);
      assert (sound_flag_valid_o || !sound_flag_o);

      history_valid                     <= 1'b1;
      previous_board_reset_n            <= board_reset_n_i;
      previous_main_write_commit        <= main_write_commit_i;
      previous_main_write_data          <= main_write_data_i;
      previous_sound_read_commit        <= sound_read_commit_i;
      previous_sound_write_commit       <= sound_write_commit_i;
      previous_sound_write_data         <= sound_write_data_i;
      previous_main_read_commit         <= main_read_commit_i;
      previous_main_to_sound_data       <= main_to_sound_data_o;
      previous_main_to_sound_data_valid <= main_to_sound_data_valid_o;
      previous_sound_to_main_data       <= sound_to_main_data_o;
      previous_sound_to_main_data_valid <= sound_to_main_data_valid_o;
      previous_main_flag                <= main_flag_o;
      previous_main_flag_valid          <= main_flag_valid_o;
      previous_sound_flag               <= sound_flag_o;
      previous_sound_flag_valid         <= sound_flag_valid_o;
    end
  end
endmodule

`default_nettype wire
