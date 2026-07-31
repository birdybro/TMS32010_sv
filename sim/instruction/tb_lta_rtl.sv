`default_nettype none

module tb_lta_rtl;
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

  task automatic write_data_word(
    input logic [7:0] address,
    input logic [15:0] value
  );
    debug_data_address = address;
    debug_data         = value;
    tick();
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h6a02;  // LT 2 -> T=1
    program_memory[1]  = 16'h800f;  // MPYK 15 -> P=15
    program_memory[2]  = 16'h7e05;  // LACK 5
    program_memory[3]  = 16'h6c18;  // LTA 24: primary example
    program_memory[4]  = 16'h6a02;  // LT 2
    program_memory[5]  = 16'h8040;  // MPYK 64
    program_memory[6]  = 16'h6500;  // ZALH 0 -> 0x7fff0000
    program_memory[7]  = 16'h6101;  // ADDS 1 -> 0x7ffffffe
    program_memory[8]  = 16'h6e01;  // LDPK 1
    program_memory[9]  = 16'h6c0f;  // LTA 143: positive wrap
    program_memory[10] = 16'h7f8b;  // SOVM
    program_memory[11] = 16'h6e00;  // LDPK 0
    program_memory[12] = 16'h6500;  // ZALH 0
    program_memory[13] = 16'h6101;  // ADDS 1
    program_memory[14] = 16'h6e01;  // LDPK 1
    program_memory[15] = 16'h6c0f;  // LTA 143: positive saturation
    program_memory[16] = 16'h6e00;  // LDPK 0
    program_memory[17] = 16'h6a02;  // LT 2
    program_memory[18] = 16'h9fc0;  // MPYK -64
    program_memory[19] = 16'h7f8a;  // ROVM
    program_memory[20] = 16'h6503;  // ZALH 3 -> 0x80000000
    program_memory[21] = 16'h6104;  // ADDS 4 -> 0x80000001
    program_memory[22] = 16'h6c18;  // LTA 24: negative wrap
    program_memory[23] = 16'h7f8b;  // SOVM
    program_memory[24] = 16'h6503;  // ZALH 3
    program_memory[25] = 16'h6104;  // ADDS 4
    program_memory[26] = 16'h7018;  // LARK AR0,24
    program_memory[27] = 16'h6880;  // LARP 0
    program_memory[28] = 16'h6ca1;  // LTA *+,AR1: negative saturation
    program_memory[29] = 16'h6e01;  // LDPK 1
    program_memory[30] = 16'h6c10;  // unresolved physical address 144

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'd0;
    debug_data         = 16'h0000;
    write_data_word(8'd0, 16'h7fff);
    write_data_word(8'd1, 16'hfffe);
    write_data_word(8'd2, 16'h0001);
    write_data_word(8'd3, 16'h8000);
    write_data_word(8'd4, 16'h0001);
    write_data_word(8'd24, 16'h0062);
    write_data_word(8'd143, 16'hbeef);
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    tick();
    require(!program_read && interrupt_mask,
            "reset suppresses fetch and masks interrupts");

    reset = 1'b0;
    tick();
    tick();
    tick();
    require(accumulator == 32'd5 && product_register == 32'd15 &&
            t_register == 16'h0001,
            "primary setup establishes independent ACC, P, and old T");
    require(data_read && !data_write && data_address_valid &&
            data_address == 8'd24 && data_read_data == 16'h0062,
            "LTA exposes the selected internal data read");

    tick();
    require(retired && accumulator == 32'd20 &&
            t_register == 16'h0062 && product_register == 32'd15,
            "LTA matches TI's worked example and preserves previous P");
    require(!overflow_flag && !overflow_mode &&
            pc == 12'd4 && cycle_count == 32'd4,
            "primary LTA retires in one cycle without false overflow");

    tick();
    tick();
    tick();
    tick();
    tick();
    require(accumulator == 32'h7fff_fffe &&
            product_register == 32'h0000_0040 &&
            data_page_pointer,
            "positive-overflow setup retains the previous product");
    require(data_read && data_address_valid &&
            data_address == 8'd143 && data_read_data == 16'hbeef,
            "direct page-one LTA resolves the old DP-selected address");

    tick();
    require(accumulator == 32'h8000_003e &&
            t_register == 16'hbeef && product_register == 32'h0000_0040,
            "OVM-clear LTA wraps positive overflow while loading T");
    require(overflow_flag && !overflow_mode,
            "positive overflow sets sticky OV");

    tick();
    tick();
    tick();
    tick();
    tick();
    require(accumulator == 32'h7fff_fffe &&
            overflow_flag && overflow_mode &&
            data_read && data_address == 8'd143,
            "positive saturation setup preserves sticky OV and reaches LTA");

    tick();
    require(accumulator == 32'h7fff_ffff &&
            t_register == 16'hbeef && product_register == 32'h0000_0040,
            "OVM-set LTA saturates positive overflow and preserves P");

    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    require(accumulator == 32'h8000_0001 &&
            product_register == 32'hffff_ffc0 &&
            !overflow_mode,
            "negative-overflow setup establishes ACC and previous negative P");
    require(data_read && data_address == 8'd24,
            "negative-overflow LTA exposes its internal read");

    tick();
    require(accumulator == 32'h7fff_ffc1 &&
            t_register == 16'h0062 && product_register == 32'hffff_ffc0,
            "OVM-clear LTA wraps negative overflow while loading T");
    require(overflow_flag && !overflow_mode,
            "negative overflow retains sticky OV");

    tick();
    tick();
    tick();
    tick();
    tick();
    require(accumulator == 32'h8000_0001 &&
            auxiliary_register_0 == 16'd24 &&
            !auxiliary_register_pointer && overflow_mode,
            "indirect saturation setup establishes old AR address and OVM");
    require(data_read && data_address_valid &&
            data_address == 8'd24 && data_read_data == 16'h0062,
            "indirect LTA reads before AR/ARP post-modification");

    tick();
    require(accumulator == 32'h8000_0000 &&
            t_register == 16'h0062 && product_register == 32'hffff_ffc0,
            "OVM-set LTA saturates negative overflow with previous P");
    require(auxiliary_register_0 == 16'd25 &&
            auxiliary_register_pointer,
            "LTA applies common nine-bit increment and ARP replacement");
    require(pc == 12'd29 && cycle_count == 32'd29,
            "every accepted instruction including LTA consumes one cycle");

    tick();
    require(data_read && !data_address_valid && !instruction_valid &&
            data_address == 8'd144,
            "unresolved LTA read is visible and cannot execute");
    tick();
    require(illegal && !retired && pc == 12'd30 &&
            cycle_count == 32'd30,
            "unresolved LTA traps without advancing or counting a cycle");
    require(accumulator == 32'h8000_0000 &&
            t_register == 16'h0062 && product_register == 32'hffff_ffc0,
            "failed LTA performs neither parallel architectural effect");
    require(auxiliary_register_1 == 16'h0000 &&
            data_write_data == accumulator[15:0],
            "LTA leaves the other AR and inactive write diagnostics unchanged");

    $display("PASS tb_lta_rtl");
    $finish;
  end
endmodule

`default_nettype wire
