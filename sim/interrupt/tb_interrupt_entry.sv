`default_nettype none

module tb_interrupt_entry;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic        int_n;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic        program_read;
  logic [15:0] program_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [31:0] product_register;
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        interrupt_mask;
  logic        interrupt_pending;
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_core dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .reset_i                       (reset),
    .clock_enable_i                (clock_enable),
    .bio_i                         (1'b1),
    .int_i                         (int_n),
    .program_address_o             (program_address),
    .program_next_address_o        (program_next_address),
    .program_read_o                (program_read),
    .program_write_o               (),
    .program_write_data_o          (),
    .program_data_i                (program_data),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .io_write_data_o               (),
    .io_read_data_i                (16'h0000),
    .data_address_o                (),
    .data_read_o                   (),
    .data_write_o                  (),
    .data_address_valid_o          (),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (),
    .product_register_o            (product_register),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
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
    .instruction_valid_o           (instruction_valid),
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

  task automatic initialize_core;
    initialize   = 1'b1;
    reset        = 1'b0;
    clock_enable = 1'b1;
    int_n        = 1'b1;
    tick();
    initialize = 1'b0;
    require(pc == 12'h000 && interrupt_mask && !interrupt_pending,
            "initialization establishes masked, nonpending interrupt state");
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end

    // A request captured while EINT retires permits its following instruction,
    // then uses a non-retiring dummy fetch to push PC and select vector 2.
    program_memory[0] = 16'h7f82;  // EINT
    program_memory[1] = 16'h7e2a;  // protected LACK 0x2a
    program_memory[2] = 16'h7e5a;  // vector word, fetched once as dummy
    initialize_core();

    int_n = 1'b0;
    tick();
    require(retired && !illegal && !interrupt_mask && interrupt_pending,
            "active-low request is latched while EINT clears INTM");
    require(pc == 12'h001 && cycle_count == 32'd1,
            "EINT retires before interrupt entry");

    int_n = 1'b1;
    tick();
    require(retired && pc == 12'h002 && accumulator == 32'h0000_002a,
            "instruction following EINT retires normally");
    require(interrupt_pending && !instruction_valid &&
            program_address == 12'h002 &&
            program_next_address == 12'h002,
            "entry state presents the return-address dummy fetch");

    tick();
    require(!retired && !illegal && program_read,
            "interrupt entry consumes a program cycle without retirement");
    require(pc == 12'h002 && stack_top == 12'h002 &&
            stack_level_1 == 12'h000 && stack_level_2 == 12'h000 &&
            stack_bottom == 12'h000,
            "entry pushes the current return PC and selects vector 2");
    require(interrupt_mask && !interrupt_pending &&
            accumulator == 32'h0000_002a && cycle_count == 32'd3,
            "acknowledge masks and clears the latch without executing dummy");

    tick();
    require(retired && pc == 12'h003 &&
            accumulator == 32'h0000_005a && cycle_count == 32'd4,
            "vector instruction executes only on the following fetch cycle");

    // DINT in the protected slot cancels entry. Re-enabling with the still
    // pending request then demonstrates MPYK's extra protected instruction.
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7f82;  // EINT, no request
    program_memory[1] = 16'h7f80;  // request sampled here
    program_memory[2] = 16'h7f81;  // protected DINT cancels entry
    program_memory[3] = 16'h7f80;  // remains ordinary while masked
    program_memory[4] = 16'h7f82;  // EINT reschedules pending request
    program_memory[5] = 16'h8002;  // protected MPYK 2
    program_memory[6] = 16'h7e44;  // instruction following MPYK
    program_memory[7] = 16'h7f89;  // dummy-fetched ZAC, must not execute
    initialize_core();
    // Establish a nonzero multiplier input through the exposed deterministic
    // initialization state is not possible; MPYK still proves sequencing with
    // a zero T input and therefore a zero product.

    tick();
    require(retired && !interrupt_mask && !interrupt_pending,
            "request-free EINT only clears the mask");
    int_n = 1'b0;
    tick();
    int_n = 1'b1;
    require(retired && interrupt_pending && !interrupt_mask &&
            pc == 12'h002,
            "one-cycle low pulse arms service while unmasked");
    tick();
    require(retired && interrupt_mask && interrupt_pending &&
            pc == 12'h003,
            "DINT cancels armed entry and retains the request");
    tick();
    require(retired && interrupt_mask && interrupt_pending &&
            pc == 12'h004,
            "masked execution cannot service the retained request");
    tick();
    require(retired && !interrupt_mask && interrupt_pending &&
            pc == 12'h005,
            "EINT makes the retained request eligible");
    tick();
    require(retired && pc == 12'h006 && product_register == 32'h0000_0000,
            "MPYK retires but extends interrupt deferral");
    tick();
    require(retired && pc == 12'h007 &&
            accumulator == 32'h0000_0044 && !instruction_valid,
            "instruction after MPYK completes before dummy entry");
    tick();
    require(!retired && pc == 12'h002 && stack_top == 12'h007 &&
            accumulator == 32'h0000_0044 &&
            interrupt_mask && !interrupt_pending,
            "dummy-fetched ZAC is discarded and return PC 7 is stacked");

    // A pulse arriving during a two-word branch is retained until the branch
    // completes, then one target instruction retires before entry.
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]     = 16'h7f82;  // EINT
    program_memory[1]     = 16'hf900;  // B
    program_memory[2]     = 16'h0100;  // target
    program_memory[12'h100] = 16'h7e66;
    program_memory[12'h101] = 16'h7f89;
    initialize_core();

    tick();
    int_n = 1'b0;
    tick();
    require(!retired && interrupt_pending && pc == 12'h002,
            "request during first branch cycle cannot interrupt midinstruction");
    int_n = 1'b1;
    tick();
    require(retired && pc == 12'h100 && interrupt_pending,
            "branch completes before interrupt deferral begins");
    tick();
    require(retired && pc == 12'h101 &&
            accumulator == 32'h0000_0066 && !instruction_valid,
            "one target instruction retires before branch-delayed entry");
    tick();
    require(!retired && pc == 12'h002 && stack_top == 12'h101 &&
            accumulator == 32'h0000_0066,
            "entry after multicycle completion stacks resolved target PC");

    // TI limits EINT's special protection to the transition from disabled to
    // enabled. A redundant EINT already in an armed unmasked slot does not
    // protect another instruction.
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7f82;  // first EINT clears reset mask
    program_memory[1] = 16'h7f80;  // request sampled here
    program_memory[2] = 16'h7f82;  // redundant EINT in protected slot
    program_memory[3] = 16'h7f89;  // dummy-fetched ZAC
    initialize_core();

    tick();
    int_n = 1'b0;
    tick();
    int_n = 1'b1;
    tick();
    require(retired && pc == 12'h003 && !instruction_valid &&
            !interrupt_mask && interrupt_pending,
            "redundant EINT does not extend an already active deferral");
    tick();
    require(!retired && pc == 12'h002 && stack_top == 12'h003 &&
            interrupt_mask && !interrupt_pending,
            "entry immediately follows redundant EINT's protected slot");

    // Physical reset masks interrupts and clears both the pending latch and
    // all entry microstate, as shown by TI's interrupt-control logic.
    reset = 1'b1;
    int_n = 1'b0;
    tick();
    require(pc == 12'h000 && interrupt_mask && !interrupt_pending &&
            cycle_count == 32'd0,
            "reset clears a held-low pending request at its sample boundary");

    $display("PASS tb_interrupt_entry");
    $finish;
  end
endmodule

`default_nettype wire
