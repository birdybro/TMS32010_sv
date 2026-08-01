`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_bio_generator;
  logic       clk;
  logic       initialize;
  logic       board_reset_n;
  logic       one_mhz_rise;
  logic       clkout_rise;
  logic [7:0] counter_seed;
  logic       counter_seed_valid;
  logic [7:0] divider_state;
  logic       divider_phase_valid;
  logic       raw_320bio_n;
  logic       raw_320bio_valid;
  logic       bio_n;
  logic       bio_valid;

  hard_drivin_sound_bio_generator dut (
    .clk_i                     (clk),
    .initialize_i              (initialize),
    .board_reset_n_i           (board_reset_n),
    .one_mhz_rise_i            (one_mhz_rise),
    .clkout_rise_i             (clkout_rise),
    .counter_seed_i            (counter_seed),
    .counter_seed_valid_i      (counter_seed_valid),
    .divider_state_o           (divider_state),
    .divider_phase_valid_o     (divider_phase_valid),
    .raw_320bio_n_o            (raw_320bio_n),
    .raw_320bio_valid_o        (raw_320bio_valid),
    .bio_n_o                   (bio_n),
    .bio_valid_o               (bio_valid)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    @(posedge clk);
    #1;
  endtask

  task automatic source_edge;
    one_mhz_rise = 1'b1;
    tick();
    one_mhz_rise = 1'b0;
  endtask

  task automatic sample_edge;
    clkout_rise = 1'b1;
    tick();
    clkout_rise = 1'b0;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  task automatic initialize_from(
    input logic [7:0] seed,
    input logic       seed_valid,
    input logic       reset_n
  );
    counter_seed = seed;
    counter_seed_valid = seed_valid;
    board_reset_n = reset_n;
    one_mhz_rise = 1'b0;
    clkout_rise = 1'b0;
    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    tick();
  endtask

  initial begin
    // Qualified phase: CE through FF is exactly fifty 1 MHz periods, and the
    // source active-low pulse occupies only the reload-to-CE period.
    initialize_from(8'hce, 1'b1, 1'b1);
    require(divider_state == 8'hce && divider_phase_valid,
            "valid caller seed establishes the documented CE phase");
    for (int unsigned offset = 0; offset < 50; offset++) begin
      require(divider_state == (8'hce + offset[7:0]),
              "divider advances through the complete CE-to-FF sequence");
      source_edge();
      if (offset == 49) begin
        require(divider_state == 8'hce && !raw_320bio_n && raw_320bio_valid,
                "terminal FF edge reloads CE and asserts /320BIO once");
      end else begin
        require(raw_320bio_n && raw_320bio_valid,
                "nonterminal divider edges keep /320BIO inactive");
      end
    end
    source_edge();
    require(divider_state == 8'hcf && raw_320bio_n,
            "the following source edge ends the one-microsecond pulse");

    // Five CLKOUT samples per source period preserve a five-CLKOUT low pulse.
    initialize_from(8'hff, 1'b1, 1'b1);
    source_edge();
    require(!raw_320bio_n && bio_n,
            "source assertion does not bypass the CLKOUT resampler");
    for (int unsigned sample = 0; sample < 5; sample++) begin
      sample_edge();
      require(!bio_n && bio_valid,
              "resampled BIO remains low for each of five CLKOUT periods");
    end
    source_edge();
    require(raw_320bio_n && !bio_n,
            "source release also waits for a CLKOUT sample");
    sample_edge();
    require(bio_n && bio_valid,
            "first following CLKOUT sample releases active-low BIO");

    // /RESET clears only the source LS74. It neither resets the divider nor
    // directly changes the separate CLKOUT resampler.
    initialize_from(8'hf8, 1'b1, 1'b1);
    source_edge();
    require(divider_state == 8'hf9,
            "test establishes a nonpreload divider state");
    board_reset_n = 1'b0;
    tick();
    require(divider_state == 8'hf9 && raw_320bio_n && !bio_valid,
            "board reset clears source pulse without touching counter/resampler");
    source_edge();
    require(divider_state == 8'hfa && raw_320bio_n,
            "divider continues counting while board reset is active");
    sample_edge();
    require(bio_n && bio_valid,
            "CLKOUT propagates the reset-qualified inactive source level");
    board_reset_n = 1'b1;
    tick();
    require(divider_state == 8'hfa,
            "board reset release does not choose a new divider phase");

    // Every explicitly invalid deterministic FPGA seed remains unqualified
    // until its first model terminal reload. This qualifies the documented
    // recurrent sequence, not alignment to an unavailable physical board.
    for (int unsigned seed = 0; seed < 256; seed++) begin
      initialize_from(seed[7:0], 1'b0, 1'b1);
      require(!divider_phase_valid && !raw_320bio_valid && !bio_valid,
              "unqualified seed does not claim physical phase or pin validity");
      for (int unsigned edge_index = 0;
           edge_index < (256 - seed);
           edge_index++) begin
        source_edge();
        if ((edge_index + 1) < (256 - seed)) begin
          require(!divider_phase_valid && !raw_320bio_valid,
                  "preterminal state from an invalid seed remains unqualified");
        end
      end
      require(divider_state == 8'hce && divider_phase_valid &&
              !raw_320bio_n && raw_320bio_valid,
              "every model seed self-qualifies at documented terminal reload");
    end
    sample_edge();
    require(!bio_n && bio_valid,
            "resampler validity follows a qualified source sample");

    $display("PASS tb_hard_drivin_sound_bio_generator");
    $finish;
  end
endmodule

`default_nettype wire
