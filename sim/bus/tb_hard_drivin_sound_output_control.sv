`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_output_control;
  logic        clk;
  logic        initialize;
  logic        dsp_reset_n;
  logic [2:0]  io_port;
  logic        io_write;
  logic [15:0] io_write_data;
  logic        io_commit;
  logic        host_irq_clear_commit;
  logic        mute_net;
  logic        mute_commit;
  logic        irq_68000;

  hard_drivin_sound_output_control dut (
    .clk_i                       (clk),
    .initialize_i                (initialize),
    .dsp_reset_n_i               (dsp_reset_n),
    .io_port_i                   (io_port),
    .io_write_i                  (io_write),
    .io_write_data_i             (io_write_data),
    .io_commit_i                 (io_commit),
    .host_irq_clear_commit_i     (host_irq_clear_commit),
    .mute_net_o                  (mute_net),
    .mute_commit_o               (mute_commit),
    .irq_68000_o                 (irq_68000)
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

  task automatic clear_irq;
    io_write = 1'b0;
    io_commit = 1'b0;
    host_irq_clear_commit = 1'b1;
    tick();
    host_irq_clear_commit = 1'b0;
    require(!irq_68000, "host /IRQCLR completion clears grounded-D latch");
  endtask

  initial begin
    initialize = 1'b1;
    dsp_reset_n = 1'b0;
    io_port = 3'd0;
    io_write = 1'b0;
    io_write_data = 16'h0000;
    io_commit = 1'b0;
    host_irq_clear_commit = 1'b0;
    tick();

    initialize = 1'b0;
    dsp_reset_n = 1'b1;
    tick();
    require(mute_net && !mute_commit && !irq_68000,
            "/320RES clears Q states and leaves complementary MUTE high");

    // Exhaust every word to prove that only TD0 controls the complement net.
    for (int unsigned word = 0; word < 65536; word++) begin
      io_port = 3'd4;
      io_write = 1'b1;
      io_write_data = word[15:0];
      io_commit = 1'b1;
      tick();
      require(mute_commit && mute_net == !word[0],
              "port-4 completion captures only complement TD0");
      io_commit = 1'b0;
      tick();
      require(!mute_commit && mute_net == !word[0],
              "raw MUTE state persists after its one-clock commit pulse");
    end

    // Every port-5 data value has the same asynchronous-preset effect; no
    // completion pulse is required to expose the physical request.
    for (int unsigned word = 0; word < 65536; word++) begin
      clear_irq();
      io_port = 3'd5;
      io_write = 1'b1;
      io_write_data = word[15:0];
      io_commit = 1'b0;
      tick();
      require(irq_68000,
              "port-5 request presets 320IRQ independently of write data");
    end

    clear_irq();
    io_port = 3'd5;
    io_write = 1'b1;
    host_irq_clear_commit = 1'b1;
    tick();
    require(irq_68000,
            "active /68IRQ preset wins over simultaneous normal host clear");
    io_write = 1'b0;
    tick();
    require(!irq_68000,
            "held host clear takes effect after /68IRQ request releases");
    host_irq_clear_commit = 1'b0;

    // Other ports and uncommitted port-4 data cannot alter either raw state.
    io_port = 3'd4;
    io_write = 1'b1;
    io_write_data = 16'h0000;
    io_commit = 1'b1;
    tick();
    io_commit = 1'b0;
    tick();
    require(mute_net && !mute_commit,
            "test establishes a known high raw MUTE state");
    io_write_data = 16'h0001;
    tick();
    require(mute_net && !mute_commit && !irq_68000,
            "uncommitted port-4 data has no latch effect");
    for (int unsigned port = 0; port < 8; port++) begin
      if ((port != 4) && (port != 5)) begin
        io_port = port[2:0];
        io_write_data = 16'hffff;
        io_commit = 1'b1;
        tick();
        require(mute_net && !mute_commit && !irq_68000,
                "unrelated output ports leave both LS74 states unchanged");
      end
    end

    // Physical /320RES clear dominates both write paths.
    io_port = 3'd5;
    io_write = 1'b1;
    io_commit = 1'b1;
    dsp_reset_n = 1'b0;
    tick();
    require(mute_net && !mute_commit && !irq_68000,
            "/320RES dominates preset, clock, and host clear inputs");

    $display("PASS tb_hard_drivin_sound_output_control");
    $finish;
  end
endmodule

`default_nettype wire
