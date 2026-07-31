`default_nettype none

module tb_call_rtl;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic [15:0] program_data;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
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
    .program_read_o                 (),
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
    .t_register_o                   (),
    .product_register_o             (),
    .auxiliary_register_0_o         (),
    .auxiliary_register_1_o         (),
    .auxiliary_register_pointer_o   (),
    .data_page_pointer_o            (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
    .overflow_flag_o                (),
    .overflow_mode_o                (),
    .interrupt_mask_o               (),
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

  task automatic start_case;
    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;
    reset      = 1'b0;
    #1;
  endtask

  task automatic run_call(
    input logic [11:0] expected_target,
    input logic [11:0] expected_return,
    input logic [11:0] expected_old_top,
    input logic [11:0] expected_old_level_1,
    input logic [11:0] expected_old_level_2,
    input string       name
  );
    tick();
    require(instruction_valid && !retired && !illegal,
            {name, " opcode cycle"});
    require(
      stack_top == expected_old_top &&
      stack_level_1 == expected_old_level_1 &&
      stack_level_2 == expected_old_level_2,
      {name, " opcode sample does not push early"}
    );
    require(!data_read && !data_write && !data_address_valid,
            {name, " no data transaction"});
    require(program_next_address == expected_target,
            {name, " target-word prediction"});

    tick();
    require(retired && !illegal && pc == expected_target,
            {name, " target retirement"});
    require(
      stack_top == expected_return &&
      stack_level_1 == expected_old_top &&
      stack_level_2 == expected_old_level_1 &&
      stack_bottom == expected_old_level_2,
      {name, " return-address push"}
    );
  endtask

  task automatic test_nested_calls_and_overflow;
    program_memory[0]  = 16'h7ea5;
    program_memory[1]  = 16'hf800;
    program_memory[2]  = 16'h0006;
    program_memory[6]  = 16'hf800;
    program_memory[7]  = 16'h0009;
    program_memory[9]  = 16'hf800;
    program_memory[10] = 16'h000c;
    program_memory[12] = 16'hf800;
    program_memory[13] = 16'h000f;
    program_memory[15] = 16'hf800;
    program_memory[16] = 16'h0012;
    start_case();

    tick();
    require(retired && accumulator == 32'h0000_00a5 &&
            pc == 12'h001 && cycle_count == 32'd1,
            "setup LACK");

    tick();
    require(!retired && pc == 12'h002 && cycle_count == 32'd2,
            "first CALL opcode cycle");
    require(
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
      48'h000_000_000_000,
      "first CALL has not pushed at opcode sample"
    );
    clock_enable = 1'b0;
    tick();
    require(pc == 12'h002 && cycle_count == 32'd2 && !retired &&
            stack_top == 12'h000,
            "target-cycle stall preserves stack and PC");
    clock_enable = 1'b1;
    tick();
    require(retired && pc == 12'h006 && cycle_count == 32'd3 &&
            accumulator == 32'h0000_00a5,
            "first CALL target retirement");
    require(
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
      48'h003_000_000_000,
      "first CALL pushes opcode PC plus two"
    );

    run_call(12'h009, 12'h008, 12'h003, 12'h000, 12'h000, "nested 2");
    run_call(12'h00c, 12'h00b, 12'h008, 12'h003, 12'h000, "nested 3");
    run_call(12'h00f, 12'h00e, 12'h00b, 12'h008, 12'h003, "nested 4");
    run_call(12'h012, 12'h011, 12'h00e, 12'h00b, 12'h008, "nested 5");
    require(
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
      48'h011_00e_00b_008,
      "fifth CALL discards the old bottom"
    );
    require(accumulator == 32'h0000_00a5 && cycle_count == 32'd11,
            "nested calls preserve accumulator and total cycles");
  endtask

  task automatic test_malformed_target;
    program_memory[0] = 16'hf800;
    program_memory[1] = 16'hf123;
    start_case();

    tick();
    require(!retired && !illegal && pc == 12'h001 &&
            cycle_count == 32'd1,
            "malformed case opcode cycle");
    tick();
    require(!instruction_valid && !retired && illegal &&
            pc == 12'h001 && cycle_count == 32'd1 &&
            stack_top == 12'h000,
            "malformed target traps before stack effect");

    program_memory[1] = 16'h0005;
    tick();
    require(retired && !illegal && pc == 12'h005 &&
            cycle_count == 32'd2 && stack_top == 12'h002,
            "canonical replacement completes one push");
  endtask

  task automatic test_return_address_wrap;
    program_memory[0]   = 16'hf800;
    program_memory[1]   = 16'h0004;
    program_memory[4]   = 16'hf900;
    program_memory[5]   = 16'h0ffe;
    program_memory[4094] = 16'hf800;
    program_memory[4095] = 16'h0123;
    start_case();

    run_call(12'h004, 12'h002, 12'h000, 12'h000, 12'h000, "seed call");
    tick();
    tick();
    require(retired && pc == 12'hffe && stack_top == 12'h002,
            "B reaches final-word CALL without changing stack");
    run_call(12'h123, 12'h000, 12'h002, 12'h000, 12'h000, "wrapped call");
    require(
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
      48'h000_002_000_000,
      "CALL at 0xffe wraps return address to zero"
    );
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;

    test_nested_calls_and_overflow();
    test_malformed_target();
    test_return_address_wrap();

    $display("PASS tb_call_rtl");
    $finish;
  end
endmodule

`default_nettype wire
