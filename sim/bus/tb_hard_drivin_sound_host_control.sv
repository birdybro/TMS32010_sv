`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_host_control;
  logic       clk;
  logic       initialize;
  logic       board_reset_n;
  logic       latch_write_commit;
  logic [3:0] latch_address;
  logic [7:0] latch_q;
  logic [7:0] latch_valid;

  hard_drivin_sound_host_control dut (
    .clk_i                (clk),
    .initialize_i         (initialize),
    .board_reset_n_i      (board_reset_n),
    .latch_write_commit_i (latch_write_commit),
    .latch_address_i      (latch_address),
    .latch_q_o            (latch_q),
    .latch_valid_o        (latch_valid)
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

  task automatic write_latch(
    input logic [2:0] select,
    input logic       value
  );
    latch_address = {value, select};
    latch_write_commit = 1'b1;
    tick();
    latch_write_commit = 1'b0;
  endtask

  initial begin
    initialize = 1'b1;
    board_reset_n = 1'b1;
    latch_write_commit = 1'b0;
    latch_address = 4'h0;
    tick();
    require((latch_q == 8'h00) && (latch_valid == 8'h00),
            "FPGA initialization does not claim physical latch validity");

    initialize = 1'b0;
    tick();
    require((latch_q == 8'h00) && (latch_valid == 8'h00),
            "unreset and unwritten latch state remains unqualified");

    // A write qualifies only the selected latch and takes its data from A4.
    for (int unsigned select = 0; select < 8; select++) begin
      initialize = 1'b1;
      tick();
      initialize = 1'b0;
      write_latch(select[2:0], 1'b1);
      require(latch_q == (8'h01 << select),
              "A3:A1 selects exactly one LS259 output");
      require(latch_valid == (8'h01 << select),
              "a write qualifies exactly the selected output");

      latch_address = {1'b0, ~select[2:0]};
      tick();
      require(latch_q == (8'h01 << select),
              "address and data changes without /LATCHES completion do nothing");

      write_latch(select[2:0], 1'b0);
      require(latch_q == 8'h00,
              "A4 low clears the selected output without changing validity");
      require(latch_valid == (8'h01 << select),
              "rewriting a bit preserves its established validity");
    end

    // Board /RESET is the physical asynchronous clear. The FPGA boundary
    // samples it and can then call every low output qualified.
    board_reset_n = 1'b0;
    latch_address = 4'hf;
    latch_write_commit = 1'b1;
    tick();
    require((latch_q == 8'h00) && (latch_valid == 8'hff),
            "board reset clears all outputs and dominates a latch write");
    board_reset_n = 1'b1;
    latch_write_commit = 1'b0;

    // Build two complementary complete patterns and prove all eight raw
    // outputs are independently addressable after reset.
    for (int unsigned select = 0; select < 8; select++) begin
      write_latch(select[2:0], select[0]);
    end
    require((latch_q == 8'haa) && (latch_valid == 8'hff),
            "address-encoded writes construct alternating raw latch pattern");
    for (int unsigned select = 0; select < 8; select++) begin
      write_latch(select[2:0], !select[0]);
    end
    require((latch_q == 8'h55) && (latch_valid == 8'hff),
            "all outputs retain independent complementary values");

    $display("PASS tb_hard_drivin_sound_host_control");
    $finish;
  end
endmodule

`default_nettype wire
