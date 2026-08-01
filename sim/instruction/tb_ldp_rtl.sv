`default_nettype none

module tb_ldp_rtl;
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
    .internal_ram_read_enable_i    (clock_enable),
    .bio_i                          (1'b1),
    .int_i                          (1'b1),
    .program_address_o             (program_address),
    .program_next_address_o        (),
    .program_read_o                (program_read),
    .program_write_o               (),
    .program_write_data_o          (),
    .program_data_i                (program_data),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .io_write_data_o               (),
    .io_read_data_i                (16'h0000),
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
    .interrupt_pending_o           (),
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
    program_memory[2]  = 16'h6e01;  // LDPK 1
    program_memory[3]  = 16'h6f0f;  // LDP 15, old DP selects address 143
    program_memory[4]  = 16'h6f7f;  // LDP 127, new DP selects address 127
    program_memory[5]  = 16'h708f;  // LARK AR0,143
    program_memory[6]  = 16'h6880;  // LARP 0
    program_memory[7]  = 16'h6fa1;  // LDP *+,AR1
    program_memory[8]  = 16'h717f;  // LARK AR1,127
    program_memory[9]  = 16'h6f90;  // LDP *-,AR0
    program_memory[10] = 16'h6e01;  // LDPK 1
    program_memory[11] = 16'h6f10;  // unresolved physical address 144

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'd143;
    debug_data         = 16'hfffe;
    tick();
    initialize = 1'b0;
    debug_data_address = 8'd127;
    debug_data         = 16'h8001;
    tick();
    debug_data_write = 1'b0;
    require(!program_read && interrupt_mask,
            "reset suppresses fetch and masks interrupts");

    reset = 1'b0;
    tick();
    tick();
    tick();
    require(data_page_pointer && data_read && !data_write &&
            data_address_valid && data_address == 8'd143,
            "direct LDP resolves its address through the old page pointer");
    require(data_read_data == 16'hfffe,
            "direct LDP exposes the complete internal source word");
    require(data_write_data == 16'h00a5,
            "inactive write datapath reflects the preserved accumulator low word");

    tick();
    require(!data_page_pointer,
            "LDP ignores source bits 15:1 and loads an even LSB");
    require(data_read && data_address == 8'd127 &&
            data_read_data == 16'h8001,
            "following direct LDP uses the newly loaded page zero");

    tick();
    require(data_page_pointer,
            "LDP loads one when the selected source LSB is set");
    tick();
    tick();
    require(data_read && data_address == 8'd143,
            "indirect LDP reads through the old selected AR");

    tick();
    require(!data_page_pointer && auxiliary_register_0 == 16'd144 &&
            auxiliary_register_pointer,
            "indirect LDP updates DP, then AR0 and requested ARP");
    tick();
    require(data_read && data_address == 8'd127,
            "second indirect LDP reads through newly selected AR1");

    tick();
    require(data_page_pointer && auxiliary_register_1 == 16'd126 &&
            !auxiliary_register_pointer,
            "indirect decrement and ARP replacement follow the read");
    require(accumulator == 32'h0000_00a5 && overflow_mode && !overflow_flag,
            "LDP preserves accumulator and arithmetic status");

    tick();
    require(data_read && !data_address_valid && !instruction_valid,
            "unresolved direct LDP read is visible but cannot execute");
    require(data_address == 8'd144,
            "unresolved LDP address is not aliased into physical RAM");
    tick();
    require(illegal && !retired && pc == 12'd11,
            "unresolved LDP traps without advancing PC");
    require(cycle_count == 32'd11,
            "every accepted LDP and setup instruction consumes one cycle");

    require(t_register == 16'h0000, "LDP preserves initialized T");
    require(product_register == 32'h0000_0000,
            "LDP preserves initialized P");
    $display("PASS tb_ldp_rtl");
    $finish;
  end
endmodule

`default_nettype wire
