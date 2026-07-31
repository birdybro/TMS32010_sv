`default_nettype none

module tb_interrupt_phase;
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
  logic        data_read;
  logic        data_write;
  logic        io_read;
  logic        io_write;
  logic        program_write;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [11:0] stack_top;
  logic        interrupt_mask;
  logic        interrupt_pending;
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_phase_slice dut (
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
    .sample_o                      (sample),
    .bus_active_o                  (bus_active),
    .data_address_o                (),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .io_port_o                     (),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (),
    .program_write_o               (program_write),
    .program_write_data_o          (),
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

  task automatic advance_to_sample;
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require(clkout == phase[1], "CLKOUT follows native phase encoding");
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
    program_memory[0]       = 16'hf900;  // B
    program_memory[1]       = 16'h0100;  // target
    program_memory[2]       = 16'h7e5a;  // interrupt vector LACK 0x5a
    program_memory[12'h100] = 16'h7f82;  // EINT
    program_memory[12'h101] = 16'h7e2a;  // protected LACK 0x2a
    program_memory[12'h102] = 16'h7f89;  // dummy-fetched ZAC

    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    int_n        = 1'b1;
    tick();
    initialize = 1'b0;

    for (int unsigned index = 0; index < 20; index++) begin
      tick();
      require(!bus_active && men_n, "reset keeps native bus inactive");
    end

    rs = 1'b0;
    advance_to_sample();
    require(sample && !retired && program_address == 12'h001 &&
            pc == 12'h001 && cycle_count == 32'd1,
            "B opcode fetch advances to its following target word");

    // Hold INT low for the complete target-word machine cycle. It is sampled
    // at the falling-CLKOUT boundary while reset-established INTM is still set.
    int_n = 1'b0;
    tick();
    require(phase == 2'd1 && !men_n && program_address == 12'h001,
            "active-low request spans the B operand MEN phase");
    advance_to_sample();
    int_n = 1'b1;
    require(sample && retired && interrupt_pending && interrupt_mask &&
            pc == 12'h100 && program_address == 12'h100 &&
            cycle_count == 32'd2,
            "masked pulse is retained while B completes at target 0x100");

    advance_to_sample();
    require(retired && !interrupt_mask && interrupt_pending &&
            pc == 12'h101 && program_address == 12'h101 &&
            cycle_count == 32'd3,
            "EINT fetch retires and permits its following instruction");

    advance_to_sample();
    require(retired && accumulator == 32'h0000_002a &&
            pc == 12'h102 && program_address == 12'h102 &&
            interrupt_pending && !instruction_valid &&
            cycle_count == 32'd4,
            "following instruction retires before return-address dummy fetch");

    tick();
    require(phase == 2'd1 && bus_active && !men_n &&
            den_n && we_n && program_address == 12'h102,
            "dummy fetch has an ordinary active program-memory MEN phase");
    require(!data_read && !data_write && !io_read && !io_write &&
            !program_write,
            "dummy cycle cannot issue data, I/O, or program-write traffic");

    advance_to_sample();
    require(sample && !retired && !illegal &&
            pc == 12'h002 && program_address == 12'h002 &&
            stack_top == 12'h102 && interrupt_mask && !interrupt_pending &&
            accumulator == 32'h0000_002a && cycle_count == 32'd5,
            "dummy sample acknowledges internally and selects vector 2");

    advance_to_sample();
    require(retired && !illegal && pc == 12'h003 &&
            program_address == 12'h003 &&
            accumulator == 32'h0000_005a && cycle_count == 32'd6,
            "vector word executes on its own following native read cycle");

    $display("PASS tb_interrupt_phase");
    $finish;
  end
endmodule

`default_nettype wire
