`default_nettype none

module tb_sequential_pipeline_interrupt;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic        int_n;
  logic [15:0] program_data;
  logic [1:0]  phase;
  logic        clkout;
  logic [11:0] program_address;
  logic        men_n;
  logic        den_n;
  logic        we_n;
  logic        sample;
  logic        bus_active;
  logic        execute_valid;
  logic [11:0] execute_address;
  logic [15:0] execute_word;
  logic        pipeline_blocked;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [11:0] stack_top;
  logic        interrupt_mask;
  logic        interrupt_pending;
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
    .int_i                         (int_n),
    .program_data_i                (program_data),
    .io_read_data_i                (16'h0000),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .program_address_o             (program_address),
    .men_n_o                       (men_n),
    .den_n_o                       (den_n),
    .we_n_o                        (we_n),
    .program_write_o               (),
    .program_write_data_o          (),
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
    .accumulator_o                 (accumulator),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (interrupt_mask),
    .interrupt_pending_o           (interrupt_pending),
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
      require(
        !(
          (!men_n && !den_n) ||
          (!men_n && !we_n) ||
          (!den_n && !we_n)
        ),
        {name, " native strobes remain mutually exclusive"}
      );
      if (sample) begin
        return;
      end
    end
    $fatal(1, "%s sample event did not arrive", name);
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]       = 16'hf900;  // B
    program_memory[1]       = 16'h0100;  // target
    program_memory[2]       = 16'h7e5a;  // vector LACK 0x5a
    program_memory[3]       = 16'h7f80;  // instruction after vector
    program_memory[12'h100] = 16'h7f82;  // EINT
    program_memory[12'h101] = 16'h7e2a;  // protected LACK 0x2a
    program_memory[12'h102] = 16'h7f89;  // dummy-fetched ZAC

    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    int_n        = 1'b1;
    tick();
    initialize = 1'b0;
    repeat (20) begin
      tick();
      require(
        !bus_active && men_n && den_n && we_n,
        "reset keeps every native strobe inactive"
      );
    end
    rs = 1'b0;

    advance_to_sample("B prefetch");
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'hf900 &&
      !retired && cycle_count == 32'd0 &&
      program_address == 12'h001,
      "first fetch primes B without execution"
    );

    int_n = 1'b0;
    advance_to_sample("B operand");
    int_n = 1'b1;
    require(
      execute_address == 12'h000 &&
      !retired &&
      interrupt_pending && interrupt_mask &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      program_address == 12'h100,
      "masked request is retained while B selects its target"
    );

    advance_to_sample("B target");
    require(
      retired &&
      execute_address == 12'h100 &&
      execute_word == 16'h7f82 &&
      interrupt_pending && interrupt_mask &&
      pc == 12'h100 &&
      cycle_count == 32'd2 &&
      program_address == 12'h101,
      "B retires and captures EINT before pending service"
    );

    advance_to_sample("EINT");
    require(
      retired &&
      execute_address == 12'h101 &&
      execute_word == 16'h7e2a &&
      interrupt_pending && !interrupt_mask &&
      pc == 12'h101 &&
      accumulator == 32'h0000_0000 &&
      cycle_count == 32'd3 &&
      program_address == 12'h102,
      "EINT retires and captures exactly one protected instruction"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n &&
      program_address == 12'h102 &&
      execute_address == 12'h101,
      "protected instruction overlaps the ordinary dummy fetch"
    );
    clock_enable = 1'b0;
    repeat (3) begin
      tick();
      require(
        phase == 2'd1 &&
        !men_n && den_n && we_n &&
        program_address == 12'h102 &&
        execute_address == 12'h101 &&
        accumulator == 32'h0000_0000 &&
        !retired &&
        cycle_count == 32'd3,
        "dummy-fetch stall cannot retire the protected instruction early"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("protected instruction");
    require(
      retired &&
      !illegal &&
      !execute_valid &&
      accumulator == 32'h0000_002a &&
      pc == 12'h102 &&
      cycle_count == 32'd4 &&
      interrupt_pending && !interrupt_mask &&
      stack_top == 12'h000 &&
      program_address == 12'h002 &&
      !pipeline_blocked,
      "protected instruction retires while N+2 is discarded as a dummy"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n &&
      program_address == 12'h002 &&
      !execute_valid,
      "vector fetch overlaps a nonexecuting interrupt-entry cycle"
    );
    clock_enable = 1'b0;
    repeat (2) begin
      tick();
      require(
        phase == 2'd1 &&
        program_address == 12'h002 &&
        !men_n && den_n && we_n &&
        !execute_valid &&
        stack_top == 12'h000 &&
        pc == 12'h102 &&
        cycle_count == 32'd4 &&
        !retired,
        "vector-fetch stall cannot acknowledge or push early"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("vector fetch");
    require(
      !retired &&
      !illegal &&
      execute_valid &&
      execute_address == 12'h002 &&
      execute_word == 16'h7e5a &&
      accumulator == 32'h0000_002a &&
      stack_top == 12'h102 &&
      pc == 12'h002 &&
      cycle_count == 32'd5 &&
      !interrupt_pending && interrupt_mask &&
      program_address == 12'h003,
      "entry pushes return PC and captures vector without executing it"
    );

    advance_to_sample("vector execution");
    require(
      retired &&
      !illegal &&
      execute_address == 12'h003 &&
      accumulator == 32'h0000_005a &&
      stack_top == 12'h102 &&
      pc == 12'h003 &&
      cycle_count == 32'd6,
      "vector executes only in the following fetch interval"
    );

    $display("PASS tb_sequential_pipeline_interrupt");
    $finish;
  end
endmodule

`default_nettype wire
