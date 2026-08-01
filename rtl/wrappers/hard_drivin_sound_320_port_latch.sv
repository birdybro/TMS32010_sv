`default_nettype none

// Digital boundary for A044427 LS374 50L. A completed TMS output-port-3
// transaction clocks TD7:TD0 into the latch. Host /320PORT enables those
// stored bits onto D15:D8; D7:D0 have no source in this physical target.
module hard_drivin_sound_320_port_latch (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic [2:0]  io_port_i,
  input  logic        io_write_i,
  /* verilator lint_off UNUSEDSIGNAL */
  input  logic [15:0] io_write_data_i,
  /* verilator lint_on UNUSEDSIGNAL */
  input  logic        io_commit_i,
  output logic [7:0]  latch_data_o,
  output logic        latch_data_valid_o,
  output logic        latch_commit_o,
  output logic [15:0] host_read_data_o,
  output logic [15:0] host_driven_mask_o,
  output logic [15:0] host_valid_mask_o
);
  logic cport_commit;

  assign cport_commit =
    io_commit_i && io_write_i && (io_port_i == 3'd3);

  // The low-byte zero is only a deterministic interface filler. The driven
  // and valid masks prevent it from being mistaken for physical board data.
  assign host_read_data_o   = {latch_data_o, 8'h00};
  assign host_driven_mask_o = 16'hff00;
  assign host_valid_mask_o  =
    latch_data_valid_o ? 16'hff00 : 16'h0000;

  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      // LS374 50L has no drawn clear. FPGA initialization therefore makes
      // the storage deterministic while leaving its physical validity false.
      latch_data_o       <= 8'h00;
      latch_data_valid_o <= 1'b0;
      latch_commit_o     <= 1'b0;
    end else begin
      latch_commit_o <= 1'b0;
      if (cport_commit) begin
        latch_data_o       <= io_write_data_i[7:0];
        latch_data_valid_o <= 1'b1;
        latch_commit_o     <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (!initialize_i) begin
      assert (host_driven_mask_o == 16'hff00);
      assert ((host_valid_mask_o & ~host_driven_mask_o) == 16'h0000);
      assert (host_valid_mask_o ==
              (latch_data_valid_o ? 16'hff00 : 16'h0000));
      assert (!latch_commit_o || latch_data_valid_o);
      assert (!cport_commit || (io_port_i == 3'd3));
    end
  end
endmodule

`default_nettype wire
