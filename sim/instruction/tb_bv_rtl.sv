`default_nettype none

module tb_bv_rtl;
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
  logic [15:0] debug_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic        overflow_flag;
  logic        overflow_mode;
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
    .debug_data_write_i             (debug_data_write),
    .debug_data_address_i           (8'h00),
    .debug_data_i                   (debug_data),
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
    .overflow_flag_o                (overflow_flag),
    .overflow_mode_o                (overflow_mode),
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

  task automatic start_case(input logic status_overflow);
    initialize       = 1'b1;
    reset            = 1'b1;
    clock_enable     = 1'b1;
    debug_data       = status_overflow ? 16'h8000 : 16'h0000;
    debug_data_write = 1'b1;
    tick();
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    reset            = 1'b0;
    #1;
  endtask

  task automatic run_outcome(
    input logic  status_overflow,
    input string name
  );
    program_memory[0] = 16'h7b00;  // LST 0 establishes OV.
    program_memory[1] = 16'hf500;  // BV
    program_memory[2] = 16'h0004;  // Target.
    program_memory[3] = 16'h7f80;  // Fallthrough NOP.
    program_memory[4] = 16'h7f80;  // Target NOP.
    start_case(status_overflow);

    tick();
    require(retired && !illegal && pc == 12'h001 &&
            cycle_count == 32'd1 &&
            overflow_flag == status_overflow,
            {name, " LST setup"});

    tick();
    require(instruction_valid && !retired && !illegal &&
            pc == 12'h002 && cycle_count == 32'd2 &&
            overflow_flag == status_overflow,
            {name, " opcode cycle preserves OV"});
    require(
      program_next_address == (status_overflow ? 12'h004 : 12'h003),
      {name, " predicts target or fallthrough"}
    );
    require(!data_read && !data_write && !data_address_valid,
            {name, " target cycle has no data transaction"});

    clock_enable = 1'b0;
    tick();
    require(pc == 12'h002 && cycle_count == 32'd2 &&
            !retired && !illegal &&
            overflow_flag == status_overflow &&
            program_next_address ==
              (status_overflow ? 12'h004 : 12'h003),
            {name, " target-cycle stall"});
    clock_enable = 1'b1;

    tick();
    require(retired && !illegal && cycle_count == 32'd3 &&
            pc == (status_overflow ? 12'h004 : 12'h003),
            {name, " second-cycle retirement"});
    require(!overflow_flag, {name, " leaves OV clear"});
    require(accumulator == 32'h0000_0000 && !overflow_mode,
            {name, " preserves unrelated datapath and OVM"});
  endtask

  task automatic reject_noncanonical_target;
    program_memory[0] = 16'h7b00;
    program_memory[1] = 16'hf500;
    program_memory[2] = 16'hf123;
    start_case(1'b1);

    tick();
    require(retired && overflow_flag && pc == 12'h001,
            "malformed setup loads OV");
    tick();
    require(!retired && !illegal && overflow_flag &&
            pc == 12'h002 && cycle_count == 32'd2,
            "malformed opcode cycle has no effects");
    tick();
    require(!instruction_valid && !retired && illegal &&
            overflow_flag && pc == 12'h002 &&
            cycle_count == 32'd2,
            "malformed target traps before OV clear");

    program_memory[2] = 16'h0004;
    tick();
    require(retired && !illegal && !overflow_flag &&
            pc == 12'h004 && cycle_count == 32'd3,
            "canonical replacement branches and clears OV");
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    initialize       = 1'b1;
    reset            = 1'b1;
    clock_enable     = 1'b1;
    debug_data_write = 1'b0;
    debug_data       = 16'h0000;

    run_outcome(1'b1, "taken");
    run_outcome(1'b0, "untaken");
    reject_noncanonical_target();

    $display("PASS tb_bv_rtl");
    $finish;
  end
endmodule

`default_nettype wire
