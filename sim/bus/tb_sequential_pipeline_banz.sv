`default_nettype none

module tb_sequential_pipeline_banz;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic [15:0] program_data;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
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
  logic [11:0] pc;
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
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
    .debug_data_address_i          (debug_data_address),
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
    .data_read_o                   (),
    .data_write_o                  (),
    .data_address_valid_o          (),
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
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
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

  task automatic advance_to_sample;
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require(clkout == phase[1], "CLKOUT follows phase encoding");
      if (sample) begin
        return;
      end
    end
    $fatal(1, "sample event did not arrive");
  endtask

  task automatic preload_data(
    input logic [7:0] address,
    input logic [15:0] value
  );
    debug_data_write   = 1'b1;
    debug_data_address = address;
    debug_data         = value;
    tick();
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h3800;  // LAR AR0,0: zero low-nine counter
    program_memory[1]  = 16'hf400;  // untaken BANZ
    program_memory[2]  = 16'h0100;  // canonical but unselected target
    program_memory[3]  = 16'h3901;  // fallthrough: LAR AR1,1
    program_memory[4]  = 16'h6881;  // LARP 1
    program_memory[5]  = 16'hf400;  // taken BANZ
    program_memory[6]  = 16'h0008;  // canonical target
    program_memory[7]  = 16'h7f89;  // skipped ZAC
    program_memory[8]  = 16'h702a;  // target: LARK AR0,0x2a
    program_memory[9]  = 16'hf400;  // malformed BANZ
    program_memory[10] = 16'hf123;  // malformed upper nibble

    initialize         = 1'b1;
    rs                 = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    preload_data(8'h00, 16'ha400);
    preload_data(8'h01, 16'hbe01);
    debug_data_write = 1'b0;
    initialize       = 1'b0;

    repeat (20) begin
      tick();
      require(!bus_active && men_n, "reset keeps program bus inactive");
    end

    rs = 1'b0;
    advance_to_sample();
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'h3800 &&
      !retired &&
      cycle_count == 32'd0,
      "first fetch primes the AR0 setup instruction"
    );

    advance_to_sample();
    require(
      retired &&
      auxiliary_register_0 == 16'ha400 &&
      execute_address == 12'h001 &&
      execute_word == 16'hf400 &&
      program_address == 12'h002 &&
      pc == 12'h001 &&
      cycle_count == 32'd1,
      "setup retires while untaken BANZ enters execute ownership"
    );

    advance_to_sample();
    require(
      sample &&
      !retired &&
      execute_address == 12'h001 &&
      execute_word == 16'hf400 &&
      program_address == 12'h003 &&
      pc == 12'h002 &&
      cycle_count == 32'd2 &&
      auxiliary_register_0 == 16'ha400 &&
      !pipeline_blocked,
      "zero old counter selects fallthrough without an early decrement"
    );

    advance_to_sample();
    require(
      retired &&
      execute_address == 12'h003 &&
      execute_word == 16'h3901 &&
      program_address == 12'h004 &&
      pc == 12'h003 &&
      cycle_count == 32'd3 &&
      auxiliary_register_0 == 16'ha5ff &&
      auxiliary_register_1 == 16'h0000,
      "fallthrough fetch retires BANZ, wraps nine bits, and only primes LAR"
    );

    advance_to_sample();
    require(
      retired &&
      auxiliary_register_1 == 16'hbe01 &&
      execute_address == 12'h004 &&
      pc == 12'h004 &&
      cycle_count == 32'd4,
      "fallthrough instruction executes in the following interval"
    );
    advance_to_sample();
    require(
      retired &&
      auxiliary_register_pointer &&
      execute_address == 12'h005 &&
      execute_word == 16'hf400 &&
      pc == 12'h005 &&
      cycle_count == 32'd5,
      "LARP selects the nonzero AR1 before taken BANZ ownership"
    );

    advance_to_sample();
    require(
      sample &&
      !retired &&
      execute_address == 12'h005 &&
      execute_word == 16'hf400 &&
      program_address == 12'h008 &&
      pc == 12'h006 &&
      cycle_count == 32'd6 &&
      auxiliary_register_1 == 16'hbe01,
      "nonzero old counter selects target without an early decrement"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n &&
      program_address == 12'h008 &&
      execute_address == 12'h005,
      "BANZ retains execute ownership while the selected fetch is active"
    );
    clock_enable = 1'b0;
    repeat (3) begin
      tick();
      require(
        phase == 2'd1 &&
        !men_n &&
        program_address == 12'h008 &&
        execute_address == 12'h005 &&
        pc == 12'h006 &&
        cycle_count == 32'd6 &&
        auxiliary_register_1 == 16'hbe01 &&
        !sample &&
        !retired,
        "selected-fetch stall holds condition, bus, PC, and execute ownership"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample();
    require(
      retired &&
      execute_address == 12'h008 &&
      execute_word == 16'h702a &&
      program_address == 12'h009 &&
      pc == 12'h008 &&
      cycle_count == 32'd7 &&
      auxiliary_register_1 == 16'hbe00 &&
      auxiliary_register_0 == 16'ha5ff &&
      !pipeline_blocked &&
      !illegal,
      "target fetch retires BANZ, decrements AR1, and only primes target"
    );

    advance_to_sample();
    require(
      retired &&
      auxiliary_register_0 == 16'h002a &&
      execute_address == 12'h009 &&
      execute_word == 16'hf400 &&
      pc == 12'h009 &&
      cycle_count == 32'd8,
      "target instruction executes before the next BANZ takes ownership"
    );

    advance_to_sample();
    require(
      !retired &&
      execute_address == 12'h009 &&
      execute_word == 16'hf400 &&
      program_address == 12'h00a &&
      pc == 12'h00a &&
      cycle_count == 32'd9 &&
      auxiliary_register_1 == 16'hbe00 &&
      pipeline_blocked &&
      !illegal,
      "malformed operand parks before decrement or another bus transaction"
    );
    repeat (4) begin
      tick();
      require(
        phase == 2'd0 &&
        program_address == 12'h00a &&
        execute_address == 12'h009 &&
        pc == 12'h00a &&
        cycle_count == 32'd9 &&
        auxiliary_register_1 == 16'hbe00 &&
        pipeline_blocked &&
        !sample &&
        !retired,
        "malformed BANZ remains visibly parked without counter mutation"
      );
    end

    $display("PASS tb_sequential_pipeline_banz");
    $finish;
  end
endmodule

`default_nettype wire
