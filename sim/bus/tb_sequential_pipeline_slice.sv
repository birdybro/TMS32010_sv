`default_nettype none

module tb_sequential_pipeline_slice;
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
  logic [15:0] auxiliary_register_1;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_sequential_pipeline_slice dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .rs_i                          (rs),
    .clock_enable_i                (clock_enable),
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
    .auxiliary_register_1_o        (auxiliary_register_1),
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
    program_memory[0] = 16'h7012;  // LARK AR0,0x12
    program_memory[1] = 16'h7134;  // LARK AR1,0x34
    program_memory[2] = 16'h7ea5;  // LACK 0xa5
    program_memory[3] = 16'h7f80;  // NOP
    program_memory[4] = 16'hf600;  // BIOZ: valid, but outside this slice
    program_memory[5] = 16'h0123;  // branch operand must not execute

    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;

    repeat (20) begin
      tick();
      require(!bus_active && men_n, "reset keeps program bus inactive");
      require(!execute_valid && !retired, "reset keeps execute slot empty");
    end

    rs = 1'b0;
    advance_to_sample();
    require(sample && !retired, "first fetch primes without retirement");
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'h7012,
      "address-zero word enters the execute slot"
    );
    require(
      pc == 12'h000 &&
      program_address == 12'h001 &&
      cycle_count == 32'd0,
      "fetch PC advances independently while execute PC remains at zero"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n &&
      execute_address == 12'h000 &&
      pc == 12'h000,
      "next fetch overlaps ownership of instruction zero"
    );
    clock_enable = 1'b0;
    repeat (4) begin
      tick();
      require(
        phase == 2'd1 &&
        program_address == 12'h001 &&
        execute_address == 12'h000 &&
        pc == 12'h000,
        "clock-enable stall holds distinct fetch and execute addresses"
      );
      require(!sample && !retired, "stall cannot sample or retire");
    end
    clock_enable = 1'b1;

    advance_to_sample();
    require(
      sample && retired &&
      auxiliary_register_0 == 16'h0012 &&
      pc == 12'h001 &&
      cycle_count == 32'd1,
      "second fetch boundary retires instruction zero"
    );
    require(
      execute_address == 12'h001 &&
      execute_word == 16'h7134 &&
      program_address == 12'h002,
      "fetch one becomes execute while bus advances to fetch two"
    );

    advance_to_sample();
    require(
      retired &&
      auxiliary_register_1 == 16'h0034 &&
      pc == 12'h002 &&
      execute_address == 12'h002 &&
      program_address == 12'h003,
      "third fetch boundary retires instruction one with one-cycle overlap"
    );

    advance_to_sample();
    require(
      retired &&
      accumulator == 32'h0000_00a5 &&
      pc == 12'h003 &&
      execute_address == 12'h003 &&
      program_address == 12'h004,
      "LACK consumes execute word two while fetch owns address four"
    );

    advance_to_sample();
    require(
      retired &&
      pc == 12'h004 &&
      cycle_count == 32'd4 &&
      execute_address == 12'h004 &&
      execute_word == 16'hf600 &&
      program_address == 12'h005,
      "NOP retires while unsupported BIOZ enters execute ownership"
    );
    require(
      pipeline_blocked && !illegal,
      "unsupported multicycle word parks before timing is invented"
    );

    repeat (8) begin
      tick();
      require(
        phase == 2'd0 &&
        program_address == 12'h005 &&
        execute_address == 12'h004 &&
        pc == 12'h004 &&
        cycle_count == 32'd4,
        "blocked slice parks fetch, execute, and architectural ownership"
      );
      require(
        pipeline_blocked && men_n && !sample && !retired && !illegal,
        "blocked slice cannot access or retire the BIOZ operand"
      );
      require(accumulator == 32'h0000_00a5,
              "parked BIOZ operand cannot affect the accumulator");
    end

    rs = 1'b1;
    repeat (4) begin
      tick();
    end
    require(
      !pipeline_blocked &&
      !execute_valid &&
      !bus_active &&
      pc == 12'h000 &&
      cycle_count == 32'd0,
      "recognized reset recovers a parked pipeline and empties ownership"
    );

    $display("PASS tb_sequential_pipeline_slice");
    $finish;
  end
endmodule

`default_nettype wire
