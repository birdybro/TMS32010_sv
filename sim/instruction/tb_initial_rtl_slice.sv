`default_nettype none

module tb_initial_rtl_slice;
  logic        clk;
  logic        reset;
  logic        clock_enable;
  logic [11:0] program_address;
  logic        program_read;
  logic [15:0] program_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic        overflow_mode;
  logic        interrupt_mask;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;

  logic [15:0] program_memory [0:4095];

  tms32010_core dut (
    .clk_i             (clk),
    .reset_i           (reset),
    .clock_enable_i    (clock_enable),
    .program_address_o (program_address),
    .program_read_o    (program_read),
    .program_data_i    (program_data),
    .pc_o              (pc),
    .accumulator_o     (accumulator),
    .overflow_mode_o   (overflow_mode),
    .interrupt_mask_o  (interrupt_mask),
    .retired_o         (retired),
    .illegal_o         (illegal),
    .cycle_count_o     (cycle_count)
  );

  assign program_data = program_memory[program_address];

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

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7e80;
    program_memory[1] = 16'h7f89;
    program_memory[2] = 16'h7f8b;
    program_memory[3] = 16'h7f80;
    program_memory[4] = 16'h7f81;

    reset        = 1'b1;
    clock_enable = 1'b1;
    tick();
    require(pc == 12'h000, "reset PC");
    require(interrupt_mask, "reset masks interrupts");
    require(!program_read, "program read inactive during reset");

    reset = 1'b0;
    tick();
    require(retired, "LACK retires");
    require(accumulator == 32'h0000_0080, "LACK zero extends");
    require(pc == 12'h001, "LACK advances PC");
    require(cycle_count == 32'd1, "LACK is one architectural cycle");

    tick();
    require(accumulator == 32'h0000_0000, "ZAC clears accumulator");
    require(pc == 12'h002, "ZAC advances PC");

    tick();
    require(overflow_mode, "SOVM sets overflow mode");
    require(pc == 12'h003, "SOVM advances PC");

    clock_enable = 1'b0;
    tick();
    require(pc == 12'h003, "clock enable stalls PC");
    require(!retired, "stalled instruction does not retire");
    require(cycle_count == 32'd3, "stall does not count a cycle");

    clock_enable = 1'b1;
    tick();
    require(pc == 12'h004, "NOP advances PC");
    require(accumulator == 32'h0000_0000, "NOP preserves accumulator");

    tick();
    require(illegal, "unsupported opcode traps");
    require(!retired, "unsupported opcode does not retire");
    require(pc == 12'h004, "unsupported opcode holds PC");
    require(cycle_count == 32'd4, "unsupported opcode is not counted");

    program_memory[4] = 16'h7f8a;
    tick();
    require(!illegal, "valid opcode clears trap indication");
    require(!overflow_mode, "ROVM clears overflow mode");
    require(pc == 12'h005, "ROVM advances PC");

    program_memory[0] = 16'h7f8b;
    reset      = 1'b1;
    tick();
    require(pc == 12'h000, "second reset clears PC");
    require(!overflow_mode, "reset preserves cleared OVM");

    reset = 1'b0;
    tick();
    require(overflow_mode, "SOVM executes after reset");
    reset = 1'b1;
    tick();
    require(overflow_mode, "reset preserves set OVM");

    $display("PASS tb_initial_rtl_slice");
    $finish;
  end
endmodule

`default_nettype wire
