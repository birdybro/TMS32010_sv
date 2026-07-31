`default_nettype none

module tb_accumulator_branches_phase;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic [15:0] program_data;
  logic        debug_data_write;
  logic [1:0]  phase;
  logic        clkout;
  logic [11:0] program_address;
  logic        men_n;
  logic        sample;
  logic        bus_active;
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

  tms32010_phase_slice dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .rs_i                          (rs),
    .clock_enable_i                (clock_enable),
    .program_data_i                (program_data),
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'hffff),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .program_address_o             (program_address),
    .men_n_o                       (men_n),
    .sample_o                      (sample),
    .bus_active_o                  (bus_active),
    .data_address_o                (),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (),
    .instruction_valid_o           (instruction_valid),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
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

  task automatic advance_to_sample;
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require(clkout == phase[1], "CLKOUT follows native phase encoding");
      if (sample) begin
        return;
      end
    end
    $fatal(1, "sample event did not arrive");
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
    rs           = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;
    for (int unsigned index = 0; index < 20; index++) begin
      tick();
      require(!bus_active && men_n, {name, " reset bus"});
    end
    rs = 1'b0;

    advance_to_sample();
    require(retired && !illegal && pc == 12'h001 &&
            program_address == 12'h001 && cycle_count == 32'd1 &&
            accumulator == expected_accumulator,
            {name, " setup sample"});

    advance_to_sample();
    require(sample && instruction_valid && !retired && !illegal &&
            pc == 12'h002 && program_address == 12'h002 &&
            cycle_count == 32'd2,
            {name, " opcode sample"});
    require(!data_read && !data_write && !data_address_valid,
            {name, " target read has no data transaction"});

    tick();
    require(phase == 2'd1 && bus_active && !men_n &&
            program_address == 12'h002,
            {name, " target has ordinary active MEN phase"});
    clock_enable = 1'b0;
    tick();
    require(phase == 2'd1 && bus_active && !men_n &&
            program_address == 12'h002 && pc == 12'h002 &&
            cycle_count == 32'd2 && !retired,
            {name, " target phase stalls"});
    clock_enable = 1'b1;

    advance_to_sample();
    require(sample && retired && !illegal && cycle_count == 32'd3 &&
            pc == (expected_taken ? 12'h004 : 12'h003) &&
            program_address == (expected_taken ? 12'h004 : 12'h003),
            {name, " target sample retires"});
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end

    initialize       = 1'b1;
    rs               = 1'b1;
    clock_enable     = 1'b1;
    debug_data_write = 1'b1;
    tick();
    debug_data_write = 1'b0;

    run_case(16'hfa00, 16'h2000, 32'hffff_ffff, 1'b1, "BLZ taken");
    run_case(16'hfa00, 16'h7f89, 32'h0000_0000, 1'b0, "BLZ untaken");
    run_case(16'hfb00, 16'h7f89, 32'h0000_0000, 1'b1, "BLEZ taken");
    run_case(16'hfb00, 16'h7e01, 32'h0000_0001, 1'b0, "BLEZ untaken");
    run_case(16'hfc00, 16'h7e01, 32'h0000_0001, 1'b1, "BGZ taken");
    run_case(16'hfc00, 16'h7f89, 32'h0000_0000, 1'b0, "BGZ untaken");
    run_case(16'hfd00, 16'h7f89, 32'h0000_0000, 1'b1, "BGEZ taken");
    run_case(16'hfd00, 16'h2000, 32'hffff_ffff, 1'b0, "BGEZ untaken");
    run_case(16'hfe00, 16'h7e01, 32'h0000_0001, 1'b1, "BNZ taken");
    run_case(16'hfe00, 16'h7f89, 32'h0000_0000, 1'b0, "BNZ untaken");
    run_case(16'hff00, 16'h7f89, 32'h0000_0000, 1'b1, "BZ taken");
    run_case(16'hff00, 16'h7e01, 32'h0000_0001, 1'b0, "BZ untaken");

    $display("PASS tb_accumulator_branches_phase");
    $finish;
  end
endmodule

`default_nettype wire
