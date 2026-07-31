`default_nettype none

module tb_sequential_pipeline_interrupt_multiply;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic        int_n;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
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
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] t_register;
  logic [31:0] product_register;
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
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
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
    .pipeline_blocked_o            (),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
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
    .t_register_o                  (t_register),
    .product_register_o            (product_register),
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

  task automatic require_exclusive_strobes(input string name);
    require(clkout == phase[1], {name, " CLKOUT follows phase encoding"});
    require(
      !(
        (!men_n && !den_n) ||
        (!men_n && !we_n) ||
        (!den_n && !we_n)
      ),
      {name, " native strobes remain mutually exclusive"}
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
    $fatal(1, "%s sample event did not arrive", name);
  endtask

  task automatic clear_program;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
  endtask

  task automatic initialize_pipeline(
    input logic [15:0] data_0,
    input logic [15:0] data_1
  );
    initialize         = 1'b1;
    rs                 = 1'b1;
    clock_enable       = 1'b1;
    int_n              = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    tick();
    initialize = 1'b0;

    debug_data_write   = 1'b1;
    debug_data_address = 8'h00;
    debug_data         = data_0;
    tick();
    debug_data_address = 8'h01;
    debug_data         = data_1;
    tick();
    debug_data_write = 1'b0;

    repeat (20) begin
      tick();
      require(
        !bus_active && men_n && den_n && we_n,
        "reset keeps every native strobe inactive"
      );
    end
    rs = 1'b0;
  endtask

  task automatic reach_eint(
    input logic [11:0] target,
    input logic [15:0] multiply_word,
    input logic [15:0] expected_t
  );
    advance_to_sample("B prefetch");
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'hf900 &&
      cycle_count == 32'd0 &&
      program_address == 12'h001,
      "first read primes B without executing it"
    );

    advance_to_sample("B operand");
    require(
      execute_address == 12'h000 &&
      !retired &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      program_address == target,
      "B operand selects the case target without retirement"
    );

    advance_to_sample("B target");
    require(
      retired &&
      execute_address == target &&
      execute_word == 16'h6a00 &&
      pc == target &&
      cycle_count == 32'd2 &&
      program_address == target + 12'h001,
      "B retires only when the target LT is captured"
    );

    advance_to_sample("LT");
    require(
      retired &&
      execute_address == target + 12'h001 &&
      execute_word == 16'h7f82 &&
      t_register == expected_t &&
      cycle_count == 32'd3 &&
      program_address == target + 12'h002,
      "LT establishes T before EINT enters execute ownership"
    );

    int_n = 1'b0;
    advance_to_sample("EINT");
    int_n = 1'b1;
    require(
      retired &&
      !illegal &&
      execute_address == target + 12'h002 &&
      execute_word == multiply_word &&
      interrupt_pending && !interrupt_mask &&
      pc == target + 12'h002 &&
      cycle_count == 32'd4 &&
      program_address == target + 12'h003,
      "EINT captures the multiply as its protected instruction"
    );
  endtask

  initial begin
    clear_program();
    program_memory[0]       = 16'hf900;  // B
    program_memory[1]       = 16'h0100;  // target
    program_memory[2]       = 16'h7e5a;  // vector LACK 0x5a
    program_memory[12'h100] = 16'h6a00;  // LT 0: T=3
    program_memory[12'h101] = 16'h7f82;  // EINT
    program_memory[12'h102] = 16'h6d01;  // protected MPY 1: 3 * -4
    program_memory[12'h103] = 16'h7e33;  // instruction after MPY
    program_memory[12'h104] = 16'h7f89;  // dummy-fetched ZAC
    initialize_pipeline(16'h0003, 16'hfffc);
    reach_eint(12'h100, 16'h6d01, 16'h0003);

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n &&
      program_address == 12'h103 &&
      execute_address == 12'h102 &&
      data_read && !data_write && data_address == 8'h01,
      "protected MPY overlaps the following program fetch and internal read"
    );
    clock_enable = 1'b0;
    repeat (3) begin
      tick();
      require(
        phase == 2'd1 &&
        program_address == 12'h103 &&
        execute_address == 12'h102 &&
        product_register == 32'h0000_0000 &&
        cycle_count == 32'd4 &&
        interrupt_pending && !interrupt_mask &&
        !retired,
        "MPY fetch stall cannot multiply or enter the interrupt early"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("protected MPY");
    require(
      retired &&
      !illegal &&
      execute_valid &&
      execute_address == 12'h103 &&
      execute_word == 16'h7e33 &&
      product_register == 32'hffff_fff4 &&
      interrupt_pending && !interrupt_mask &&
      stack_top == 12'h000 &&
      pc == 12'h103 &&
      cycle_count == 32'd5 &&
      program_address == 12'h104,
      "MPY retires but extends protection through the following instruction"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n &&
      program_address == 12'h104 &&
      execute_address == 12'h103,
      "instruction after MPY overlaps the deferred dummy fetch"
    );
    clock_enable = 1'b0;
    repeat (2) begin
      tick();
      require(
        accumulator == 32'h0000_0000 &&
        product_register == 32'hffff_fff4 &&
        stack_top == 12'h000 &&
        cycle_count == 32'd5 &&
        !retired,
        "deferred dummy stall cannot retire the following instruction early"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("instruction after MPY");
    require(
      retired &&
      !execute_valid &&
      accumulator == 32'h0000_0033 &&
      product_register == 32'hffff_fff4 &&
      pc == 12'h104 &&
      cycle_count == 32'd6 &&
      interrupt_pending && !interrupt_mask &&
      program_address == 12'h002,
      "instruction after MPY retires while its N+2 word is discarded"
    );

    advance_to_sample("MPY vector fetch");
    require(
      !retired &&
      execute_valid &&
      execute_address == 12'h002 &&
      execute_word == 16'h7e5a &&
      stack_top == 12'h104 &&
      pc == 12'h002 &&
      cycle_count == 32'd7 &&
      !interrupt_pending && interrupt_mask &&
      program_address == 12'h003,
      "MPY extension enters only after stacking the post-following PC"
    );

    advance_to_sample("MPY vector execution");
    require(
      retired &&
      accumulator == 32'h0000_005a &&
      product_register == 32'hffff_fff4 &&
      stack_top == 12'h104 &&
      cycle_count == 32'd8,
      "MPY vector executes only after the entry interval"
    );

    clear_program();
    program_memory[0]       = 16'hf900;  // B
    program_memory[1]       = 16'h0120;  // target
    program_memory[2]       = 16'h7e66;  // vector LACK 0x66
    program_memory[12'h120] = 16'h6a00;  // LT 0: T=7
    program_memory[12'h121] = 16'h7f82;  // EINT
    program_memory[12'h122] = 16'h9ff7;  // protected MPYK -9
    program_memory[12'h123] = 16'h7e44;  // instruction after MPYK
    program_memory[12'h124] = 16'h7f89;  // dummy-fetched ZAC
    initialize_pipeline(16'h0007, 16'h0000);
    reach_eint(12'h120, 16'h9ff7, 16'h0007);

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n &&
      program_address == 12'h123 &&
      execute_address == 12'h122 &&
      !data_read && !data_write,
      "protected MPYK retains the ordinary program-only fetch boundary"
    );
    clock_enable = 1'b0;
    repeat (2) begin
      tick();
      require(
        program_address == 12'h123 &&
        execute_address == 12'h122 &&
        product_register == 32'h0000_0000 &&
        cycle_count == 32'd4 &&
        !retired,
        "MPYK fetch stall cannot multiply or consume its protection"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("protected MPYK");
    require(
      retired &&
      execute_valid &&
      execute_address == 12'h123 &&
      execute_word == 16'h7e44 &&
      product_register == 32'hffff_ffc1 &&
      interrupt_pending && !interrupt_mask &&
      pc == 12'h123 &&
      cycle_count == 32'd5 &&
      program_address == 12'h124,
      "MPYK retires but protects exactly one following instruction"
    );

    advance_to_sample("instruction after MPYK");
    require(
      retired &&
      !execute_valid &&
      accumulator == 32'h0000_0044 &&
      product_register == 32'hffff_ffc1 &&
      pc == 12'h124 &&
      cycle_count == 32'd6 &&
      program_address == 12'h002,
      "instruction after MPYK retires while the dummy word is discarded"
    );

    advance_to_sample("MPYK vector fetch");
    require(
      !retired &&
      execute_valid &&
      execute_address == 12'h002 &&
      execute_word == 16'h7e66 &&
      accumulator == 32'h0000_0044 &&
      product_register == 32'hffff_ffc1 &&
      stack_top == 12'h124 &&
      pc == 12'h002 &&
      cycle_count == 32'd7 &&
      !interrupt_pending && interrupt_mask,
      "MPYK extension enters with the post-following return PC"
    );

    advance_to_sample("MPYK vector execution");
    require(
      retired &&
      accumulator == 32'h0000_0066 &&
      product_register == 32'hffff_ffc1 &&
      stack_top == 12'h124 &&
      cycle_count == 32'd8,
      "MPYK vector effect remains deferred until its execution interval"
    );

    $display("PASS tb_sequential_pipeline_interrupt_multiply");
    $finish;
  end
endmodule

`default_nettype wire
