`default_nettype none

// Same-clock FPGA boundary for A044427 Rev-A LS259 80R. The caller supplies
// one completion pulse for a decoded /LATCHES write. Physical host address
// A3:A1 selects a latch and A4 supplies its value; 68000 data is irrelevant.
module hard_drivin_sound_host_control (
  input  logic       clk_i,
  input  logic       initialize_i,
  input  logic       board_reset_n_i,
  input  logic       latch_write_commit_i,
  input  logic [3:0] latch_address_i,
  output logic [7:0] latch_q_o,
  output logic [7:0] latch_valid_o
);
  logic       history_valid;
  logic       previous_board_reset_n;
  logic       previous_latch_write_commit;
  logic [3:0] previous_latch_address;
  logic [7:0] previous_latch_q;
  logic [7:0] previous_latch_valid;

  function automatic logic [7:0] write_selected(
    input logic [7:0] value,
    input logic [2:0] select,
    input logic       data
  );
    logic [7:0] result;
    begin
      result = value;
      result[select] = data;
      write_selected = result;
    end
  endfunction

  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      // Deterministic FPGA storage is not physical power-up evidence. A board
      // reset or a write to an individual bit establishes validity.
      latch_q_o     <= 8'h00;
      latch_valid_o <= 8'h00;
    end else if (!board_reset_n_i) begin
      // The LS259 asynchronous clear drives every Q output low. This same-
      // clock adapter samples that physical control on clk_i.
      latch_q_o     <= 8'h00;
      latch_valid_o <= 8'hff;
    end else if (latch_write_commit_i) begin
      latch_q_o[latch_address_i[2:0]] <= latch_address_i[3];
      latch_valid_o[latch_address_i[2:0]] <= 1'b1;
    end
  end

  // Retained assertions prove reset priority, address-encoded data, and
  // preservation of every unaddressed latch across a completion.
  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      history_valid                <= 1'b0;
      previous_board_reset_n       <= board_reset_n_i;
      previous_latch_write_commit  <= 1'b0;
      previous_latch_address       <= 4'h0;
      previous_latch_q             <= 8'h00;
      previous_latch_valid         <= 8'h00;
    end else begin
      if (history_valid) begin
        if (!previous_board_reset_n) begin
          assert (latch_q_o == 8'h00);
          assert (latch_valid_o == 8'hff);
        end else if (previous_latch_write_commit) begin
          assert (
            latch_q_o == write_selected(
              previous_latch_q,
              previous_latch_address[2:0],
              previous_latch_address[3]
            )
          );
          assert (
            latch_valid_o == write_selected(
              previous_latch_valid,
              previous_latch_address[2:0],
              1'b1
            )
          );
        end else begin
          assert (latch_q_o == previous_latch_q);
          assert (latch_valid_o == previous_latch_valid);
        end
      end

      history_valid                <= 1'b1;
      previous_board_reset_n       <= board_reset_n_i;
      previous_latch_write_commit  <= latch_write_commit_i;
      previous_latch_address       <= latch_address_i;
      previous_latch_q             <= latch_q_o;
      previous_latch_valid         <= latch_valid_o;
    end
  end
endmodule

`default_nettype wire
