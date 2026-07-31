`default_nettype none

module tb_bioz_rtl;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic        bio;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic [15:0] program_data;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [11:0] pc;
  logic [31:0] accumulator;
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
    .bio_i                          (bio),
    .int_i                          (1'b1),
    .program_address_o              (program_address),
    .program_next_address_o         (program_next_address),
    .program_read_o                 (),
    .program_write_o               (),
    .program_write_data_o          (),
    .program_data_i                 (program_data),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .io_write_data_o               (),
    .io_read_data_i                (16'h0000),
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
    .stack_top_o                    (),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
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

  task automatic start_case;
    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;
    bio          = 1'b1;
    tick();
    initialize = 1'b0;
    reset      = 1'b0;
    #1;
  endtask

  task automatic run_transition(
    input logic  opcode_bio_high,
    input logic  target_bio_high,
    input logic  expect_taken,
    input string name
  );
    program_memory[0] = 16'h7ea5;  // LACK 0xa5.
    program_memory[1] = 16'hf600;  // BIOZ.
    program_memory[2] = 16'h0005;  // Target.
    program_memory[3] = 16'h7f80;  // Fallthrough NOP.
    program_memory[5] = 16'h7f80;  // Target NOP.
    start_case();

    tick();
    require(retired && !illegal && pc == 12'h001 &&
            accumulator == 32'h0000_00a5 && cycle_count == 32'd1,
            {name, " setup"});

    bio = opcode_bio_high;
    tick();
    require(instruction_valid && !retired && !illegal &&
            pc == 12'h002 && cycle_count == 32'd2,
            {name, " opcode cycle"});
    require(!data_read && !data_write && !data_address_valid,
            {name, " target cycle has no data transaction"});

    // TI says BIO is sampled every cycle and is not latched. The level meeting
    // setup at the target-word retirement sample therefore owns the branch.
    bio = target_bio_high;
    #1;
    require(
      program_next_address == (expect_taken ? 12'h005 : 12'h003),
      {name, " live target-sample prediction"}
    );

    clock_enable = 1'b0;
    tick();
    require(pc == 12'h002 && cycle_count == 32'd2 &&
            !retired && !illegal && accumulator == 32'h0000_00a5,
            {name, " target-cycle stall"});
    clock_enable = 1'b1;

    tick();
    require(retired && !illegal && cycle_count == 32'd3 &&
            pc == (expect_taken ? 12'h005 : 12'h003),
            {name, " second-cycle retirement"});
    require(accumulator == 32'h0000_00a5,
            {name, " preserves unrelated architectural state"});
  endtask

  task automatic reject_noncanonical_target;
    program_memory[0] = 16'hf600;
    program_memory[1] = 16'hf123;
    start_case();
    bio = 1'b0;

    tick();
    require(!retired && !illegal && pc == 12'h001 &&
            cycle_count == 32'd1,
            "malformed opcode cycle has no branch effect");
    tick();
    require(!instruction_valid && !retired && illegal &&
            pc == 12'h001 && cycle_count == 32'd1,
            "malformed target traps before testing BIO");

    program_memory[1] = 16'h0005;
    tick();
    require(retired && !illegal && pc == 12'h005 &&
            cycle_count == 32'd2,
            "canonical replacement samples low BIO and branches");
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;
    bio          = 1'b1;

    run_transition(1'b1, 1'b0, 1'b1, "high-to-low taken");
    run_transition(1'b0, 1'b1, 1'b0, "low-to-high untaken");
    reject_noncanonical_target();

    $display("PASS tb_bioz_rtl");
    $finish;
  end
endmodule

`default_nettype wire
