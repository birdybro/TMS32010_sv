`default_nettype none

// Digital boundary for A044427's port-0 /DACL path. The physical LS374s
// capture TD15:TD4 without complementing the MSB. Analog conversion and any
// signed-sample interpretation remain outside this module.
module hard_drivin_sound_dac_latch (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic [2:0]  io_port_i,
  input  logic        io_write_i,
  // TD3:TD0 are intentionally present at the processor boundary but have no
  // connection to the twelve physical DAC latch inputs on A044427 sheet 7.
  /* verilator lint_off UNUSEDSIGNAL */
  input  logic [15:0] io_write_data_i,
  /* verilator lint_on UNUSEDSIGNAL */
  input  logic        io_commit_i,
  output logic [11:0] dac_code_o,
  output logic        dac_code_valid_o,
  output logic        dac_commit_o
);
  logic dac_write_commit;

  assign dac_write_commit =
    io_commit_i && io_write_i && (io_port_i == 3'd0);

  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      // Deterministic FPGA validity is not a physical board-reset claim. The
      // drawn LS374 path has no clear and processor reset does not reach it.
      dac_code_o       <= 12'h000;
      dac_code_valid_o <= 1'b0;
      dac_commit_o     <= 1'b0;
    end else begin
      dac_commit_o <= 1'b0;
      if (dac_write_commit) begin
        dac_code_o       <= io_write_data_i[15:4];
        dac_code_valid_o <= 1'b1;
        dac_commit_o     <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (!initialize_i) begin
      assert (!dac_commit_o || dac_code_valid_o);
      assert (!dac_write_commit || (io_port_i == 3'd0));
    end
  end
endmodule

`default_nettype wire
