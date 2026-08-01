`default_nettype none

module tb_cala_ret_rtl;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic [15:0] program_data;
  logic        program_read;
  logic        program_write;
  logic        io_read;
  logic        io_write;
  logic        data_read;
  logic        data_write;
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
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .reset_i                       (reset),
    .clock_enable_i                (clock_enable),
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
    .program_address_o             (program_address),
    .program_next_address_o        (program_next_address),
    .program_read_o                (program_read),
    .program_write_o               (program_write),
    .program_write_data_o          (),
    .program_data_i                (program_data),
    .io_port_o                     (),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (),
    .io_read_data_i                (16'h0000),
    .data_address_o                (),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
    .overflow_flag_o                (),
    .overflow_mode_o                (),
    .interrupt_mask_o               (),
    .interrupt_pending_o            (),
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

  task automatic require_no_side_bus(input string message);
    require(
      program_read && !program_write &&
      !data_read && !data_write && !io_read && !io_write,
      message
    );
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7e06; // LACK 6
    program_memory[1] = 16'h7f8c; // CALA
    program_memory[2] = 16'h7eee; // discarded sequential word, then return PC
    program_memory[6] = 16'h7e44; // LACK 0x44
    program_memory[7] = 16'h7f8d; // RET
    program_memory[8] = 16'h7edd; // discarded sequential word

    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;
    reset      = 1'b0;

    tick();
    require(retired && !illegal && pc == 12'h001 &&
            accumulator == 32'h0000_0006 && cycle_count == 32'd1,
            "CALA target setup");

    tick();
    require(instruction_valid && !retired && !illegal &&
            pc == 12'h002 && cycle_count == 32'd2,
            "CALA discarded-prefetch cycle does not retire");
    require(program_next_address == 12'h006,
            "CALA selects captured ACC low address");
    require({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
            48'h000_000_000_000,
            "CALA does not push before target fetch");
    require_no_side_bus("CALA first cycle is program read only");

    clock_enable = 1'b0;
    tick();
    require(!retired && pc == 12'h002 && cycle_count == 32'd2 &&
            stack_top == 12'h000 && program_next_address == 12'h006,
            "CALA target stall preserves pending state");
    clock_enable = 1'b1;
    tick();
    require(retired && !illegal && pc == 12'h006 && cycle_count == 32'd3,
            "CALA target fetch retires");
    require({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
            48'h002_000_000_000,
            "CALA pushes one-word return address at retirement");
    require_no_side_bus("CALA second cycle is program read only");

    tick();
    require(retired && pc == 12'h007 &&
            accumulator == 32'h0000_0044 && cycle_count == 32'd4,
            "target instruction executes once");
    tick();
    require(instruction_valid && !retired && !illegal &&
            pc == 12'h008 && cycle_count == 32'd5,
            "RET discarded-prefetch cycle does not retire");
    require(program_next_address == 12'h002 && stack_top == 12'h002,
            "RET captures old top without popping early");
    require_no_side_bus("RET first cycle is program read only");

    clock_enable = 1'b0;
    tick();
    require(!retired && pc == 12'h008 && cycle_count == 32'd5 &&
            stack_top == 12'h002 && program_next_address == 12'h002,
            "RET target stall preserves pending state");
    clock_enable = 1'b1;
    tick();
    require(retired && !illegal && pc == 12'h002 && cycle_count == 32'd6,
            "RET target fetch retires");
    require({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
            48'h000_000_000_000,
            "RET pops stack at retirement");
    require_no_side_bus("RET second cycle is program read only");

    tick();
    require(retired && pc == 12'h003 &&
            accumulator == 32'h0000_00ee && cycle_count == 32'd7,
            "return-address word was not executed during RET");

    $display("PASS tb_cala_ret_rtl");
    $finish;
  end
endmodule

`default_nettype wire
