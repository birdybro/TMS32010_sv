`default_nettype none

// One-entry boundary between the externally fetched word and the instruction
// currently owned by the execute pipeline. The surrounding sequencer
// classifies operand/dummy program reads with fetched_valid_i=0 and supplies
// redirects through flush_i. This block intentionally does not decode
// instructions or invent unresolved external bus sequences.
module tms32010_fetch_execute (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        reset_i,
  input  logic        cycle_boundary_i,

  input  logic        fetched_valid_i,
  input  logic [11:0] fetched_address_i,
  input  logic [15:0] fetched_word_i,

  input  logic        execute_complete_i,
  input  logic        flush_i,

  output logic        execute_valid_o,
  output logic [11:0] execute_address_o,
  output logic [15:0] execute_word_o
);
  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      execute_valid_o   <= 1'b0;
      execute_address_o <= 12'h000;
      execute_word_o    <= 16'h0000;
    end else if (cycle_boundary_i) begin
      if (reset_i || flush_i) begin
        execute_valid_o   <= 1'b0;
        execute_address_o <= 12'h000;
        execute_word_o    <= 16'h0000;
      end else if (!execute_valid_o || execute_complete_i) begin
        execute_valid_o <= fetched_valid_i;
        if (fetched_valid_i) begin
          execute_address_o <= fetched_address_i;
          execute_word_o    <= fetched_word_i;
        end else begin
          execute_address_o <= 12'h000;
          execute_word_o    <= 16'h0000;
        end
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (
      !initialize_i &&
      cycle_boundary_i &&
      !reset_i
    ) begin
      assert (!(flush_i && fetched_valid_i));
      assert (!(
        execute_valid_o &&
        !execute_complete_i &&
        fetched_valid_i
      ));
    end
  end
endmodule

`default_nettype wire
