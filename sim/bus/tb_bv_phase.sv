`default_nettype none

module tb_bv_phase;
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
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [11:0] pc;
  logic        overflow_flag;
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
    .bio_i                          (1'b1),
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
    .stack_top_o                    (),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
    .overflow_flag_o               (overflow_flag),
    .overflow_mode_o               (),
    .interrupt_mask_o              (),
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

  task automatic run_case(
    input logic  status_overflow,
    input string name
  );
    program_memory[0] = 16'h7b00;
    program_memory[1] = 16'hf500;
    program_memory[2] = 16'h0004;
    program_memory[3] = 16'h7f80;
    program_memory[4] = 16'h7f80;

    initialize       = 1'b1;
    rs               = 1'b1;
    clock_enable     = 1'b1;
    debug_data       = status_overflow ? 16'h8000 : 16'h0000;
    debug_data_write = 1'b1;
    tick();
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    for (int unsigned index = 0; index < 20; index++) begin
      tick();
      require(!bus_active && men_n, {name, " reset bus"});
    end
    rs = 1'b0;

    advance_to_sample();
    require(retired && !illegal && pc == 12'h001 &&
            program_address == 12'h001 && cycle_count == 32'd1 &&
            overflow_flag == status_overflow,
            {name, " LST setup sample"});

    advance_to_sample();
    require(sample && instruction_valid && !retired && !illegal &&
            pc == 12'h002 && program_address == 12'h002 &&
            cycle_count == 32'd2 &&
            overflow_flag == status_overflow,
            {name, " BV opcode sample"});
    require(!data_read && !data_write && !data_address_valid,
            {name, " target read has no data transaction"});

    tick();
    require(phase == 2'd1 && bus_active && !men_n &&
            program_address == 12'h002,
            {name, " target has ordinary active MEN phase"});
    clock_enable = 1'b0;
    tick();
    require(phase == 2'd1 && bus_active && !men_n &&
            program_address == 12'h002 && pc == 12'h002 &&
            cycle_count == 32'd2 && !retired &&
            overflow_flag == status_overflow,
            {name, " target phase stalls with OV stable"});
    clock_enable = 1'b1;

    advance_to_sample();
    require(sample && retired && !illegal && cycle_count == 32'd3 &&
            pc == (status_overflow ? 12'h004 : 12'h003) &&
            program_address == (status_overflow ? 12'h004 : 12'h003),
            {name, " target sample retires"});
    require(!overflow_flag, {name, " retires with OV clear"});
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

    run_case(1'b1, "taken");
    run_case(1'b0, "untaken");

    $display("PASS tb_bv_phase");
    $finish;
  end
endmodule

`default_nettype wire
