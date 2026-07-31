`default_nettype none

module tb_sequential_pipeline_bioz;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic        bio;
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
    .bio_i                         (bio),
    .program_data_i                (program_data),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .program_address_o             (program_address),
    .men_n_o                       (men_n),
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

  task automatic reset_case(
    input logic  opcode_bio,
    input string name
  );
    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    bio          = opcode_bio;
    tick();
    initialize = 1'b0;
    repeat (20) begin
      tick();
      require(!bus_active && men_n, {name, " reset keeps bus inactive"});
    end
    rs = 1'b0;
  endtask

  task automatic run_case(
    input logic  decision_bio,
    input string name
  );
    logic [11:0] expected_selected_address;
    logic [15:0] expected_selected_word;
    logic [15:0] old_auxiliary_register_0;

    expected_selected_address = !decision_bio ? 12'h004 : 12'h003;
    expected_selected_word = !decision_bio ? 16'h7042 : 16'h7031;

    program_memory[0] = 16'h7ea5;  // LACK 0xa5
    program_memory[1] = 16'hf600;  // BIOZ
    program_memory[2] = 16'h0004;  // canonical target
    program_memory[3] = 16'h7031;  // fallthrough effect
    program_memory[4] = 16'h7042;  // target effect
    program_memory[5] = 16'h7f80;

    // Present the opposite level while BIOZ itself is fetched. TI says the
    // pin is sampled every cycle and is not latched at opcode recognition.
    reset_case(!decision_bio, name);

    advance_to_sample(name);
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'h7ea5 &&
      !retired &&
      cycle_count == 32'd0,
      {name, " first fetch only primes LACK"}
    );

    advance_to_sample(name);
    require(
      retired &&
      !illegal &&
      execute_address == 12'h001 &&
      execute_word == 16'hf600 &&
      program_address == 12'h002 &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      !pipeline_blocked,
      {name, " LACK retires while BIOZ takes execute ownership"}
    );
    require(
      accumulator == 32'h0000_00a5,
      {name, " LACK setup produces the expected accumulator value"}
    );
    old_auxiliary_register_0 = auxiliary_register_0;

    tick();
    require(
      phase == 2'd1 &&
      !men_n &&
      program_address == 12'h002 &&
      execute_address == 12'h001,
      {name, " BIOZ operand has an active MEN phase"}
    );
    clock_enable = 1'b0;
    tick();
    bio = decision_bio;
    repeat (3) begin
      tick();
      require(
        phase == 2'd1 &&
        !men_n &&
        program_address == 12'h002 &&
        execute_address == 12'h001 &&
        pc == 12'h001 &&
        cycle_count == 32'd1 &&
        !sample &&
        !retired,
        {name, " stalled operand remains unsampled after BIO changes"}
      );
      require(
        accumulator == 32'h0000_00a5 &&
        auxiliary_register_0 == old_auxiliary_register_0,
        {name, " operand stall preserves unrelated architectural state"}
      );
    end
    clock_enable = 1'b1;

    advance_to_sample(name);
    require(
      sample &&
      !retired &&
      !illegal &&
      execute_address == 12'h001 &&
      execute_word == 16'hf600 &&
      program_address == expected_selected_address &&
      pc == 12'h002 &&
      cycle_count == 32'd2 &&
      !data_read &&
      !data_write &&
      !data_address_valid &&
      !pipeline_blocked,
      {name, " operand boundary samples live BIO and selects cycle 2"}
    );
    require(
      accumulator == 32'h0000_00a5 &&
      auxiliary_register_0 == old_auxiliary_register_0,
      {name, " operand completion preserves unrelated architectural state"}
    );

    // Once cycle 2's address is selected, later BIO changes cannot redirect
    // the active fetch or change the decision committed at retirement.
    bio = !decision_bio;
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
        !sample &&
        !retired,
        {name, " selected-fetch stall holds the sampled BIO decision"}
      );
      require(
        accumulator == 32'h0000_00a5 &&
        auxiliary_register_0 == old_auxiliary_register_0,
        {name, " selected-fetch stall preserves architectural state"}
      );
    end
    clock_enable = 1'b1;

    advance_to_sample(name);
    require(
      retired &&
      !illegal &&
      execute_address == expected_selected_address &&
      execute_word == expected_selected_word &&
      program_address == expected_selected_address + 12'h001 &&
      pc == expected_selected_address &&
      cycle_count == 32'd3 &&
      !pipeline_blocked,
      {name, " selected fetch retires BIOZ using the sampled decision"}
    );
    require(
      accumulator == 32'h0000_00a5 &&
      auxiliary_register_0 == old_auxiliary_register_0,
      {name, " BIOZ retirement preserves unrelated architectural state"}
    );

    advance_to_sample(name);
    require(
      retired &&
      !illegal &&
      auxiliary_register_0 ==
        (!decision_bio ? 16'h0042 : 16'h0031) &&
      accumulator == 32'h0000_00a5 &&
      pc == expected_selected_address + 12'h001 &&
      cycle_count == 32'd4,
      {name, " selected instruction executes in the following interval"}
    );
  endtask

  task automatic reject_noncanonical_target;
    program_memory[0] = 16'hf600;
    program_memory[1] = 16'hf123;
    reset_case(1'b0, "malformed BIOZ");

    advance_to_sample("malformed BIOZ");
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'hf600 &&
      program_address == 12'h001 &&
      pc == 12'h000 &&
      cycle_count == 32'd0 &&
      !pipeline_blocked,
      "malformed case primes BIOZ before reading its operand"
    );

    advance_to_sample("malformed BIOZ");
    require(
      !retired &&
      !illegal &&
      execute_address == 12'h000 &&
      execute_word == 16'hf600 &&
      program_address == 12'h001 &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      pipeline_blocked,
      "malformed BIOZ parks before a condition-selected speculative fetch"
    );
    bio = 1'b1;
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
        "malformed BIOZ remains parked when BIO changes"
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
    bio          = 1'b1;

    run_case(1'b0, "taken BIOZ");
    run_case(1'b1, "untaken BIOZ");
    reject_noncanonical_target();

    $display("PASS tb_sequential_pipeline_bioz");
    $finish;
  end
endmodule

`default_nettype wire
