`default_nettype none

module tb_interrupt_native_sampling;
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
  logic        sample;
  logic        bus_active;
  logic [11:0] pc;
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
    .den_n_o                       (),
    .we_n_o                        (),
    .sample_o                      (sample),
    .bus_active_o                  (bus_active),
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
    .program_write_o               (),
    .program_write_data_o          (),
    .pc_o                          (pc),
    .accumulator_o                 (),
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

  task automatic prepare_enabled_stream;
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
    require(
      sample && retired && !interrupt_mask && !interrupt_pending &&
      pc == 12'h001 && phase == 2'd0 && cycle_count == 32'd1,
      "EINT retires on the first active falling boundary"
    );

    advance_to_sample();
    require(
      sample && retired && !interrupt_mask && !interrupt_pending &&
      pc == 12'h002 && phase == 2'd0 && cycle_count == 32'd2,
      "EINT's protected NOP retires before the sampling case"
    );
  endtask

  task automatic run_arrival_case(input int unsigned arrival_phase);
    logic [31:0] before_cycles;

    prepare_enabled_stream();
    before_cycles = cycle_count;

    while (phase != arrival_phase[1:0]) begin
      tick();
      require(
        !sample && !interrupt_pending && cycle_count == before_cycles,
        "pre-arrival native phases cannot advance architectural state"
      );
    end

    int_n = 1'b0;

    if (arrival_phase == 2) begin
      clock_enable = 1'b0;
      repeat (5) begin
        tick();
        require(
          phase == 2'd2 && !sample && !interrupt_pending &&
          cycle_count == before_cycles,
          "stalled pre-sample phase holds request and architectural state"
        );
      end
      clock_enable = 1'b1;
    end

    while (phase != 2'd3) begin
      tick();
      require(
        !sample && !interrupt_pending && cycle_count == before_cycles,
        "INT is owned only by the enabled falling-CLKOUT sample"
      );
    end

    tick();
    int_n = 1'b1;
    require(
      sample && retired && interrupt_pending && !interrupt_mask &&
      pc == 12'h003 && phase == 2'd0 &&
      cycle_count == before_cycles + 32'd1,
      "falling-CLKOUT sample latches the active-low request"
    );

    advance_to_sample();
    require(
      sample && retired && interrupt_pending && !interrupt_mask &&
      !instruction_valid && pc == 12'h004 &&
      cycle_count == before_cycles + 32'd2,
      "one already-pipelined instruction retires before dummy entry"
    );

    advance_to_sample();
    require(
      sample && !retired && !illegal && interrupt_mask &&
      !interrupt_pending && stack_top == 12'h004 &&
      pc == 12'h002 && program_address == 12'h002 &&
      cycle_count == before_cycles + 32'd3,
      "dummy sample stacks the resolved return PC and selects vector 2"
    );
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;  // NOP
    end
    program_memory[0] = 16'h7f82;  // EINT

    for (int unsigned arrival_phase = 0;
         arrival_phase < 4;
         arrival_phase++) begin
      run_arrival_case(arrival_phase);
    end

    $display("PASS tb_interrupt_native_sampling (4 arrival phases)");
    $finish;
  end
endmodule

`default_nettype wire
