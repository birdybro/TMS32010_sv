`default_nettype none

module tb_sequential_pipeline_b;
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
    .data_read_o                   (),
    .data_write_o                  (),
    .data_address_valid_o          (),
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

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7ea5;  // LACK 0xa5
    program_memory[1] = 16'hf900;  // B
    program_memory[2] = 16'h0005;  // canonical target
    program_memory[3] = 16'h7f89;  // skipped ZAC
    program_memory[4] = 16'h7f8b;  // skipped SOVM
    program_memory[5] = 16'h702a;  // LARK AR0,0x2a
    program_memory[6] = 16'h7f80;  // NOP

    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;

    repeat (20) begin
      tick();
      require(!bus_active && men_n, "reset keeps program bus inactive");
    end

    rs = 1'b0;
    advance_to_sample();
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'h7ea5 &&
      !retired &&
      cycle_count == 32'd0,
      "first fetch primes the one-cycle predecessor"
    );

    advance_to_sample();
    require(
      retired &&
      accumulator == 32'h0000_00a5 &&
      execute_address == 12'h001 &&
      execute_word == 16'hf900 &&
      program_address == 12'h002 &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      !pipeline_blocked,
      "predecessor retires while B prefetch becomes execute ownership"
    );

    advance_to_sample();
    require(
      sample &&
      !retired &&
      execute_address == 12'h001 &&
      execute_word == 16'hf900 &&
      program_address == 12'h005 &&
      pc == 12'h002 &&
      cycle_count == 32'd2 &&
      !pipeline_blocked,
      "operand fetch completes B cycle one without becoming executable"
    );
    require(
      auxiliary_register_0 == 16'h0000,
      "target instruction has not executed during operand fetch"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n &&
      program_address == 12'h005 &&
      execute_address == 12'h001,
      "B retains execute ownership while target fetch is active"
    );
    clock_enable = 1'b0;
    repeat (3) begin
      tick();
      require(
        phase == 2'd1 &&
        !men_n &&
        program_address == 12'h005 &&
        execute_address == 12'h001 &&
        pc == 12'h002 &&
        cycle_count == 32'd2 &&
        !sample &&
        !retired,
        "target-fetch stall holds branch, bus, PC, and cycle ownership"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample();
    require(
      sample &&
      retired &&
      execute_address == 12'h005 &&
      execute_word == 16'h702a &&
      program_address == 12'h006 &&
      pc == 12'h005 &&
      cycle_count == 32'd3 &&
      auxiliary_register_0 == 16'h0000 &&
      !pipeline_blocked &&
      !illegal,
      "target fetch retires B and only primes the target instruction"
    );

    advance_to_sample();
    require(
      retired &&
      execute_address == 12'h006 &&
      program_address == 12'h007 &&
      pc == 12'h006 &&
      cycle_count == 32'd4 &&
      auxiliary_register_0 == 16'h002a,
      "target instruction executes during the following fetch"
    );

    rs = 1'b1;
    repeat (12) begin
      tick();
    end
    require(
      !bus_active &&
      !execute_valid &&
      pc == 12'h000 &&
      cycle_count == 32'd0,
      "recognized reset empties branch and fetch ownership"
    );

    program_memory[0] = 16'hf900;  // B
    program_memory[1] = 16'hf123;  // malformed upper nibble
    rs = 1'b0;
    advance_to_sample();
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'hf900 &&
      program_address == 12'h001 &&
      !pipeline_blocked,
      "malformed case still primes the exact B opcode"
    );

    advance_to_sample();
    require(
      !retired &&
      execute_address == 12'h000 &&
      execute_word == 16'hf900 &&
      program_address == 12'h001 &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      pipeline_blocked &&
      !illegal,
      "malformed operand parks before an unsupported speculative fetch"
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
        "malformed B remains visibly parked without another bus cycle"
      );
    end

    $display("PASS tb_sequential_pipeline_b");
    $finish;
  end
endmodule

`default_nettype wire
