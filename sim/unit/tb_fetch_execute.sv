`default_nettype none

module tb_fetch_execute;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        cycle_boundary;
  logic        fetched_valid;
  logic [11:0] fetched_address;
  logic [15:0] fetched_word;
  logic        execute_complete;
  logic        flush;
  logic        execute_valid;
  logic [11:0] execute_address;
  logic [15:0] execute_word;

  tms32010_fetch_execute dut (
    .clk_i                (clk),
    .initialize_i         (initialize),
    .reset_i              (reset),
    .cycle_boundary_i     (cycle_boundary),
    .fetched_valid_i      (fetched_valid),
    .fetched_address_i    (fetched_address),
    .fetched_word_i       (fetched_word),
    .execute_complete_i   (execute_complete),
    .flush_i              (flush),
    .execute_valid_o      (execute_valid),
    .execute_address_o    (execute_address),
    .execute_word_o       (execute_word)
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

  task automatic boundary(
    input logic        next_fetched_valid,
    input logic [11:0] next_fetched_address,
    input logic [15:0] next_fetched_word,
    input logic        current_execute_complete,
    input logic        redirect_flush
  );
    fetched_valid   = next_fetched_valid;
    fetched_address = next_fetched_address;
    fetched_word    = next_fetched_word;
    execute_complete = current_execute_complete;
    flush            = redirect_flush;
    cycle_boundary   = 1'b1;
    tick();
    cycle_boundary = 1'b0;
  endtask

  initial begin
    initialize      = 1'b1;
    reset           = 1'b0;
    cycle_boundary  = 1'b0;
    fetched_valid   = 1'b0;
    fetched_address = 12'h000;
    fetched_word    = 16'h0000;
    execute_complete = 1'b0;
    flush            = 1'b0;
    tick();
    initialize = 1'b0;
    require(
      !execute_valid && execute_address == 12'h000 &&
      execute_word == 16'h0000,
      "FPGA initialization empties the execute slot"
    );

    // Figure 2-2 priming: fetch 0 fills an empty execute slot. The next
    // boundary completes instruction 0 while fetch 1 replaces it.
    boundary(1'b1, 12'h000, 16'h7e11, 1'b0, 1'b0);
    require(
      execute_valid && execute_address == 12'h000 &&
      execute_word == 16'h7e11,
      "first fetch primes the execute slot without a prior retirement"
    );

    fetched_valid    = 1'b1;
    fetched_address  = 12'h001;
    fetched_word     = 16'h7e22;
    execute_complete = 1'b1;
    repeat (4) begin
      tick();
      require(
        execute_valid && execute_address == 12'h000 &&
        execute_word == 16'h7e11,
        "non-boundary FPGA clocks hold fetch and execute ownership"
      );
    end
    boundary(1'b1, 12'h001, 16'h7e22, 1'b1, 1'b0);
    require(
      execute_valid && execute_address == 12'h001 &&
      execute_word == 16'h7e22,
      "sequential fetch replaces the completed execute instruction"
    );

    // A multicycle instruction owns the execute slot while a dummy/operand
    // program read is classified as non-instruction traffic.
    boundary(1'b0, 12'h002, 16'hbeef, 1'b0, 1'b0);
    require(
      execute_valid && execute_address == 12'h001 &&
      execute_word == 16'h7e22,
      "noninstruction fetch cannot displace an incomplete execution"
    );
    boundary(1'b0, 12'h000, 16'h0000, 1'b1, 1'b0);
    require(!execute_valid, "completion without a fetch leaves a bubble");

    // Branch operand fetch and redirect: the following target word is not
    // captured until its own external read completes.
    boundary(1'b1, 12'h010, 16'hf900, 1'b0, 1'b0);
    require(
      execute_valid && execute_address == 12'h010 &&
      execute_word == 16'hf900,
      "branch opcode enters execute"
    );
    boundary(1'b0, 12'h011, 16'h1234, 1'b1, 1'b1);
    require(!execute_valid, "branch operand boundary flushes the old path");
    boundary(1'b1, 12'h234, 16'h7e44, 1'b0, 1'b0);
    require(
      execute_valid && execute_address == 12'h234 &&
      execute_word == 16'h7e44,
      "redirect target enters execute only after its own fetch"
    );

    // Figure 2-12: N executes while N+1 is fetched, the N+2 fetch is marked
    // dummy and flushes execution, then vector word 2 enters the empty slot.
    boundary(1'b0, 12'h000, 16'h0000, 1'b1, 1'b0);
    boundary(1'b1, 12'h120, 16'h7e55, 1'b0, 1'b0);
    boundary(1'b1, 12'h121, 16'h7e66, 1'b1, 1'b0);
    require(
      execute_valid && execute_address == 12'h121 &&
      execute_word == 16'h7e66,
      "fetch N+1 replaces completed execute N"
    );
    boundary(1'b0, 12'h122, 16'h7f89, 1'b1, 1'b1);
    require(!execute_valid, "interrupt dummy fetch cannot enter execute");
    boundary(1'b1, 12'h002, 16'h7e77, 1'b0, 1'b0);
    require(
      execute_valid && execute_address == 12'h002 &&
      execute_word == 16'h7e77,
      "vector word enters execute after the dummy slot"
    );

    reset = 1'b1;
    cycle_boundary = 1'b0;
    repeat (3) begin
      tick();
      require(
        execute_valid && execute_address == 12'h002,
        "recognized reset changes pipeline state only at a cycle boundary"
      );
    end
    boundary(1'b0, 12'h000, 16'h0000, 1'b0, 1'b0);
    require(
      !execute_valid && execute_address == 12'h000 &&
      execute_word == 16'h0000,
      "recognized reset boundary empties the execute slot"
    );

    $display("PASS tb_fetch_execute");
    $finish;
  end
endmodule

`default_nettype wire
