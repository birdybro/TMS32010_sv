`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_dac_latch;
  logic        clk;
  logic        initialize;
  logic [2:0]  io_port;
  logic        io_write;
  logic [15:0] io_write_data;
  logic        io_commit;
  logic [11:0] dac_code;
  logic        dac_code_valid;
  logic        dac_commit;

  hard_drivin_sound_dac_latch dut (
    .clk_i            (clk),
    .initialize_i     (initialize),
    .io_port_i        (io_port),
    .io_write_i       (io_write),
    .io_write_data_i  (io_write_data),
    .io_commit_i      (io_commit),
    .dac_code_o       (dac_code),
    .dac_code_valid_o (dac_code_valid),
    .dac_commit_o     (dac_commit)
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
    io_port       = 3'd0;
    io_write      = 1'b1;
    io_write_data = value;
    io_commit     = 1'b1;
    tick();
    require(dac_commit && dac_code_valid && dac_code == value[15:4],
            "port-zero commit captures only the raw upper twelve bits");
    io_commit = 1'b0;
    tick();
    require(!dac_commit && dac_code == value[15:4],
            "commit is one clock while the raw latch value persists");
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

    require(!dac_code_valid && !dac_commit,
            "FPGA initialization does not claim a physical power-up code");

    for (int unsigned word = 0; word < 65536; word++) begin
      commit_word(word[15:0]);
    end

    commit_word(16'hf230);
    require(dac_code == 12'hf23,
            "smoke raw word reaches the primary-backed straight code");
    require((dac_code ^ 12'h800) == 12'h723,
            "MAME's distinct transform remains derivable but is not latched");

    for (int unsigned port = 1; port < 8; port++) begin
      io_port = port[2:0];
      io_write_data = 16'h0120 | port[15:0];
      io_commit = 1'b1;
      tick();
      require(!dac_commit && dac_code == 12'hf23,
              "other output ports cannot alter the DAC latch");
    end

    io_port = 3'd0;
    io_write = 1'b0;
    io_write_data = 16'h0000;
    io_commit = 1'b1;
    tick();
    require(!dac_commit && dac_code == 12'hf23,
            "a port-zero input-side commit cannot alter the DAC latch");

    io_commit = 1'b0;
    io_write = 1'b1;
    io_write_data = 16'h5550;
    tick();
    require(!dac_commit && dac_code == 12'hf23,
            "held write data without a physical commit has no effect");

    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    tick();
    require(!dac_code_valid && !dac_commit,
            "deterministic reinitialization restores explicit invalidity");

    $display("PASS tb_hard_drivin_sound_dac_latch");
    $finish;
  end
endmodule

`default_nettype wire
