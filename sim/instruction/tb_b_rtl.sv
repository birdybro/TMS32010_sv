`default_nettype none

module tb_b_rtl;
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
    .debug_data_write_i             (1'b0),
    .debug_data_address_i           (8'h00),
    .debug_data_i                   (16'h0000),
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

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h7ea5;  // LACK 0xa5
    program_memory[1]  = 16'h7f8b;  // SOVM
    program_memory[2]  = 16'h7005;  // LARK AR0,5
    program_memory[3]  = 16'h7106;  // LARK AR1,6
    program_memory[4]  = 16'h6881;  // LARP 1
    program_memory[5]  = 16'h6e01;  // LDPK 1
    program_memory[6]  = 16'h7f82;  // EINT
    program_memory[7]  = 16'hf900;  // B
    program_memory[8]  = 16'h000b;  // target
    program_memory[9]  = 16'h7f89;  // skipped ZAC
    program_memory[10] = 16'h7f81;  // skipped DINT
    program_memory[11] = 16'h7f80;  // target NOP
    program_memory[12] = 16'hf900;  // malformed target test
    program_memory[13] = 16'hf123;
    program_memory[15] = 16'hf900;  // branch to itself
    program_memory[16] = 16'h000f;

    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;
    reset      = 1'b0;
    #1;

    for (int unsigned index = 0; index < 7; index++) begin
      tick();
      require(retired && !illegal, "setup instruction retires");
    end
    require(pc == 12'h007 && cycle_count == 32'd7,
            "setup reaches the branch opcode");
    require(accumulator == 32'h0000_00a5 &&
            auxiliary_register_0 == 16'h0005 &&
            auxiliary_register_1 == 16'h0006 &&
            auxiliary_register_pointer && data_page_pointer &&
            overflow_mode && !overflow_flag && !interrupt_mask,
            "setup establishes preservation-sensitive state");
    require(program_address == 12'h007 &&
            program_next_address == 12'h008 && program_read,
            "B opcode predicts its following target word");

    tick();
    require(instruction_valid && !retired && !illegal,
            "B opcode begins without retiring the instruction");
    require(pc == 12'h008 && cycle_count == 32'd8,
            "B opcode consumes the first machine cycle");
    require(program_address == 12'h008 &&
            program_next_address == 12'h00b,
            "canonical following word predicts the unconditional target");
    require(!data_read && !data_write && !data_address_valid,
            "B target word cannot become a data transaction");

    clock_enable = 1'b0;
    tick();
    require(pc == 12'h008 && cycle_count == 32'd8 && !retired &&
            program_address == 12'h008 &&
            program_next_address == 12'h00b,
            "clock-enable stall holds the pending target read");
    clock_enable = 1'b1;

    tick();
    require(retired && !illegal && pc == 12'h00b &&
            cycle_count == 32'd9,
            "B commits its target and retires on cycle two");
    require(accumulator == 32'h0000_00a5 &&
            t_register == 16'h0000 &&
            product_register == 32'h0000_0000 &&
            auxiliary_register_0 == 16'h0005 &&
            auxiliary_register_1 == 16'h0006 &&
            auxiliary_register_pointer && data_page_pointer &&
            overflow_mode && !overflow_flag && !interrupt_mask,
            "B preserves all non-PC architectural state");

    tick();
    require(retired && pc == 12'h00c && cycle_count == 32'd10,
            "branch destination executes while skipped words do not");

    tick();
    require(!retired && pc == 12'h00d && cycle_count == 32'd11,
            "second B reaches its target-word cycle");
    tick();
    require(illegal && !instruction_valid && !retired &&
            pc == 12'h00d && cycle_count == 32'd11,
            "noncanonical target traps without completing the branch");

    program_memory[13] = 16'h000f;
    tick();
    require(retired && !illegal && pc == 12'h00f &&
            cycle_count == 32'd12,
            "canonical replacement completes the pending branch");

    tick();
    require(!retired && pc == 12'h010 && cycle_count == 32'd13,
            "self-target B consumes its opcode cycle");
    tick();
    require(retired && pc == 12'h00f && cycle_count == 32'd14,
            "self-target B returns to its opcode after exactly two cycles");

    $display("PASS tb_b_rtl");
    $finish;
  end
endmodule

`default_nettype wire
