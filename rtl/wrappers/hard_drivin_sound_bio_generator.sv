`default_nettype none

// Logical A044427 Rev-A /320BIO divider and CLKOUT resampling path.
// Both physical clocks are represented as enables in one FPGA clock domain.
// Their enables must not coincide because the production clocks are
// independent and coincident-edge setup/hold behavior is not documented.
module hard_drivin_sound_bio_generator (
  input  logic       clk_i,
  input  logic       initialize_i,
  input  logic       board_reset_n_i,
  input  logic       one_mhz_rise_i,
  input  logic       clkout_rise_i,
  input  logic [7:0] counter_seed_i,
  input  logic       counter_seed_valid_i,
  output logic [7:0] divider_state_o,
  output logic       divider_phase_valid_o,
  output logic       raw_320bio_n_o,
  output logic       raw_320bio_valid_o,
  output logic       bio_n_o,
  output logic       bio_valid_o
);
  localparam logic [7:0] DIVIDER_PRELOAD = 8'hce;

  logic terminal_count;
  logic previous_one_mhz_rise;
  logic previous_terminal_count;
  logic previous_board_reset_n;
  logic previous_clkout_rise;
  logic previous_raw_320bio_n;
  logic previous_raw_320bio_valid;

  assign terminal_count = (divider_state_o == 8'hff);

  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      // The physical LS161 pair has no board-reset connection. A caller-
      // supplied seed gives deterministic FPGA storage without claiming a
      // physical phase; validity becomes true after the first observed reload.
      divider_state_o       <= counter_seed_i;
      divider_phase_valid_o <= counter_seed_valid_i;
      raw_320bio_n_o         <= 1'b1;
      raw_320bio_valid_o     <= !board_reset_n_i;
      bio_n_o                <= 1'b1;
      bio_valid_o            <= 1'b0;
    end else begin
      // /RESET is the asynchronous clear of the source LS74 only. The
      // synchronous FPGA boundary samples that physical assertion on clk_i;
      // the divider continues to run whenever its 1 MHz enable arrives.
      if (!board_reset_n_i) begin
        raw_320bio_n_o     <= 1'b1;
        raw_320bio_valid_o <= 1'b1;
      end else if (one_mhz_rise_i) begin
        raw_320bio_n_o <= !terminal_count;
        raw_320bio_valid_o <=
          divider_phase_valid_o || terminal_count;
      end

      if (one_mhz_rise_i) begin
        if (terminal_count) begin
          divider_state_o       <= DIVIDER_PRELOAD;
          divider_phase_valid_o <= 1'b1;
        end else begin
          divider_state_o <= divider_state_o + 8'h01;
        end
      end

      // LS74 70S samples /320BIO on the positive edge of TMS32010 CLKOUT.
      // No board-reset connection is drawn on this second flip-flop.
      if (clkout_rise_i) begin
        bio_n_o     <= raw_320bio_n_o;
        bio_valid_o <= raw_320bio_valid_o;
      end
    end
  end

  // History-based retained checks keep the enable contract and the two
  // independently clocked state transitions visible to synthesis/formal tools.
  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      previous_one_mhz_rise      <= 1'b0;
      previous_terminal_count    <= 1'b0;
      previous_board_reset_n     <= board_reset_n_i;
      previous_clkout_rise       <= 1'b0;
      previous_raw_320bio_n      <= 1'b1;
      previous_raw_320bio_valid  <= 1'b0;
    end else begin
      assert (!(one_mhz_rise_i && clkout_rise_i));
      if (previous_one_mhz_rise) begin
        if (previous_terminal_count) begin
          assert (divider_state_o == DIVIDER_PRELOAD);
          assert (divider_phase_valid_o);
        end
      end
      if (!previous_board_reset_n) begin
        assert (raw_320bio_n_o);
        assert (raw_320bio_valid_o);
      end
      if (previous_clkout_rise) begin
        assert (bio_n_o == previous_raw_320bio_n);
        assert (bio_valid_o == previous_raw_320bio_valid);
      end

      previous_one_mhz_rise      <= one_mhz_rise_i;
      previous_terminal_count    <= terminal_count;
      previous_board_reset_n     <= board_reset_n_i;
      previous_clkout_rise       <= clkout_rise_i;
      previous_raw_320bio_n      <= raw_320bio_n_o;
      previous_raw_320bio_valid  <= raw_320bio_valid_o;
    end
  end
endmodule

`default_nettype wire
