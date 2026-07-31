`default_nettype none

module tb_mpy_rtl;
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
    .program_address_o             (program_address),
    .program_read_o                (program_read),
    .program_data_i                (program_data),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
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

  task automatic preload(input logic [7:0] address, input logic [15:0] data);
    debug_data_address = address;
    debug_data         = data;
    tick();
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h7ea5;  // LACK 0xa5
    program_memory[1]  = 16'h7f8b;  // SOVM
    program_memory[2]  = 16'h6a01;  // LT 1
    program_memory[3]  = 16'h6d02;  // MPY 2
    program_memory[4]  = 16'h6a03;  // LT 3
    program_memory[5]  = 16'h6d04;  // MPY 4
    program_memory[6]  = 16'h6a05;  // LT 5
    program_memory[7]  = 16'h6d05;  // MPY 5, special most-negative square
    program_memory[8]  = 16'h6a06;  // LT 6
    program_memory[9]  = 16'h7107;  // LARK AR1,7
    program_memory[10] = 16'h7006;  // LARK AR0,6
    program_memory[11] = 16'h6880;  // LARP 0
    program_memory[12] = 16'h6da1;  // MPY *+,AR1
    program_memory[13] = 16'h6d90;  // MPY *-,AR0
    program_memory[14] = 16'h6e01;  // LDPK 1
    program_memory[15] = 16'h6a0f;  // LT 15, physical address 143
    program_memory[16] = 16'h6d0e;  // MPY 14, physical address 142
    program_memory[17] = 16'h6d10;  // unresolved physical address 144

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    preload(8'd1, 16'h0006);
    preload(8'd2, 16'h0007);
    preload(8'd3, 16'hffff);
    preload(8'd4, 16'h0002);
    preload(8'd5, 16'h8000);
    preload(8'd6, 16'h7fff);
    preload(8'd7, 16'h8000);
    preload(8'd142, 16'h0003);
    preload(8'd143, 16'hfffe);
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    tick();
    require(!program_read && interrupt_mask,
            "reset suppresses fetch and masks interrupts");

    reset = 1'b0;
    tick();
    tick();
    require(data_read && data_address == 8'd1,
            "LT exposes the multiplicand source before MPY");
    tick();
    require(t_register == 16'h0006 &&
            data_read && data_address == 8'd2 &&
            data_read_data == 16'h0007,
            "MPY reads its data operand while preserving loaded T");
    tick();
    require(product_register == 32'h0000_002a,
            "positive signed multiplication produces the primary example");

    tick();
    tick();
    require(product_register == 32'hffff_fffe,
            "MPY treats both operands as signed two's-complement values");
    tick();
    tick();
    require(product_register == 32'hc000_0000,
            "most-negative square reproduces the documented hardware result");

    tick();
    tick();
    tick();
    tick();
    require(data_read && data_address == 8'd6,
            "indirect MPY uses the selected AR before modification");
    tick();
    require(product_register == 32'h3fff_0001 &&
            auxiliary_register_0 == 16'd7 &&
            auxiliary_register_pointer,
            "indirect MPY stores the product then updates AR and ARP");
    require(data_read && data_address == 8'd7,
            "second indirect MPY uses the newly selected AR");
    tick();
    require(product_register == 32'hc000_8000 &&
            auxiliary_register_1 == 16'd6 &&
            !auxiliary_register_pointer,
            "negative indirect product and nine-bit decrement are exact");

    tick();
    require(data_page_pointer && data_read && data_address == 8'd143,
            "page-one LT resolves its old DP address");
    tick();
    require(t_register == 16'hfffe &&
            data_read && data_address == 8'd142,
            "page-one MPY sees the complete signed operands");
    tick();
    require(product_register == 32'hffff_fffa,
            "page-one MPY stores a negative product");
    require(accumulator == 32'h0000_00a5 && overflow_mode && !overflow_flag,
            "MPY preserves ACC, OV, and OVM");
    require(t_register == 16'hfffe,
            "MPY preserves its T multiplicand");
    require(data_read && !data_address_valid && !instruction_valid &&
            data_address == 8'd144,
            "unresolved MPY read remains visible without RAM aliasing");

    tick();
    require(illegal && !retired && pc == 12'd17,
            "unresolved MPY traps without advancing PC");
    require(product_register == 32'hffff_fffa && cycle_count == 32'd17,
            "failed MPY preserves P and counts only accepted instructions");
    require(!data_write && data_write_data == accumulator[15:0],
            "MPY never creates a logical data write");

    $display("PASS tb_mpy_rtl");
    $finish;
  end
endmodule

`default_nettype wire
