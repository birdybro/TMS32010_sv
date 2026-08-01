`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_320_port_latch;
  logic        clk;
  logic        initialize;
  logic [2:0]  io_port;
  logic        io_write;
  logic [15:0] io_write_data;
  logic        io_commit;
  logic [7:0]  latch_data;
  logic        latch_data_valid;
  logic        latch_commit;
  logic [15:0] host_read_data;
  logic [15:0] host_driven_mask;
  logic [15:0] host_valid_mask;

  hard_drivin_sound_320_port_latch dut (
    .clk_i               (clk),
    .initialize_i        (initialize),
    .io_port_i           (io_port),
    .io_write_i          (io_write),
    .io_write_data_i     (io_write_data),
    .io_commit_i         (io_commit),
    .latch_data_o        (latch_data),
    .latch_data_valid_o  (latch_data_valid),
    .latch_commit_o      (latch_commit),
    .host_read_data_o    (host_read_data),
    .host_driven_mask_o  (host_driven_mask),
    .host_valid_mask_o   (host_valid_mask)
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

  task automatic commit_word(input logic [15:0] value);
    io_port       = 3'd3;
    io_write      = 1'b1;
    io_write_data = value;
    io_commit     = 1'b1;
    tick();
    require(
      latch_commit && latch_data_valid &&
      latch_data == value[7:0] &&
      host_read_data == {value[7:0], 8'h00} &&
      host_driven_mask == 16'hff00 &&
      host_valid_mask == 16'hff00,
      "port-three commit captures TD7:TD0 onto host D15:D8 only"
    );
    io_commit = 1'b0;
    tick();
    require(
      !latch_commit && latch_data == value[7:0] &&
      host_read_data == {value[7:0], 8'h00},
      "LS374 state persists after its one-clock commit pulse"
    );
  endtask

  initial begin
    initialize = 1'b1;
    io_port = 3'd0;
    io_write = 1'b0;
    io_write_data = 16'h0000;
    io_commit = 1'b0;
    tick();
    initialize = 1'b0;
    tick();

    require(
      !latch_data_valid && !latch_commit &&
      host_driven_mask == 16'hff00 && host_valid_mask == 16'h0000,
      "FPGA initialization does not claim LS374 power-up data"
    );

    for (int unsigned word = 0; word < 65536; word++) begin
      commit_word(word[15:0]);
    end

    commit_word(16'ha55a);
    require(latch_data == 8'h5a && host_read_data == 16'h5a00,
            "the upper TMS byte is physically ignored by LS374 50L");

    for (int unsigned port = 0; port < 8; port++) begin
      if (port != 3) begin
        io_port = port[2:0];
        io_write_data = {8'hc3, port[7:0]};
        io_commit = 1'b1;
        tick();
        require(!latch_commit && latch_data == 8'h5a,
                "other output ports cannot alter the /CPORT latch");
      end
    end

    io_port = 3'd3;
    io_write = 1'b0;
    io_write_data = 16'h003c;
    io_commit = 1'b1;
    tick();
    require(!latch_commit && latch_data == 8'h5a,
            "an input-side commit cannot clock the output latch");

    io_write = 1'b1;
    io_commit = 1'b0;
    io_write_data = 16'h00c3;
    tick();
    require(!latch_commit && latch_data == 8'h5a,
            "write data without a physical completion has no effect");

    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    tick();
    require(
      !latch_data_valid && host_valid_mask == 16'h0000 &&
      host_driven_mask == 16'hff00,
      "deterministic reinitialization restores explicit invalidity"
    );

    $display("PASS tb_hard_drivin_sound_320_port_latch");
    $finish;
  end
endmodule

`default_nettype wire
