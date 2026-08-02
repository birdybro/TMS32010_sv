`default_nettype none

module tb_sequential_pipeline_interrupt_mask_controls;
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
  logic        program_write;
  logic        sample;
  logic        bus_active;
  logic        execute_valid;
  logic [11:0] execute_address;
  logic [15:0] execute_word;
  logic        pipeline_blocked;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic        io_read;
  logic        io_write;
  logic [11:0] pc;
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
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
    .program_write_o               (program_write),
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
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (),
    .pc_o                          (pc),
    .accumulator_o                 (),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
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

  task automatic require_exclusive_strobes(input string name);
    require(clkout == phase[1], {name, " CLKOUT follows phase"});
    require(
      !(
        (!men_n && !den_n) ||
        (!men_n && !we_n) ||
        (!den_n && !we_n)
      ),
      {name, " native strobes are exclusive"}
    );
  endtask

  task automatic advance_to_sample(input string name);
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require_exclusive_strobes(name);
      if (sample) begin
        return;
      end
    end
    $fatal(1, "%s sample did not arrive", name);
  endtask

  task automatic clear_program;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
  endtask

  task automatic initialize_pipeline(input string name);
    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    int_n        = 1'b1;
    tick();
    initialize = 1'b0;
    repeat (20) begin
      tick();
      require(
        !bus_active && men_n && den_n && we_n && !program_write,
        {name, " reset keeps the native bus inactive"}
      );
    end
    rs = 1'b0;
  endtask

  task automatic require_program_only_active(
    input logic [11:0] expected_program_address,
    input logic [11:0] expected_execute_address,
    input logic [15:0] expected_execute_word,
    input string name
  );
    require(
      phase == 2'd1 && bus_active &&
      !men_n && den_n && we_n && !program_write &&
      program_address == expected_program_address &&
      execute_valid && execute_address == expected_execute_address &&
      execute_word == expected_execute_word && !pipeline_blocked,
      {name, " owns an ordinary active MEN read"}
    );
    require(
      !data_read && !data_write && !data_address_valid &&
      !io_read && !io_write,
      {name, " remains program-only"}
    );
  endtask

  task automatic require_vector_capture(
    input logic [11:0] expected_return_pc,
    input logic [15:0] expected_vector_word,
    input logic [31:0] expected_cycles,
    input string name
  );
    require(
      !retired && !illegal && execute_valid &&
      execute_address == 12'h002 && execute_word == expected_vector_word &&
      pc == 12'h002 && stack_top == expected_return_pc &&
      stack_level_1 == 12'h000 && stack_level_2 == 12'h000 &&
      stack_bottom == 12'h000 && interrupt_mask &&
      !interrupt_pending && cycle_count == expected_cycles,
      {name, " captures vector 2 only after acknowledge"}
    );
  endtask

  task automatic run_request_during_eint;
    clear_program();
    program_memory[12'h000] = 16'h7f82;  // EINT samples request
    program_memory[12'h001] = 16'h7155;  // protected LARK AR1,0x55
    program_memory[12'h002] = 16'h7f80;  // vector word and return-PC dummy
    initialize_pipeline("request-during-EINT");

    advance_to_sample("request-during-EINT prefetch");
    require(
      execute_valid && execute_address == 12'h000 &&
      execute_word == 16'h7f82 && !retired && cycle_count == 32'd0,
      "request-during-EINT primes EINT"
    );

    int_n = 1'b0;
    tick();
    require_exclusive_strobes("request-during-EINT active");
    require_program_only_active(
      12'h001,
      12'h000,
      16'h7f82,
      "request-during-EINT"
    );
    advance_to_sample("request-during-EINT execution");
    int_n = 1'b1;
    require(
      retired && !illegal && execute_valid &&
      execute_address == 12'h001 && execute_word == 16'h7155 &&
      pc == 12'h001 && !interrupt_mask && interrupt_pending &&
      cycle_count == 32'd1 && program_address == 12'h002,
      "request-during-EINT arms exactly one following instruction"
    );

    advance_to_sample("request-during-EINT protected");
    require(
      retired && !execute_valid && auxiliary_register_1 == 16'h0055 &&
      pc == 12'h002 && !interrupt_mask && interrupt_pending &&
      cycle_count == 32'd2 && program_address == 12'h002,
      "request-during-EINT discards the return-PC word after protection"
    );
    advance_to_sample("request-during-EINT vector");
    require_vector_capture(
      12'h002,
      16'h7f80,
      32'd3,
      "request-during-EINT"
    );
  endtask

  task automatic run_request_during_dint;
    clear_program();
    program_memory[12'h000] = 16'h7f82;  // establish unmasked state
    program_memory[12'h001] = 16'h7f81;  // DINT samples request
    program_memory[12'h002] = 16'h7022;  // ordinary masked LARK AR0,0x22
    program_memory[12'h003] = 16'h7f82;  // re-enable retained request
    program_memory[12'h004] = 16'h7155;  // protected LARK AR1,0x55
    program_memory[12'h005] = 16'h7f89;  // return-PC dummy
    initialize_pipeline("request-during-DINT");

    advance_to_sample("request-during-DINT prefetch");
    advance_to_sample("request-during-DINT initial EINT");
    require(
      retired && execute_valid && execute_address == 12'h001 &&
      execute_word == 16'h7f81 && !interrupt_mask && !interrupt_pending &&
      cycle_count == 32'd1,
      "request-during-DINT begins unmasked"
    );

    int_n = 1'b0;
    tick();
    require_exclusive_strobes("request-during-DINT active");
    require_program_only_active(
      12'h002,
      12'h001,
      16'h7f81,
      "request-during-DINT"
    );
    advance_to_sample("request-during-DINT execution");
    int_n = 1'b1;
    require(
      retired && !illegal && execute_valid &&
      execute_address == 12'h002 && execute_word == 16'h7022 &&
      pc == 12'h002 && interrupt_mask && interrupt_pending &&
      cycle_count == 32'd2 && program_address == 12'h003,
      "request-during-DINT masks service but retains and advances normally"
    );

    advance_to_sample("request-during-DINT masked LARK");
    require(
      retired && execute_valid && execute_address == 12'h003 &&
      execute_word == 16'h7f82 && auxiliary_register_0 == 16'h0022 &&
      pc == 12'h003 && interrupt_mask && interrupt_pending &&
      cycle_count == 32'd3,
      "request-during-DINT leaves the next masked word executable"
    );
    advance_to_sample("request-during-DINT re-enable");
    require(
      retired && execute_valid && execute_address == 12'h004 &&
      execute_word == 16'h7155 && !interrupt_mask && interrupt_pending &&
      cycle_count == 32'd4,
      "request-during-DINT re-enable protects one following word"
    );
    advance_to_sample("request-during-DINT protected");
    require(
      retired && !execute_valid && auxiliary_register_1 == 16'h0055 &&
      pc == 12'h005 && !interrupt_mask && interrupt_pending &&
      cycle_count == 32'd5 && program_address == 12'h002,
      "request-during-DINT eventually reaches dummy ownership"
    );
    advance_to_sample("request-during-DINT vector");
    require_vector_capture(
      12'h005,
      16'h7022,
      32'd6,
      "request-during-DINT"
    );
  endtask

  task automatic run_eint_in_protected_slot;
    clear_program();
    program_memory[12'h000] = 16'h7f82;  // establish unmasked state
    program_memory[12'h001] = 16'h7f80;  // request-sampling NOP
    program_memory[12'h002] = 16'h7f82;  // redundant protected EINT/vector
    program_memory[12'h003] = 16'h7f89;  // return-PC dummy
    initialize_pipeline("protected-EINT");

    advance_to_sample("protected-EINT prefetch");
    advance_to_sample("protected-EINT initial EINT");
    int_n = 1'b0;
    advance_to_sample("protected-EINT request NOP");
    int_n = 1'b1;
    require(
      retired && execute_valid && execute_address == 12'h002 &&
      execute_word == 16'h7f82 && !interrupt_mask && interrupt_pending &&
      cycle_count == 32'd2,
      "protected-EINT reaches an already-unmasked protected slot"
    );

    tick();
    require_exclusive_strobes("protected-EINT active");
    require_program_only_active(
      12'h003,
      12'h002,
      16'h7f82,
      "protected-EINT"
    );
    advance_to_sample("protected-EINT execution");
    require(
      retired && !execute_valid && pc == 12'h003 &&
      !interrupt_mask && interrupt_pending && cycle_count == 32'd3 &&
      program_address == 12'h002,
      "protected-EINT does not add a second deferral interval"
    );
    advance_to_sample("protected-EINT vector");
    require_vector_capture(
      12'h003,
      16'h7f82,
      32'd4,
      "protected-EINT"
    );
  endtask

  task automatic run_dint_in_protected_slot_provisional;
    clear_program();
    program_memory[12'h000] = 16'h7f82;  // establish unmasked state
    program_memory[12'h001] = 16'h7f80;  // request-sampling NOP
    program_memory[12'h002] = 16'h7f81;  // protected DINT and vector word
    program_memory[12'h003] = 16'h7033;  // ordinary masked LARK AR0,0x33
    program_memory[12'h004] = 16'h7f82;  // re-enable retained request
    program_memory[12'h005] = 16'h7155;  // protected LARK AR1,0x55
    program_memory[12'h006] = 16'h7f89;  // return-PC dummy
    initialize_pipeline("protected-DINT-PROVISIONAL");

    advance_to_sample("protected-DINT prefetch");
    advance_to_sample("protected-DINT initial EINT");
    int_n = 1'b0;
    advance_to_sample("protected-DINT request NOP");
    int_n = 1'b1;
    require(
      retired && execute_valid && execute_address == 12'h002 &&
      execute_word == 16'h7f81 && !interrupt_mask && interrupt_pending &&
      cycle_count == 32'd2,
      "protected-DINT reaches the unresolved OQ-019 boundary"
    );

    tick();
    require_exclusive_strobes("protected-DINT active");
    require_program_only_active(
      12'h003,
      12'h002,
      16'h7f81,
      "protected-DINT-PROVISIONAL"
    );
    advance_to_sample("protected-DINT execution");
    require(
      retired && execute_valid && execute_address == 12'h003 &&
      execute_word == 16'h7033 && pc == 12'h003 &&
      interrupt_mask && interrupt_pending && cycle_count == 32'd3 &&
      program_address == 12'h004,
      "PROVISIONAL protected-DINT policy cancels entry and keeps request"
    );

    advance_to_sample("protected-DINT masked LARK");
    require(
      retired && execute_valid && execute_address == 12'h004 &&
      execute_word == 16'h7f82 && auxiliary_register_0 == 16'h0033 &&
      interrupt_mask && interrupt_pending && cycle_count == 32'd4,
      "PROVISIONAL protected-DINT policy continues masked execution"
    );
    advance_to_sample("protected-DINT re-enable");
    require(
      retired && execute_valid && execute_address == 12'h005 &&
      execute_word == 16'h7155 && !interrupt_mask && interrupt_pending &&
      cycle_count == 32'd5,
      "protected-DINT retained request is eligible after EINT"
    );
    advance_to_sample("protected-DINT following protection");
    require(
      retired && !execute_valid && auxiliary_register_1 == 16'h0055 &&
      pc == 12'h006 && !interrupt_mask && interrupt_pending &&
      cycle_count == 32'd6 && program_address == 12'h002,
      "protected-DINT retained request reaches later dummy ownership"
    );
    advance_to_sample("protected-DINT vector");
    require_vector_capture(
      12'h006,
      16'h7f81,
      32'd7,
      "protected-DINT-PROVISIONAL"
    );
  endtask

  initial begin
    initialize   = 1'b0;
    rs           = 1'b0;
    clock_enable = 1'b1;
    int_n        = 1'b1;

    run_request_during_eint();
    run_request_during_dint();
    run_eint_in_protected_slot();
    run_dint_in_protected_slot_provisional();

    $display(
      "PASS tb_sequential_pipeline_interrupt_mask_controls (4 placements)"
    );
    $finish;
  end
endmodule

`default_nettype wire
