`default_nettype none

module tb_sequential_pipeline_accumulator_branches;
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
  logic        execute_valid;
  logic [11:0] execute_address;
  logic [15:0] execute_word;
  logic        pipeline_blocked;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] auxiliary_register_0;
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
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'hffff),
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
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (),
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

  task automatic run_case(
    input logic [15:0] opcode,
    input logic [15:0] setup_opcode,
    input logic [31:0] expected_accumulator,
    input logic        expected_taken,
    input logic        stall_selected,
    input string       name
  );
    logic [11:0] expected_selected_address;
    logic [15:0] expected_selected_word;
    logic [15:0] old_auxiliary_register_0;

    expected_selected_address = expected_taken ? 12'h004 : 12'h003;
    expected_selected_word = expected_taken ? 16'h7042 : 16'h7031;

    program_memory[0] = setup_opcode;
    program_memory[1] = opcode;
    program_memory[2] = 16'h0004;
    program_memory[3] = 16'h7031;  // fallthrough effect
    program_memory[4] = 16'h7042;  // target effect
    program_memory[5] = 16'h7f80;

    reset_case(name);

    advance_to_sample(name);
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == setup_opcode &&
      !retired &&
      cycle_count == 32'd0,
      {name, " first fetch only primes setup"}
    );

    advance_to_sample(name);
    old_auxiliary_register_0 = auxiliary_register_0;
    require(
      retired &&
      !illegal &&
      accumulator == expected_accumulator &&
      execute_address == 12'h001 &&
      execute_word == opcode &&
      program_address == 12'h002 &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      !pipeline_blocked,
      {name, " setup retires while branch takes execute ownership"}
    );

    advance_to_sample(name);
    require(
      sample &&
      !retired &&
      !illegal &&
      accumulator == expected_accumulator &&
      execute_address == 12'h001 &&
      execute_word == opcode &&
      program_address == expected_selected_address &&
      pc == 12'h002 &&
      cycle_count == 32'd2 &&
      auxiliary_register_0 == old_auxiliary_register_0 &&
      !data_read &&
      !data_write &&
      !data_address_valid &&
      !pipeline_blocked,
      {name, " operand selects target or fallthrough without retiring"}
    );

    if (stall_selected) begin
      tick();
      require(
        phase == 2'd1 &&
        !men_n &&
        program_address == expected_selected_address &&
        execute_address == 12'h001,
        {name, " selected instruction has an active MEN phase"}
      );
      clock_enable = 1'b0;
      repeat (3) begin
        tick();
        require(
          phase == 2'd1 &&
          !men_n &&
          program_address == expected_selected_address &&
          execute_address == 12'h001 &&
          pc == 12'h002 &&
          cycle_count == 32'd2 &&
          accumulator == expected_accumulator &&
          auxiliary_register_0 == old_auxiliary_register_0 &&
          !sample &&
          !retired,
          {name, " selected-fetch stall holds condition and ownership"}
        );
      end
      clock_enable = 1'b1;
    end

    advance_to_sample(name);
    require(
      retired &&
      !illegal &&
      accumulator == expected_accumulator &&
      execute_address == expected_selected_address &&
      execute_word == expected_selected_word &&
      program_address == expected_selected_address + 12'h001 &&
      pc == expected_selected_address &&
      cycle_count == 32'd3 &&
      auxiliary_register_0 == old_auxiliary_register_0 &&
      !pipeline_blocked,
      {name, " selected fetch retires branch and only primes instruction"}
    );

    advance_to_sample(name);
    require(
      retired &&
      !illegal &&
      accumulator == expected_accumulator &&
      auxiliary_register_0 ==
        (expected_taken ? 16'h0042 : 16'h0031) &&
      pc == expected_selected_address + 12'h001 &&
      cycle_count == 32'd4,
      {name, " selected instruction executes in following interval"}
    );
  endtask

  task automatic reject_noncanonical_target;
    program_memory[0] = 16'hfd00;  // BGEZ
    program_memory[1] = 16'hf123;
    reset_case("BGEZ malformed");

    advance_to_sample("BGEZ malformed");
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'hfd00 &&
      program_address == 12'h001 &&
      !pipeline_blocked,
      "malformed case primes exact BGEZ"
    );

    advance_to_sample("BGEZ malformed");
    require(
      !retired &&
      !illegal &&
      execute_address == 12'h000 &&
      execute_word == 16'hfd00 &&
      program_address == 12'h001 &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      pipeline_blocked,
      "malformed BGEZ parks before an unsupported speculative fetch"
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
        !retired,
        "malformed BGEZ remains parked without architectural effects"
      );
    end
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

    run_case(16'hfa00, 16'h2000, 32'hffff_ffff, 1'b1, 1'b1, "BLZ taken");
    run_case(16'hfa00, 16'h7f89, 32'h0000_0000, 1'b0, 1'b1, "BLZ untaken");
    run_case(16'hfb00, 16'h7f89, 32'h0000_0000, 1'b1, 1'b0, "BLEZ taken");
    run_case(16'hfb00, 16'h7e01, 32'h0000_0001, 1'b0, 1'b0, "BLEZ untaken");
    run_case(16'hfc00, 16'h7e01, 32'h0000_0001, 1'b1, 1'b0, "BGZ taken");
    run_case(16'hfc00, 16'h7f89, 32'h0000_0000, 1'b0, 1'b0, "BGZ untaken");
    run_case(16'hfd00, 16'h7f89, 32'h0000_0000, 1'b1, 1'b0, "BGEZ taken");
    run_case(16'hfd00, 16'h2000, 32'hffff_ffff, 1'b0, 1'b0, "BGEZ untaken");
    run_case(16'hfe00, 16'h7e01, 32'h0000_0001, 1'b1, 1'b0, "BNZ taken");
    run_case(16'hfe00, 16'h7f89, 32'h0000_0000, 1'b0, 1'b0, "BNZ untaken");
    run_case(16'hff00, 16'h7f89, 32'h0000_0000, 1'b1, 1'b0, "BZ taken");
    run_case(16'hff00, 16'h7e01, 32'h0000_0001, 1'b0, 1'b0, "BZ untaken");

    reject_noncanonical_target();

    $display("PASS tb_sequential_pipeline_accumulator_branches");
    $finish;
  end
endmodule

`default_nettype wire
