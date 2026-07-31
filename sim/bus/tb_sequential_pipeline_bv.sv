`default_nettype none

module tb_sequential_pipeline_bv;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic [15:0] program_data;
  logic        debug_data_write;
  logic [15:0] debug_data;
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
  logic [15:0] auxiliary_register_0;
  logic        overflow_flag;
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
    .debug_data_i                  (debug_data),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .program_address_o             (program_address),
    .men_n_o                       (men_n),
    .den_n_o                       (),
    .we_n_o                        (),
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
    .accumulator_o                 (),
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
    .overflow_flag_o               (overflow_flag),
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

  task automatic reset_case(
    input logic  status_overflow,
    input string name
  );
    initialize       = 1'b1;
    rs               = 1'b1;
    clock_enable     = 1'b1;
    debug_data       = status_overflow ? 16'h8000 : 16'h0000;
    debug_data_write = 1'b1;
    tick();
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    repeat (20) begin
      tick();
      require(!bus_active && men_n, {name, " reset keeps bus inactive"});
    end
    rs = 1'b0;
  endtask

  task automatic run_case(
    input logic  status_overflow,
    input string name
  );
    logic [11:0] expected_selected_address;
    logic [15:0] expected_selected_word;
    logic [15:0] old_auxiliary_register_0;

    expected_selected_address = status_overflow ? 12'h004 : 12'h003;
    expected_selected_word = status_overflow ? 16'h7042 : 16'h7031;

    program_memory[0] = 16'h7b00;  // LST 0 establishes OV.
    program_memory[1] = 16'hf500;  // BV
    program_memory[2] = 16'h0004;  // canonical target
    program_memory[3] = 16'h7031;  // fallthrough effect
    program_memory[4] = 16'h7042;  // target effect
    program_memory[5] = 16'h7f80;

    reset_case(status_overflow, name);

    advance_to_sample(name);
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'h7b00 &&
      !retired &&
      cycle_count == 32'd0,
      {name, " first fetch only primes LST"}
    );

    advance_to_sample(name);
    old_auxiliary_register_0 = auxiliary_register_0;
    require(
      retired &&
      !illegal &&
      overflow_flag == status_overflow &&
      execute_address == 12'h001 &&
      execute_word == 16'hf500 &&
      program_address == 12'h002 &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      !pipeline_blocked,
      {name, " LST retires while BV takes execute ownership"}
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n &&
      program_address == 12'h002 &&
      execute_address == 12'h001,
      {name, " BV operand has an active MEN phase"}
    );
    clock_enable = 1'b0;
    repeat (3) begin
      tick();
      require(
        phase == 2'd1 &&
        !men_n &&
        program_address == 12'h002 &&
        execute_address == 12'h001 &&
        pc == 12'h001 &&
        cycle_count == 32'd1 &&
        overflow_flag == status_overflow &&
        auxiliary_register_0 == old_auxiliary_register_0 &&
        !sample &&
        !retired,
        {name, " operand-fetch stall holds old OV and execute ownership"}
      );
    end
    clock_enable = 1'b1;

    advance_to_sample(name);
    require(
      sample &&
      !retired &&
      !illegal &&
      overflow_flag == status_overflow &&
      execute_address == 12'h001 &&
      execute_word == 16'hf500 &&
      program_address == expected_selected_address &&
      pc == 12'h002 &&
      cycle_count == 32'd2 &&
      auxiliary_register_0 == old_auxiliary_register_0 &&
      !data_read &&
      !data_write &&
      !data_address_valid &&
      !pipeline_blocked,
      {name, " operand selects from old OV without clearing it"}
    );

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
        overflow_flag == status_overflow &&
        auxiliary_register_0 == old_auxiliary_register_0 &&
        !sample &&
        !retired,
        {name, " selected-fetch stall holds OV and execute ownership"}
      );
    end
    clock_enable = 1'b1;

    advance_to_sample(name);
    require(
      retired &&
      !illegal &&
      !overflow_flag &&
      execute_address == expected_selected_address &&
      execute_word == expected_selected_word &&
      program_address == expected_selected_address + 12'h001 &&
      pc == expected_selected_address &&
      cycle_count == 32'd3 &&
      auxiliary_register_0 == old_auxiliary_register_0 &&
      !pipeline_blocked,
      {name, " selected fetch retires BV, resolves OV, and only primes"}
    );

    advance_to_sample(name);
    require(
      retired &&
      !illegal &&
      !overflow_flag &&
      auxiliary_register_0 ==
        (status_overflow ? 16'h0042 : 16'h0031) &&
      pc == expected_selected_address + 12'h001 &&
      cycle_count == 32'd4,
      {name, " selected instruction executes in following interval"}
    );
  endtask

  task automatic reject_noncanonical_target;
    program_memory[0] = 16'h7b00;
    program_memory[1] = 16'hf500;
    program_memory[2] = 16'hf123;
    reset_case(1'b1, "malformed BV");

    advance_to_sample("malformed BV");
    advance_to_sample("malformed BV");
    require(
      retired &&
      overflow_flag &&
      execute_address == 12'h001 &&
      execute_word == 16'hf500 &&
      program_address == 12'h002 &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      !pipeline_blocked,
      "malformed case establishes OV and BV ownership"
    );

    advance_to_sample("malformed BV");
    require(
      !retired &&
      !illegal &&
      overflow_flag &&
      execute_address == 12'h001 &&
      execute_word == 16'hf500 &&
      program_address == 12'h002 &&
      pc == 12'h002 &&
      cycle_count == 32'd2 &&
      pipeline_blocked,
      "malformed BV parks before OV clear or speculative fetch"
    );
    repeat (4) begin
      tick();
      require(
        phase == 2'd0 &&
        program_address == 12'h002 &&
        execute_address == 12'h001 &&
        pc == 12'h002 &&
        cycle_count == 32'd2 &&
        overflow_flag &&
        pipeline_blocked &&
        !sample &&
        !retired,
        "malformed BV remains parked with OV set"
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
    debug_data_write = 1'b0;
    debug_data       = 16'h0000;

    run_case(1'b1, "taken BV");
    run_case(1'b0, "untaken BV");
    reject_noncanonical_target();

    $display("PASS tb_sequential_pipeline_bv");
    $finish;
  end
endmodule

`default_nettype wire
