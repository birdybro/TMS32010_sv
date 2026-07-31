`default_nettype none

// FORMAL-001 bounded harness for the standalone ADR-0002 fetch/execute
// ownership register. See formal/README.md for assumptions and excluded
// claims.
module tms32010_fetch_execute_formal (
  input logic        clk_i,
  input logic        reset_i,
  input logic        cycle_boundary_i,
  input logic        fetched_valid_i,
  input logic [11:0] fetched_address_i,
  input logic [15:0] fetched_word_i,
  input logic        execute_complete_i,
  input logic        flush_i
);
  logic        initialized = 1'b0;
  logic        past_valid = 1'b0;
  logic [2:0]  cover_stage = 3'd0;
  logic        initialize;
  logic        execute_valid;
  logic [11:0] execute_address;
  logic [15:0] execute_word;

  assign initialize = !initialized;

  tms32010_fetch_execute dut (
    .clk_i                (clk_i),
    .initialize_i         (initialize),
    .reset_i              (reset_i),
    .cycle_boundary_i     (cycle_boundary_i),
    .fetched_valid_i      (fetched_valid_i),
    .fetched_address_i    (fetched_address_i),
    .fetched_word_i       (fetched_word_i),
    .execute_complete_i   (execute_complete_i),
    .flush_i              (flush_i),
    .execute_valid_o      (execute_valid),
    .execute_address_o    (execute_address),
    .execute_word_o       (execute_word)
  );

  always_ff @(posedge clk_i) begin
    initialized <= 1'b1;
    past_valid <= 1'b1;

    // The future sequencer owns these two legality contracts. A redirect
    // cannot simultaneously present an executable fetch, and an incomplete
    // execute slot cannot be overwritten by a new executable fetch.
    if (initialized && cycle_boundary_i && !reset_i) begin
      assume (!(flush_i && fetched_valid_i));
      assume (!(
        execute_valid &&
        !execute_complete_i &&
        fetched_valid_i
      ));
    end

    if (initialized) begin
      assert (
        execute_valid ||
        (execute_address == 12'h000 && execute_word == 16'h0000)
      );
    end

    if (past_valid) begin
      if ($past(initialize)) begin
        assert (!execute_valid);
        assert (execute_address == 12'h000);
        assert (execute_word == 16'h0000);
      end else if (!$past(cycle_boundary_i)) begin
        assert ({
          execute_valid,
          execute_address,
          execute_word
        } == $past({
          execute_valid,
          execute_address,
          execute_word
        }));
      end else if ($past(reset_i || flush_i)) begin
        assert (!execute_valid);
        assert (execute_address == 12'h000);
        assert (execute_word == 16'h0000);
      end else if (
        !$past(execute_valid) ||
        $past(execute_complete_i)
      ) begin
        assert (execute_valid == $past(fetched_valid_i));
        if ($past(fetched_valid_i)) begin
          assert (execute_address == $past(fetched_address_i));
          assert (execute_word == $past(fetched_word_i));
        end else begin
          assert (execute_address == 12'h000);
          assert (execute_word == 16'h0000);
        end
      end else begin
        assert ({
          execute_valid,
          execute_address,
          execute_word
        } == $past({
          execute_valid,
          execute_address,
          execute_word
        }));
      end
    end

    // Non-vacuity path: prime an empty slot, stall it, replace the completed
    // word, flush that word, and capture a redirect target.
    if (!initialized) begin
      cover_stage <= 3'd0;
    end else begin
      case (cover_stage)
        3'd0: begin
          if (
            cycle_boundary_i &&
            !reset_i &&
            !flush_i &&
            !execute_valid &&
            fetched_valid_i
          ) begin
            cover_stage <= 3'd1;
          end
        end
        3'd1: begin
          if (!cycle_boundary_i && execute_valid) begin
            cover_stage <= 3'd2;
          end
        end
        3'd2: begin
          if (
            cycle_boundary_i &&
            !reset_i &&
            !flush_i &&
            execute_valid &&
            execute_complete_i &&
            fetched_valid_i
          ) begin
            cover_stage <= 3'd3;
          end
        end
        3'd3: begin
          if (
            cycle_boundary_i &&
            !reset_i &&
            flush_i &&
            !fetched_valid_i
          ) begin
            cover_stage <= 3'd4;
          end
        end
        3'd4: begin
          if (
            cycle_boundary_i &&
            !reset_i &&
            !flush_i &&
            !execute_valid &&
            fetched_valid_i
          ) begin
            cover_stage <= 3'd5;
          end
        end
        default: begin
          cover_stage <= cover_stage;
        end
      endcase
    end

    cover (
      initialized &&
      (cover_stage == 3'd5) &&
      execute_valid
    );
  end
endmodule

`default_nettype wire
