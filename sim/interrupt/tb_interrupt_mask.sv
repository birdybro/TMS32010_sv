`default_nettype none

module tb_interrupt_mask;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic [11:0] program_address;
  logic        program_read;
  logic [15:0] program_data;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [7:0]  data_write_address;
  logic        data_write_address_valid;
  logic [15:0] data_read_data;
  logic [15:0] data_write_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] t_register;
  logic [31:0] product_register;
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
  logic        data_page_pointer;
  logic        overflow_flag;
  logic        overflow_mode;
  logic        interrupt_mask;
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
    .program_address_o             (program_address),
    .program_read_o                (program_read),
    .program_data_i                (program_data),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (data_write_address),
    .data_write_address_valid_o    (data_write_address_valid),
    .data_read_data_o              (data_read_data),
    .data_write_data_o             (data_write_data),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (t_register),
    .product_register_o            (product_register),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (data_page_pointer),
    .overflow_flag_o               (overflow_flag),
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

  task automatic require_program_only(input string instruction_name);
    require(program_read, {instruction_name, " keeps the program fetch active"});
    require(!data_read && !data_write && !data_address_valid,
            {instruction_name, " has no logical data transaction"});
    require(!data_write_address_valid,
            {instruction_name, " has no logical write destination"});
    require(data_address == 8'h00 && data_write_address == 8'h00,
            {instruction_name, " leaves inactive data addresses at zero"});
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7f8b;  // SOVM
    program_memory[1] = 16'h70a5;  // LARK AR0,0xa5
    program_memory[2] = 16'h6881;  // LARP 1
    program_memory[3] = 16'h6e01;  // LDPK 1
    program_memory[4] = 16'h7e5a;  // LACK 0x5a
    program_memory[5] = 16'h7f82;  // EINT
    program_memory[6] = 16'h7f80;  // following NOP
    program_memory[7] = 16'h7f81;  // DINT
    program_memory[8] = 16'h7f83;  // adjacent unqualified word

    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;
    tick();
    require(interrupt_mask && !program_read,
            "physical reset masks interrupts and suppresses fetch");

    reset = 1'b0;
    for (int unsigned index = 0; index < 5; index++) begin
      tick();
    end
    require(pc == 12'd5 && cycle_count == 32'd5,
            "setup retires in five one-cycle instructions");
    require(accumulator == 32'h0000_005a &&
            t_register == 16'h0000 && product_register == 32'h0000_0000 &&
            auxiliary_register_0 == 16'h00a5 &&
            auxiliary_register_1 == 16'h0000 &&
            auxiliary_register_pointer && data_page_pointer &&
            overflow_mode && !overflow_flag,
            "setup establishes nontrivial preserved state");
    require(interrupt_mask && instruction_valid,
            "EINT is valid while reset-established mask is set");
    require_program_only("EINT");

    tick();
    require(retired && !illegal && !interrupt_mask,
            "EINT clears INTM on its retirement boundary");
    require(pc == 12'd6 && cycle_count == 32'd6,
            "EINT consumes exactly one instruction cycle");
    require(accumulator == 32'h0000_005a &&
            t_register == 16'h0000 && product_register == 32'h0000_0000 &&
            auxiliary_register_0 == 16'h00a5 &&
            auxiliary_register_1 == 16'h0000 &&
            auxiliary_register_pointer && data_page_pointer &&
            overflow_mode && !overflow_flag,
            "EINT preserves all unrelated exposed state");
    require(data_write_data == 16'h005a,
            "EINT does not select a distinct write value");

    clock_enable = 1'b0;
    for (int unsigned index = 0; index < 3; index++) begin
      tick();
      require(!retired && pc == 12'd6 && cycle_count == 32'd6,
              "clock-enable stall cannot retire the following instruction");
      require(!interrupt_mask, "clock-enable stall holds cleared INTM");
    end
    clock_enable = 1'b1;
    tick();
    require(retired && !interrupt_mask && pc == 12'd7,
            "the instruction following EINT preserves cleared INTM");
    require(cycle_count == 32'd7,
            "following NOP consumes its one documented cycle");
    require(instruction_valid, "DINT is valid at the next program address");
    require_program_only("DINT");

    tick();
    require(retired && interrupt_mask,
            "DINT sets INTM on its retirement boundary");
    require(pc == 12'd8 && cycle_count == 32'd8,
            "DINT consumes exactly one instruction cycle");
    require(accumulator == 32'h0000_005a &&
            t_register == 16'h0000 && product_register == 32'h0000_0000 &&
            auxiliary_register_0 == 16'h00a5 &&
            auxiliary_register_1 == 16'h0000 &&
            auxiliary_register_pointer && data_page_pointer &&
            overflow_mode && !overflow_flag,
            "DINT preserves all unrelated exposed state");
    require(!instruction_valid,
            "the adjacent unqualified control word remains invalid");

    tick();
    require(illegal && !retired && interrupt_mask,
            "unqualified word traps without changing DINT state");
    require(pc == 12'd8 && cycle_count == 32'd8,
            "unqualified word neither advances nor consumes a cycle");

    reset = 1'b1;
    tick();
    require(interrupt_mask && pc == 12'h000,
            "physical reset reasserts INTM and resets PC");

    $display("PASS tb_interrupt_mask read_data=%04x", data_read_data);
    $finish;
  end
endmodule

`default_nettype wire
