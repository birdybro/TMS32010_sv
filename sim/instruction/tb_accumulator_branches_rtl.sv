`default_nettype none

module tb_accumulator_branches_rtl;
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
  logic        debug_data_write;
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
    .debug_data_write_i             (debug_data_write),
    .debug_data_address_i           (8'h00),
    .debug_data_i                   (16'hffff),
    .pc_o                           (pc),
    .accumulator_o                  (accumulator),
    .t_register_o                   (),
    .product_register_o             (),
    .auxiliary_register_0_o         (),
    .auxiliary_register_1_o         (),
    .auxiliary_register_pointer_o   (),
    .data_page_pointer_o            (),
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

  task automatic run_case(
    input logic [15:0] opcode,
    input logic [15:0] setup_opcode,
    input logic [31:0] expected_accumulator,
    input logic        expected_taken,
    input string       name
  );
    program_memory[0] = setup_opcode;
    program_memory[1] = opcode;
    program_memory[2] = 16'h0004;
    program_memory[3] = 16'h7f80;
    program_memory[4] = 16'h7f80;

    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;
    reset      = 1'b0;
    #1;

    tick();
    require(retired && !illegal && pc == 12'h001 &&
            cycle_count == 32'd1 &&
            accumulator == expected_accumulator,
            {name, " setup"});

    tick();
    require(instruction_valid && !retired && !illegal &&
            pc == 12'h002 && cycle_count == 32'd2,
            {name, " opcode cycle"});
    require(
      program_next_address == (expected_taken ? 12'h004 : 12'h003),
      {name, " condition predicts target or fallthrough"}
    );
    require(!data_read && !data_write && !data_address_valid,
            {name, " target cycle has no data transaction"});

    clock_enable = 1'b0;
    tick();
    require(pc == 12'h002 && cycle_count == 32'd2 &&
            !retired && !illegal &&
            program_next_address == (expected_taken ? 12'h004 : 12'h003),
            {name, " target-cycle stall"});
    clock_enable = 1'b1;

    tick();
    require(retired && !illegal && cycle_count == 32'd3 &&
            pc == (expected_taken ? 12'h004 : 12'h003),
            {name, " second-cycle retirement"});
    require(accumulator == expected_accumulator,
            {name, " preserves accumulator"});
  endtask

  task automatic reject_noncanonical_target(
    input logic [15:0] opcode,
    input string       name
  );
    program_memory[0] = opcode;
    program_memory[1] = 16'hf123;

    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;
    reset      = 1'b0;
    #1;

    tick();
    require(!retired && !illegal && pc == 12'h001 &&
            cycle_count == 32'd1,
            {name, " malformed setup"});
    tick();
    require(!instruction_valid && !retired && illegal &&
            pc == 12'h001 && cycle_count == 32'd1,
            {name, " rejects noncanonical target before effects"});

    program_memory[1] = 16'h0004;
    tick();
    require(retired && !illegal && cycle_count == 32'd2,
            {name, " canonical replacement completes"});
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end

    initialize      = 1'b1;
    reset           = 1'b1;
    clock_enable    = 1'b1;
    debug_data_write = 1'b1;
    tick();
    debug_data_write = 1'b0;

    // Zero, positive one, and negative one distinguish every predicate.
    run_case(16'hfa00, 16'h7f89, 32'h0000_0000, 1'b0, "BLZ zero");
    run_case(16'hfa00, 16'h7e01, 32'h0000_0001, 1'b0, "BLZ positive");
    run_case(16'hfa00, 16'h2000, 32'hffff_ffff, 1'b1, "BLZ negative");

    run_case(16'hfb00, 16'h7f89, 32'h0000_0000, 1'b1, "BLEZ zero");
    run_case(16'hfb00, 16'h7e01, 32'h0000_0001, 1'b0, "BLEZ positive");
    run_case(16'hfb00, 16'h2000, 32'hffff_ffff, 1'b1, "BLEZ negative");

    run_case(16'hfc00, 16'h7f89, 32'h0000_0000, 1'b0, "BGZ zero");
    run_case(16'hfc00, 16'h7e01, 32'h0000_0001, 1'b1, "BGZ positive");
    run_case(16'hfc00, 16'h2000, 32'hffff_ffff, 1'b0, "BGZ negative");

    run_case(16'hfd00, 16'h7f89, 32'h0000_0000, 1'b1, "BGEZ zero");
    run_case(16'hfd00, 16'h7e01, 32'h0000_0001, 1'b1, "BGEZ positive");
    run_case(16'hfd00, 16'h2000, 32'hffff_ffff, 1'b0, "BGEZ negative");

    run_case(16'hfe00, 16'h7f89, 32'h0000_0000, 1'b0, "BNZ zero");
    run_case(16'hfe00, 16'h7e01, 32'h0000_0001, 1'b1, "BNZ positive");
    run_case(16'hfe00, 16'h2000, 32'hffff_ffff, 1'b1, "BNZ negative");

    run_case(16'hff00, 16'h7f89, 32'h0000_0000, 1'b1, "BZ zero");
    run_case(16'hff00, 16'h7e01, 32'h0000_0001, 1'b0, "BZ positive");
    run_case(16'hff00, 16'h2000, 32'hffff_ffff, 1'b0, "BZ negative");

    reject_noncanonical_target(16'hfa00, "BLZ");
    reject_noncanonical_target(16'hfb00, "BLEZ");
    reject_noncanonical_target(16'hfc00, "BGZ");
    reject_noncanonical_target(16'hfd00, "BGEZ");
    reject_noncanonical_target(16'hfe00, "BNZ");
    reject_noncanonical_target(16'hff00, "BZ");

    $display("PASS tb_accumulator_branches_rtl");
    $finish;
  end
endmodule

`default_nettype wire
