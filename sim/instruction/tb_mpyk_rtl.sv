`default_nettype none

module tb_mpyk_rtl;
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
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
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
    .bio_i                          (1'b1),
    .program_address_o             (program_address),
    .program_next_address_o        (),
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
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (t_register),
    .product_register_o            (product_register),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (data_page_pointer),
    .stack_top_o                    (),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
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
    program_memory[0]  = 16'h7ea5;  // LACK 0xa5
    program_memory[1]  = 16'h7f8b;  // SOVM
    program_memory[2]  = 16'h6a00;  // LT 0
    program_memory[3]  = 16'h9ff7;  // MPYK -9
    program_memory[4]  = 16'h9000;  // MPYK -4096
    program_memory[5]  = 16'h8fff;  // MPYK 4095
    program_memory[6]  = 16'h8000;  // MPYK 0
    program_memory[7]  = 16'h6a01;  // LT 1
    program_memory[8]  = 16'h8fff;  // MPYK 4095
    program_memory[9]  = 16'h9000;  // MPYK -4096
    program_memory[10] = 16'h7f83;  // unsupported control word

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'd0;
    debug_data         = 16'h0007;
    tick();
    debug_data_address = 8'd1;
    debug_data         = 16'h8000;
    tick();
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    tick();
    require(!program_read && interrupt_mask,
            "reset suppresses fetch and masks interrupts");

    reset = 1'b0;
    tick();
    tick();
    require(data_read && data_address_valid && data_address == 8'd0 &&
            data_read_data == 16'h0007,
            "LT presents the complete T source word");
    tick();
    require(t_register == 16'h0007 && !data_read && !data_write &&
            !data_address_valid,
            "MPYK consumes only its program-word immediate");
    tick();
    require(product_register == 32'hffff_ffc1,
            "MPYK reproduces TI's seven times negative-nine example");
    require(t_register == 16'h0007 &&
            accumulator == 32'h0000_00a5 &&
            !overflow_flag && overflow_mode,
            "MPYK preserves T, ACC, OV, and OVM");

    tick();
    require(product_register == 32'hffff_9000,
            "negative immediate minimum is sign-extended");
    tick();
    require(product_register == 32'h0000_6ff9,
            "positive immediate maximum remains signed positive");
    require(!data_read && !data_write && !data_address_valid,
            "zero-immediate MPYK exposes no logical data transaction");
    tick();
    require(product_register == 32'h0000_0000,
            "zero immediate clears P");
    require(auxiliary_register_0 == 16'h0000 &&
            auxiliary_register_1 == 16'h0000 &&
            !auxiliary_register_pointer && !data_page_pointer,
            "MPYK leaves address state unchanged");

    require(data_read && data_address == 8'd1,
            "following LT is the only logical data read");
    tick();
    require(t_register == 16'h8000 && !data_read && !data_write,
            "negative T is available to immediate multiplication");
    tick();
    require(product_register == 32'hf800_8000,
            "most-negative T times positive maximum is exact");
    tick();
    require(product_register == 32'h0800_0000,
            "two negative operands produce the exact positive boundary");
    require(cycle_count == 32'd10 && pc == 12'd10,
            "every accepted MPYK consumes exactly one instruction cycle");
    require(!instruction_valid,
            "adjacent unsupported control word remains invalid");

    tick();
    require(illegal && !retired && pc == 12'd10 &&
            cycle_count == 32'd10,
            "unsupported word traps without changing qualified state");
    require(product_register == 32'h0800_0000,
            "trap preserves the final MPYK result");
    require(data_write_data == accumulator[15:0],
            "MPYK never selects a logical write value");

    $display("PASS tb_mpyk_rtl");
    $finish;
  end
endmodule

`default_nettype wire
