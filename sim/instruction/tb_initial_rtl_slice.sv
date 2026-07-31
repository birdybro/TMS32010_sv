`default_nettype none

module tb_initial_rtl_slice;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic [11:0] program_address;
  logic        program_read;
  logic [15:0] program_data;
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
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [7:0]  data_write_address;
  logic        data_write_address_valid;
  logic [15:0] data_read_data;
  logic [15:0] data_write_data;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;

  logic [15:0] program_memory [0:4095];

  tms32010_core dut (
    .clk_i             (clk),
    .initialize_i      (initialize),
    .reset_i           (reset),
    .clock_enable_i    (clock_enable),
    .bio_i                          (1'b1),
    .program_address_o (program_address),
    .program_next_address_o (),
    .program_read_o    (program_read),
    .program_data_i    (program_data),
    .data_address_o    (data_address),
    .data_read_o       (data_read),
    .data_write_o      (data_write),
    .data_address_valid_o (data_address_valid),
    .data_write_address_o (data_write_address),
    .data_write_address_valid_o (data_write_address_valid),
    .data_read_data_o  (data_read_data),
    .data_write_data_o (data_write_data),
    .debug_data_write_i (debug_data_write),
    .debug_data_address_i (debug_data_address),
    .debug_data_i      (debug_data),
    .pc_o              (pc),
    .accumulator_o     (accumulator),
    .t_register_o      (t_register),
    .product_register_o (product_register),
    .auxiliary_register_0_o (auxiliary_register_0),
    .auxiliary_register_1_o (auxiliary_register_1),
    .auxiliary_register_pointer_o (auxiliary_register_pointer),
    .data_page_pointer_o (data_page_pointer),
    .stack_top_o                    (),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
    .overflow_flag_o   (overflow_flag),
    .overflow_mode_o   (overflow_mode),
    .interrupt_mask_o  (interrupt_mask),
    .instruction_valid_o (instruction_valid),
    .retired_o         (retired),
    .illegal_o         (illegal),
    .cycle_count_o     (cycle_count)
  );

  assign program_data = program_memory[program_address];

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    @(posedge clk);
    #1;
    assert (!data_write_address_valid || (data_write_address < 8'd144));
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7000;
    program_memory[1] = 16'h71ff;
    program_memory[2] = 16'h6881;
    program_memory[3] = 16'h6e01;
    program_memory[4] = 16'h7e80;
    program_memory[5] = 16'h7f89;
    program_memory[6] = 16'h7f8b;
    program_memory[7] = 16'h7f80;
    program_memory[8] = 16'h7f83;

    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    tick();
    initialize = 1'b0;
    require(pc == 12'h000, "reset PC");
    require(interrupt_mask, "reset masks interrupts");
    require(!overflow_flag, "explicit initialization clears OV");
    require(!program_read, "program read inactive during reset");
    require(!data_read && !data_write &&
            !data_address_valid && data_address == 8'h00,
            "logical data read is inactive during reset");
    require(!data_write || data_write_data == accumulator[15:0],
            "logical write data always reflects ACC low");
    require(!data_read || !$isunknown(data_read_data),
            "an active logical data read must return known test data");

    reset = 1'b0;
    tick();
    require(instruction_valid, "LARK encoding is qualified");
    require(auxiliary_register_0 == 16'h0000, "LARK zero boundary");
    require(pc == 12'h001, "LARK AR0 advances PC");

    tick();
    require(auxiliary_register_1 == 16'h00ff, "LARK zero extends maximum");
    require(pc == 12'h002, "LARK AR1 advances PC");

    tick();
    require(auxiliary_register_pointer, "LARP selects AR1");
    require(pc == 12'h003, "LARP advances PC");

    tick();
    require(data_page_pointer, "LDPK selects page one");
    require(pc == 12'h004, "LDPK advances PC");

    tick();
    require(retired, "LACK retires");
    require(accumulator == 32'h0000_0080, "LACK zero extends");
    require(pc == 12'h005, "LACK advances PC");
    require(cycle_count == 32'd5, "immediate controls are one cycle each");

    tick();
    require(accumulator == 32'h0000_0000, "ZAC clears accumulator");
    require(pc == 12'h006, "ZAC advances PC");

    tick();
    require(overflow_mode, "SOVM sets overflow mode");
    require(pc == 12'h007, "SOVM advances PC");

    clock_enable = 1'b0;
    tick();
    require(pc == 12'h007, "clock enable stalls PC");
    require(!retired, "stalled instruction does not retire");
    require(cycle_count == 32'd7, "stall does not count a cycle");

    clock_enable = 1'b1;
    tick();
    require(pc == 12'h008, "NOP advances PC");
    require(accumulator == 32'h0000_0000, "NOP preserves accumulator");

    tick();
    require(illegal, "unsupported opcode traps");
    require(!instruction_valid, "unsupported opcode is visibly invalid");
    require(!retired, "unsupported opcode does not retire");
    require(pc == 12'h008, "unsupported opcode holds PC");
    require(cycle_count == 32'd8, "unsupported opcode is not counted");

    program_memory[8] = 16'h7f8a;
    tick();
    require(!illegal, "valid opcode clears trap indication");
    require(!overflow_mode, "ROVM clears overflow mode");
    require(pc == 12'h009, "ROVM advances PC");

    program_memory[0] = 16'h7f8b;
    reset      = 1'b1;
    tick();
    require(pc == 12'h000, "second reset clears PC");
    require(!overflow_mode, "reset preserves cleared OVM");

    reset = 1'b0;
    tick();
    require(overflow_mode, "SOVM executes after reset");
    reset = 1'b1;
    tick();
    require(overflow_mode, "reset preserves set OVM");

    require(t_register == 16'h0000,
            "qualified control slice preserves initialized T");
    require(product_register == 32'h0000_0000,
            "qualified control slice preserves initialized P");
    $display("PASS tb_initial_rtl_slice");
    $finish;
  end
endmodule

`default_nettype wire
