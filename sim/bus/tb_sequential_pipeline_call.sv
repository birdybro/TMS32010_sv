`default_nettype none

module tb_sequential_pipeline_call;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic [15:0] program_data;
  logic [1:0]  phase;
  logic        clkout;
  logic [11:0] program_address;
  logic        men_n;
  logic        sample;
  logic        bus_active;
  logic        execute_valid;
  logic [11:0] execute_address;
  logic [15:0] execute_word;
  logic        pipeline_blocked;
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
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        overflow_flag;
  logic        overflow_mode;
  logic        interrupt_mask;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_sequential_pipeline_slice dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .rs_i                          (rs),
    .clock_enable_i                (clock_enable),
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
    .program_data_i                (program_data),
    .io_read_data_i                (16'h0000),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .program_address_o             (program_address),
    .men_n_o                       (men_n),
    .den_n_o                       (),
    .we_n_o                        (),
    .program_write_o               (),
    .program_write_data_o          (),
    .sample_o                      (sample),
    .bus_active_o                  (bus_active),
    .execute_valid_o               (execute_valid),
    .execute_address_o             (execute_address),
    .execute_word_o                (execute_word),
    .pipeline_blocked_o            (pipeline_blocked),
    .data_address_o                (),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .io_write_data_o               (),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (t_register),
    .product_register_o            (product_register),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (data_page_pointer),
    .stack_top_o                    (stack_top),
    .stack_level_1_o               (stack_level_1),
    .stack_level_2_o               (stack_level_2),
    .stack_bottom_o                (stack_bottom),
    .overflow_flag_o               (overflow_flag),
    .overflow_mode_o               (overflow_mode),
    .interrupt_mask_o              (interrupt_mask),
    .interrupt_pending_o           (),
    .instruction_valid_o           (),
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

  task automatic advance_to_sample(input string name);
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require(clkout == phase[1], {name, " CLKOUT follows phase encoding"});
      if (sample) begin
        return;
      end
    end
    $fatal(1, "%s sample event did not arrive", name);
  endtask

  task automatic require_preserved_state(input string name);
    require(accumulator == 32'h0000_00a5, {name, " preserves ACC"});
    require(t_register == 16'h0000, {name, " preserves T"});
    require(product_register == 32'h0000_0000, {name, " preserves P"});
    require(auxiliary_register_0 == 16'h0031, {name, " preserves AR0"});
    require(auxiliary_register_1 == 16'h0022, {name, " preserves AR1"});
    require(!auxiliary_register_pointer, {name, " preserves ARP"});
    require(!data_page_pointer, {name, " preserves DP"});
    require(!overflow_flag, {name, " preserves OV"});
    require(overflow_mode, {name, " preserves OVM"});
    require(interrupt_mask, {name, " preserves INTM"});
    require(
      !data_read && !data_write && !data_address_valid,
      {name, " has no data-memory transaction"}
    );
  endtask

  task automatic reset_case(input string name);
    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;
    repeat (20) begin
      tick();
      require(!bus_active && men_n, {name, " reset keeps bus inactive"});
    end
    rs = 1'b0;
  endtask

  task automatic test_nested_calls;
    program_memory[0]  = 16'h7ea5;  // LACK 0xa5
    program_memory[1]  = 16'h7031;  // LARK AR0,0x31
    program_memory[2]  = 16'h7122;  // LARK AR1,0x22
    program_memory[3]  = 16'h7f8b;  // SOVM
    program_memory[4]  = 16'hf800;  // CALL
    program_memory[5]  = 16'h0008;  // first target
    program_memory[8]  = 16'hf800;  // nested CALL
    program_memory[9]  = 16'h000c;  // second target
    program_memory[12] = 16'h7042;  // target effect
    program_memory[13] = 16'h7f80;  // NOP

    reset_case("nested CALL");

    advance_to_sample("nested CALL");
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'h7ea5 &&
      !retired &&
      cycle_count == 32'd0,
      "first fetch only primes the setup stream"
    );

    repeat (3) begin
      advance_to_sample("nested CALL setup");
      require(retired && !illegal, "setup instruction retires");
    end

    advance_to_sample("nested CALL");
    require(
      retired &&
      !illegal &&
      execute_address == 12'h004 &&
      execute_word == 16'hf800 &&
      program_address == 12'h005 &&
      pc == 12'h004 &&
      cycle_count == 32'd4 &&
      !pipeline_blocked,
      "SOVM retires while CALL takes execute ownership"
    );
    require_preserved_state("CALL opcode prefetch");
    require(
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
      48'h000_000_000_000,
      "CALL opcode prefetch does not push"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n &&
      program_address == 12'h005 &&
      execute_address == 12'h004,
      "CALL operand has an active MEN phase"
    );
    clock_enable = 1'b0;
    repeat (3) begin
      tick();
      require(
        phase == 2'd1 &&
        !men_n &&
        program_address == 12'h005 &&
        execute_address == 12'h004 &&
        pc == 12'h004 &&
        cycle_count == 32'd4 &&
        !sample &&
        !retired,
        "operand stall holds CALL before its first execution boundary"
      );
      require_preserved_state("CALL operand stall");
      require(stack_top == 12'h000, "operand stall cannot push");
    end
    clock_enable = 1'b1;

    advance_to_sample("nested CALL");
    require(
      sample &&
      !retired &&
      !illegal &&
      execute_address == 12'h004 &&
      execute_word == 16'hf800 &&
      program_address == 12'h008 &&
      pc == 12'h005 &&
      cycle_count == 32'd5 &&
      !pipeline_blocked,
      "operand completion selects target without retiring CALL"
    );
    require_preserved_state("CALL operand completion");
    require(stack_top == 12'h000, "operand completion cannot push");

    tick();
    require(
      phase == 2'd1 &&
      !men_n &&
      program_address == 12'h008 &&
      execute_address == 12'h004,
      "CALL retains execute ownership during target fetch"
    );
    clock_enable = 1'b0;
    repeat (3) begin
      tick();
      require(
        phase == 2'd1 &&
        !men_n &&
        program_address == 12'h008 &&
        execute_address == 12'h004 &&
        pc == 12'h005 &&
        cycle_count == 32'd5 &&
        !sample &&
        !retired,
        "target-fetch stall holds CALL and its selected address"
      );
      require_preserved_state("CALL target-fetch stall");
      require(stack_top == 12'h000, "target-fetch stall cannot push");
    end
    clock_enable = 1'b1;

    advance_to_sample("nested CALL");
    require(
      retired &&
      !illegal &&
      execute_address == 12'h008 &&
      execute_word == 16'hf800 &&
      program_address == 12'h009 &&
      pc == 12'h008 &&
      cycle_count == 32'd6 &&
      !pipeline_blocked,
      "target fetch retires CALL and captures the nested CALL"
    );
    require_preserved_state("first CALL retirement");
    require(
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
      48'h006_000_000_000,
      "first CALL pushes opcode PC plus two only at retirement"
    );

    advance_to_sample("nested CALL");
    require(
      !retired &&
      !illegal &&
      execute_address == 12'h008 &&
      execute_word == 16'hf800 &&
      program_address == 12'h00c &&
      pc == 12'h009 &&
      cycle_count == 32'd7 &&
      !pipeline_blocked,
      "nested operand selects its target without an early push"
    );
    require_preserved_state("nested CALL operand");
    require(
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
      48'h006_000_000_000,
      "nested CALL operand preserves the first return address"
    );

    advance_to_sample("nested CALL");
    require(
      retired &&
      !illegal &&
      execute_address == 12'h00c &&
      execute_word == 16'h7042 &&
      program_address == 12'h00d &&
      pc == 12'h00c &&
      cycle_count == 32'd8 &&
      auxiliary_register_0 == 16'h0031 &&
      !pipeline_blocked,
      "nested target fetch retires CALL without executing target"
    );
    require_preserved_state("nested CALL retirement");
    require(
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
      48'h00a_006_000_000,
      "nested CALL shifts the first return below opcode PC plus two"
    );

    advance_to_sample("nested CALL");
    require(
      retired &&
      !illegal &&
      execute_address == 12'h00d &&
      pc == 12'h00d &&
      cycle_count == 32'd9 &&
      auxiliary_register_0 == 16'h0042 &&
      accumulator == 32'h0000_00a5 &&
      overflow_mode,
      "target instruction executes only in the following interval"
    );
  endtask

  task automatic test_malformed_target;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'hf800;
    program_memory[1] = 16'hf123;

    reset_case("malformed CALL");
    advance_to_sample("malformed CALL");
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'hf800 &&
      program_address == 12'h001 &&
      pc == 12'h000 &&
      cycle_count == 32'd0 &&
      !pipeline_blocked,
      "malformed case primes CALL before reading its operand"
    );

    advance_to_sample("malformed CALL");
    require(
      !retired &&
      !illegal &&
      execute_address == 12'h000 &&
      execute_word == 16'hf800 &&
      program_address == 12'h001 &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      pipeline_blocked &&
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
        48'h000_000_000_000,
      "malformed CALL parks before target selection or stack push"
    );
    repeat (4) begin
      tick();
      require(
        phase == 2'd0 &&
        program_address == 12'h001 &&
        execute_address == 12'h000 &&
        pc == 12'h001 &&
        cycle_count == 32'd1 &&
        pipeline_blocked &&
        !sample &&
        !retired &&
        {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
          48'h000_000_000_000,
        "malformed CALL remains parked without stack mutation"
      );
    end
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;

    test_nested_calls();
    test_malformed_target();

    $display("PASS tb_sequential_pipeline_call");
    $finish;
  end
endmodule

`default_nettype wire
