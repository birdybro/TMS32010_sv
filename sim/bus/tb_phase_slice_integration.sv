`default_nettype none

module tb_phase_slice_integration;
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
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
  logic        data_page_pointer;
  logic        overflow_mode;
  logic        interrupt_mask;
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
    .program_data_i                (program_data),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .program_address_o             (program_address),
    .men_n_o                       (men_n),
    .sample_o                      (sample),
    .bus_active_o                  (bus_active),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (data_page_pointer),
    .overflow_mode_o               (overflow_mode),
    .interrupt_mask_o              (interrupt_mask),
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
    program_memory[0] = 16'h7012;  // LARK AR0,0x12
    program_memory[1] = 16'h7134;  // LARK AR1,0x34
    program_memory[2] = 16'h6881;  // LARP 1
    program_memory[3] = 16'h6e01;  // LDPK 1
    program_memory[4] = 16'h7f8b;  // SOVM
    program_memory[5] = 16'h7ea5;  // LACK 0xa5
    program_memory[6] = 16'h7f81;  // unsupported and not a silent NOP

    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;

    for (int unsigned index = 0; index < 20; index++) begin
      tick();
      require(!bus_active && men_n, "reset keeps native bus inactive");
    end
    require(pc == 12'h000 && interrupt_mask, "reset establishes control state");

    rs = 1'b0;
    advance_to_sample();
    require(sample && retired, "first falling boundary retires LARK");
    require(program_address == 12'h001, "native bus advances from 0 to 1");
    require(pc == 12'h001, "architectural PC advances with native address");
    require(auxiliary_register_0 == 16'h0012, "sampled LARK updates AR0");
    require(cycle_count == 32'd1, "one native cycle retires one instruction");

    // Stop in the active MEN phase. All bus pins and architectural state hold.
    tick();
    require(phase == 2'd1 && !men_n && !retired, "entered active read phase");
    clock_enable = 1'b0;
    logic_stall_check: begin
      logic [1:0] saved_phase;
      logic [11:0] saved_address;
      saved_phase   = phase;
      saved_address = program_address;
      for (int unsigned index = 0; index < 3; index++) begin
        tick();
        require(phase == saved_phase, "clock enable holds native phase");
        require(program_address == saved_address, "clock enable holds address");
        require(!retired && !sample, "stall cannot retire or sample");
      end
    end

    clock_enable = 1'b1;
    advance_to_sample();
    require(retired && auxiliary_register_1 == 16'h0034,
            "second LARK updates AR1");
    require(pc == 12'h002 && program_address == 12'h002,
            "second sample advances PC and bus together");

    advance_to_sample();
    require(retired && auxiliary_register_pointer, "LARP selects AR1");
    require(pc == 12'h003, "LARP sample advances PC");

    advance_to_sample();
    require(retired && data_page_pointer, "LDPK selects page one");
    require(pc == 12'h004, "LDPK sample advances PC");

    advance_to_sample();
    require(retired && overflow_mode, "SOVM sets overflow mode");
    require(pc == 12'h005, "SOVM sample advances PC");

    advance_to_sample();
    require(retired, "LACK retires on sixth sample");
    require(accumulator == 32'h0000_00a5, "LACK consumes sampled program word");
    require(pc == 12'h006 && cycle_count == 32'd6,
            "six samples retire six instructions");

    advance_to_sample();
    require(sample && !retired && illegal, "unsupported word traps at sample");
    require(!instruction_valid, "unsupported word remains visibly invalid");
    require(pc == 12'h006, "trap holds architectural PC");
    require(program_address == 12'h006, "trap holds native program address");
    require(cycle_count == 32'd6, "trap does not count as retired cycle");

    // Assertion is recognized at the next falling boundary, after the current
    // machine cycle, and resets the architectural PC with the native address.
    rs = 1'b1;
    for (int unsigned index = 0; index < 4; index++) begin
      tick();
    end
    require(!bus_active && men_n, "recognized reset disables native bus");
    require(pc == 12'h000 && program_address == 12'h000,
            "recognized reset aligns architectural and native address zero");

    $display("PASS tb_phase_slice_integration");
    $finish;
  end
endmodule

`default_nettype wire
