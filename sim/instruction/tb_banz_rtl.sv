`default_nettype none

module tb_banz_rtl;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic        program_read;
  logic [15:0] program_data;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] t_register;
  logic [31:0] product_register;
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
  logic        data_page_pointer;
  logic        overflow_flag;
  logic        overflow_mode;
  logic        interrupt_mask;
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_core dut (
    .clk_i                          (clk),
    .initialize_i                   (initialize),
    .reset_i                        (reset),
    .clock_enable_i                 (clock_enable),
    .bio_i                          (1'b1),
    .program_address_o              (program_address),
    .program_next_address_o         (program_next_address),
    .program_read_o                 (program_read),
    .program_data_i                 (program_data),
    .data_address_o                 (),
    .data_read_o                    (data_read),
    .data_write_o                   (data_write),
    .data_address_valid_o           (data_address_valid),
    .data_write_address_o           (),
    .data_write_address_valid_o     (),
    .data_read_data_o               (),
    .data_write_data_o              (),
    .debug_data_write_i             (debug_data_write),
    .debug_data_address_i           (debug_data_address),
    .debug_data_i                   (debug_data),
    .pc_o                           (pc),
    .accumulator_o                  (accumulator),
    .t_register_o                   (t_register),
    .product_register_o             (product_register),
    .auxiliary_register_0_o         (auxiliary_register_0),
    .auxiliary_register_1_o         (auxiliary_register_1),
    .auxiliary_register_pointer_o   (auxiliary_register_pointer),
    .data_page_pointer_o            (data_page_pointer),
    .stack_top_o                    (),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
    .overflow_flag_o                (overflow_flag),
    .overflow_mode_o                (overflow_mode),
    .interrupt_mask_o               (interrupt_mask),
    .instruction_valid_o            (instruction_valid),
    .retired_o                      (retired),
    .illegal_o                      (illegal),
    .cycle_count_o                  (cycle_count)
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

  task automatic preload_data(
    input logic [7:0] address,
    input logic [15:0] value
  );
    debug_data_write   = 1'b1;
    debug_data_address = address;
    debug_data         = value;
    tick();
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h3800;  // LAR AR0,0: upper bits, zero counter
    program_memory[1]  = 16'hf400;  // untaken BANZ
    program_memory[2]  = 16'h0100;  // target, still fetched when untaken
    program_memory[3]  = 16'h3901;  // LAR AR1,1: upper bits, counter one
    program_memory[4]  = 16'h6881;  // select AR1
    program_memory[5]  = 16'hf400;  // taken BANZ
    program_memory[6]  = 16'h0008;  // target
    program_memory[7]  = 16'h7f89;  // skipped ZAC
    program_memory[8]  = 16'h7f80;  // branch destination
    program_memory[9]  = 16'hf400;  // malformed-target trap
    program_memory[10] = 16'hf123;

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    preload_data(8'h00, 16'ha400);
    preload_data(8'h01, 16'hbe01);
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    reset            = 1'b0;
    #1;

    tick();
    require(retired && pc == 12'h001, "setup LAR retires normally");
    require(auxiliary_register_0 == 16'ha400, "setup loads complete AR0");

    require(program_address == 12'h001 &&
            program_next_address == 12'h002 && program_read,
            "BANZ opcode predicts its following word");
    tick();
    require(instruction_valid && !retired && !illegal,
            "BANZ opcode enters operand cycle without retirement");
    require(pc == 12'h002 && cycle_count == 32'd2,
            "BANZ opcode consumes the first of two cycles");
    require(auxiliary_register_0 == 16'ha400,
            "counter is unchanged until target-word sample");
    require(program_address == 12'h002 &&
            program_next_address == 12'h003 && program_read,
            "zero counter predicts fallthrough after operand");
    require(!data_read && !data_write && !data_address_valid,
            "target word is not misdecoded as an ADD data access");

    clock_enable = 1'b0;
    tick();
    require(pc == 12'h002 && cycle_count == 32'd2 &&
            auxiliary_register_0 == 16'ha400 && !retired,
            "clock-enable stall holds pending BANZ state");
    require(program_next_address == 12'h003,
            "stall holds the pending fallthrough selection");

    clock_enable = 1'b1;
    tick();
    require(retired && !illegal && pc == 12'h003,
            "zero counter completes the untaken path");
    require(auxiliary_register_0 == 16'ha5ff,
            "untaken BANZ wraps only the low nine counter bits");
    require(cycle_count == 32'd3,
            "untaken BANZ consumes exactly two counted cycles");

    tick();
    require(retired && auxiliary_register_1 == 16'hbe01 &&
            pc == 12'h004,
            "taken-path setup loads complete AR1");
    tick();
    require(retired && auxiliary_register_pointer && pc == 12'h005,
            "taken-path setup selects AR1");

    tick();
    require(!retired && pc == 12'h006 && cycle_count == 32'd6,
            "taken BANZ opcode consumes cycle one");
    require(program_next_address == 12'h008,
            "old nonzero counter selects target before decrement");
    require(!data_read && !data_write && !data_address_valid,
            "taken target word creates no internal data transaction");
    tick();
    require(retired && pc == 12'h008 && cycle_count == 32'd7,
            "taken BANZ retires on its second cycle");
    require(auxiliary_register_1 == 16'hbe00,
            "taken BANZ decrements selected low-nine counter");
    require(accumulator == 32'h0000_0000 &&
            t_register == 16'h0000 &&
            product_register == 32'h0000_0000 &&
            !data_page_pointer && !overflow_flag &&
            !overflow_mode && interrupt_mask,
            "BANZ preserves unrelated initialized state and status");

    tick();
    require(retired && pc == 12'h009 && cycle_count == 32'd8,
            "target NOP executes and skipped ZAC never retires");
    tick();
    require(!retired && pc == 12'h00a && cycle_count == 32'd9,
            "malformed-target BANZ enters its operand cycle");
    tick();
    require(illegal && !instruction_valid && !retired &&
            pc == 12'h00a && cycle_count == 32'd9,
            "noncanonical target word traps without completing BANZ");
    require(auxiliary_register_1 == 16'hbe00,
            "malformed target cannot decrement the counter");

    program_memory[10] = 16'h000c;
    tick();
    require(retired && !illegal && pc == 12'h00b &&
            cycle_count == 32'd10,
            "canonical replacement completes the pending untaken BANZ");
    require(auxiliary_register_1 == 16'hbfff,
            "zero low-nine counter wraps while preserving upper bits");

    $display("PASS tb_banz_rtl");
    $finish;
  end
endmodule

`default_nettype wire
