`default_nettype none

module tb_subc_rtl;
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
    assert (!data_write_address_valid || (data_write_address < 8'd144));
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  task automatic load_data(
    input logic [7:0] address,
    input logic [15:0] value
  );
    debug_data_address = address;
    debug_data         = value;
    debug_data_write   = 1'b1;
    tick();
    debug_data_write   = 1'b0;
  endtask

  task automatic start_initialized_run;
    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    reset      = 1'b0;
    #1;
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h6600;  // ZALS 0: dividend 65
    for (int unsigned iteration = 0; iteration < 16; iteration++) begin
      program_memory[1 + iteration * 2] = 16'h6401;  // SUBC divisor 7
      program_memory[2 + iteration * 2] = 16'h7f80;  // legal ACC-free gap
    end

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    load_data(8'd0, 16'h0041);
    load_data(8'd1, 16'h0007);
    load_data(8'd2, 16'h8000);
    load_data(8'd3, 16'h0001);
    load_data(8'd4, 16'hffff);
    load_data(8'd5, 16'h7fff);
    load_data(8'd6, 16'h8000);
    load_data(8'd7, 16'h0004);
    load_data(8'd8, 16'h0000);
    load_data(8'd9, 16'h4000);
    load_data(8'd143, 16'h0002);
    start_initialized_run();

    require(program_read && interrupt_mask,
            "SUBC test begins with normal program fetch and masked interrupts");
    tick();
    for (int unsigned iteration = 0; iteration < 16; iteration++) begin
      require(data_read && !data_write && data_address_valid &&
              data_address == 8'd1 && data_read_data == 16'h0007,
              "SUBC exposes one selected internal-data read");
      tick();
      require(retired && !illegal,
              "each documented SUBC divide step retires in one cycle");
      require(!data_read && !data_write,
              "the required following NOP has no internal-data transaction");
      tick();
    end
    require(accumulator == 32'h0002_0009,
            "sixteen legally spaced SUBC steps match TI's 65/7 example");
    require(pc == 12'd33 && cycle_count == 32'd33,
            "SUBC and each ACC-free gap consume one cycle apiece");
    require(!overflow_flag && !overflow_mode,
            "ordinary positive division does not raise overflow");

    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h6502;  // ZALH 2 -> 0x80000000
    program_memory[1] = 16'h7f8b;  // SOVM
    program_memory[2] = 16'h6404;  // intermediate-only signed overflow
    program_memory[3] = 16'h7f80;  // required ACC-free gap
    program_memory[4] = 16'h7b08;  // clear OV/OVM through status word zero
    program_memory[5] = 16'h6509;  // ZALH 9 -> 0x40000000
    program_memory[6] = 16'h7f8b;  // SOVM
    program_memory[7] = 16'h6408;  // final-shift-only signed overflow
    program_memory[8] = 16'h7f80;  // required ACC-free gap

    start_initialized_run();
    tick();
    tick();
    require(data_read && data_address == 8'd4,
            "intermediate-overflow vector reads unsigned divisor 0xffff");
    tick();
    require(accumulator == 32'h0001_0001 &&
            overflow_flag && overflow_mode,
            "intermediate-only overflow sets sticky OV without saturation");
    require(!data_read && !data_write,
            "intermediate-overflow SUBC is followed by an ACC-free NOP");
    tick();
    require(data_read && data_address == 8'd8,
            "LST reads zero status before the final-shift-only vector");
    tick();
    require(!overflow_flag && !overflow_mode,
            "status reload clears the sticky-overflow test precondition");
    tick();
    tick();
    require(data_read && data_address == 8'd8,
            "final-shift-only vector reads a zero divisor");
    tick();
    require(accumulator == 32'h8000_0001 &&
            !overflow_flag && overflow_mode,
            "provisional policy ignores final-shift overflow and OVM saturation");
    require(!data_read && !data_write,
            "final-shift-only SUBC is followed by an ACC-free NOP");
    tick();
    require(pc == 12'd9 && cycle_count == 32'd9,
            "separated SUBC overflow-stage vectors each retire in one cycle");

    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h6502;  // ZALH 2 -> 0x80000000
    program_memory[1]  = 16'h7f8b;  // SOVM
    program_memory[2]  = 16'h6403;  // provisional intermediate overflow
    program_memory[3]  = 16'h7f80;  // required ACC-free gap
    program_memory[4]  = 16'h6505;  // ZALH 5 -> 0x7fff0000
    program_memory[5]  = 16'h6106;  // ADDS 6 -> 0x7fff8000
    program_memory[6]  = 16'h6404;  // unsigned 0xffff divisor
    program_memory[7]  = 16'h7f80;  // required ACC-free gap
    program_memory[8]  = 16'h6503;  // ZALH 3 -> 0x00010000
    program_memory[9]  = 16'h6e01;  // LDPK 1
    program_memory[10] = 16'h640f;  // SUBC physical word 143
    program_memory[11] = 16'h7f80;  // required ACC-free gap
    program_memory[12] = 16'h6e00;  // LDPK 0
    program_memory[13] = 16'h708f;  // LARK AR0,143
    program_memory[14] = 16'h7108;  // LARK AR1,8
    program_memory[15] = 16'h6880;  // LARP 0
    program_memory[16] = 16'h6507;  // ZALH 7 -> 0x00040000
    program_memory[17] = 16'h64a1;  // SUBC *+,AR1
    program_memory[18] = 16'h7f80;  // required ACC-free gap
    program_memory[19] = 16'h7f89;  // ZAC
    program_memory[20] = 16'h6490;  // SUBC *-,AR0
    program_memory[21] = 16'h7f80;  // required ACC-free gap
    program_memory[22] = 16'h6e01;  // LDPK 1
    program_memory[23] = 16'h6410;  // unresolved physical word 144

    start_initialized_run();
    tick();
    tick();
    require(data_read && data_address == 8'd3 && overflow_mode,
            "OVM is set before the overflow-boundary SUBC");
    tick();
    require(accumulator == 32'hffff_0001 && overflow_flag && overflow_mode,
            "SUBC sets provisional sticky OV but ignores OVM saturation");
    tick();
    tick();
    tick();
    require(accumulator == 32'h7fff_8000,
            "unsigned-divisor boundary setup is exact");
    tick();
    require(accumulator == 32'h0000_0001 && overflow_flag && overflow_mode,
            "SUBC zero-extends 0xffff before its fixed 15-bit shift");
    tick();
    tick();
    tick();
    require(data_page_pointer && data_read &&
            data_address == 8'd143 && data_read_data == 16'h0002,
            "page-one SUBC reaches the final physical RAM word");
    tick();
    require(accumulator == 32'h0000_0001 && overflow_flag,
            "page-one SUBC result and sticky OV are preserved");
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    require(!auxiliary_register_pointer &&
            auxiliary_register_0 == 16'd143 &&
            auxiliary_register_1 == 16'd8,
            "indirect SUBC setup selects AR0");
    require(data_read && data_address == 8'd143,
            "indirect SUBC reads the old selected AR address");
    tick();
    require(accumulator == 32'h0006_0001 &&
            auxiliary_register_0 == 16'd144 &&
            auxiliary_register_pointer,
            "indirect SUBC updates ACC, AR0, and ARP in one cycle");
    tick();
    tick();
    require(data_read && data_address == 8'd8 &&
            data_read_data == 16'h0000,
            "second indirect SUBC uses the newly selected AR1");
    tick();
    require(accumulator == 32'h0000_0001 &&
            auxiliary_register_1 == 16'd7 &&
            !auxiliary_register_pointer,
            "indirect SUBC decrements AR1 and restores AR0 selection");
    tick();
    tick();
    require(data_page_pointer && data_read && !data_address_valid &&
            data_address == 8'd144 && !instruction_valid,
            "unresolved page-one SUBC is visible but cannot execute");
    tick();
    require(illegal && !retired && pc == 12'd23,
            "unresolved SUBC traps without architectural retirement");
    require(cycle_count == 32'd23,
            "only accepted SUBC-program instructions contribute cycles");
    require(t_register == 16'h0000,
            "SUBC preserves initialized T");
    require(product_register == 32'h0000_0000,
            "SUBC preserves initialized P");
    require(data_write_data == accumulator[15:0],
            "inactive write data remains deterministic");
    $display("PASS tb_subc_rtl");
    $finish;
  end
endmodule

`default_nettype wire
