`default_nettype none

// Digital A044427 Rev-A boundary for the two LS74 halves at location 100H.
// Port 4 captures TD0 onto Q and exposes complementary /Q as the raw MUTE net.
// Port 5 asynchronously presets the active-high 320IRQ state; the future
// 68000 bridge supplies the separate /IRQCLR completion callback.
module hard_drivin_sound_output_control (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        dsp_reset_n_i,
  input  logic [2:0]  io_port_i,
  input  logic        io_write_i,
  // Only TD0 reaches the port-4 flip-flop; port 5 is data-independent.
  /* verilator lint_off UNUSEDSIGNAL */
  input  logic [15:0] io_write_data_i,
  /* verilator lint_on UNUSEDSIGNAL */
  input  logic        io_commit_i,
  input  logic        host_irq_clear_commit_i,
  output logic        mute_net_o,
  output logic        mute_commit_o,
  output logic        irq_68000_o
);
  logic mute_write_commit;
  logic irq_set_request;
  logic previous_mute_write_commit;
  logic previous_mute_data;
  logic previous_irq_set_request;
  logic previous_host_irq_clear_commit;

  assign mute_write_commit =
    io_commit_i && io_write_i && (io_port_i == 3'd4);
  assign irq_set_request =
    io_write_i && (io_port_i == 3'd5);

  always_ff @(posedge clk_i) begin
    if (initialize_i || !dsp_reset_n_i) begin
      // /320RES clears both physical Q outputs. MUTE is the complementary
      // output of the port-4 half, so its reset net level is high.
      mute_net_o     <= 1'b1;
      mute_commit_o  <= 1'b0;
      irq_68000_o    <= 1'b0;
    end else begin
      mute_commit_o <= 1'b0;
      if (mute_write_commit) begin
        mute_net_o    <= !io_write_data_i[0];
        mute_commit_o <= 1'b1;
      end

      // Active-low /68IRQ is the asynchronous preset. It therefore wins over
      // a simultaneous normal /IRQCLR clock. The host clear clocks grounded D.
      if (irq_set_request) begin
        irq_68000_o <= 1'b1;
      end else if (host_irq_clear_commit_i) begin
        irq_68000_o <= 1'b0;
      end
    end
  end

  // One-cycle history makes the retained checks refer to the state committed
  // at the preceding edge without relying on simulation-only $past behavior.
  always_ff @(posedge clk_i) begin
    if (initialize_i || !dsp_reset_n_i) begin
      previous_mute_write_commit  <= 1'b0;
      previous_mute_data          <= 1'b0;
      previous_irq_set_request    <= 1'b0;
      previous_host_irq_clear_commit <= 1'b0;
    end else begin
      if (previous_mute_write_commit) begin
        assert (mute_commit_o);
        assert (mute_net_o == !previous_mute_data);
      end
      if (previous_irq_set_request) begin
        assert (irq_68000_o);
      end else if (previous_host_irq_clear_commit) begin
        assert (!irq_68000_o);
      end

      previous_mute_write_commit  <= mute_write_commit;
      previous_mute_data          <= io_write_data_i[0];
      previous_irq_set_request    <= irq_set_request;
      previous_host_irq_clear_commit <= host_irq_clear_commit_i;
    end
  end
endmodule

`default_nettype wire
