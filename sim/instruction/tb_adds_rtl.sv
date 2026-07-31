`default_nettype none

module tb_adds_rtl;
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

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7e03;  // LACK 3
    program_memory[1] = 16'h6100;  // ADDS 0
    program_memory[2] = 16'h6502;  // ZALH 2
    program_memory[3] = 16'h6103;  // ADDS 3
    program_memory[4] = 16'h6104;  // ADDS 4, positive overflow
    program_memory[5] = 16'h6105;  // ADDS 5, sticky-OV check

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    load_data(8'd0, 16'hf006);
    load_data(8'd2, 16'h7fff);
    load_data(8'd3, 16'hfffe);
    load_data(8'd4, 16'h0002);
    load_data(8'd5, 16'h0000);
    load_data(8'd7, 16'h1234);
    load_data(8'd143, 16'h0002);
    initialize = 1'b0;
    require(!program_read && interrupt_mask && !overflow_flag &&
            !overflow_mode && accumulator == 32'h0000_0000,
            "explicit initialization establishes deterministic test state");

    reset = 1'b0;
    tick();
    require(accumulator == 32'h0000_0003 && !overflow_flag,
            "LACK establishes the unsigned-add source accumulator");
    require(data_read && !data_write && data_address_valid &&
            data_address == 8'd0 && data_read_data == 16'hf006,
            "ADDS exposes a valid internal-data read");
    tick();
    require(accumulator == 32'h0000_f009,
            "ADDS zero-extends its sign-bit-set source");
    require(!overflow_flag && !overflow_mode,
            "ordinary ADDS preserves clear overflow status");

    tick();
    require(accumulator == 32'h7fff_0000,
            "ZALH establishes the positive overflow boundary");
    tick();
    require(accumulator == 32'h7fff_fffe && !overflow_flag,
            "ADDS reaches the largest-positive boundary without overflow");
    tick();
    require(accumulator == 32'h8000_0000 && overflow_flag,
            "OVM-clear ADDS wraps and sets OV");
    tick();
    require(accumulator == 32'h8000_0000 && overflow_flag,
            "a nonoverflowing ADDS does not clear sticky OV");
    require(pc == 12'd6 && cycle_count == 32'd6,
            "each accepted ADDS consumes one architectural cycle");

    reset = 1'b1;
    tick();
    require(pc == 12'h000 && cycle_count == 32'd0 && interrupt_mask,
            "physical reset applies documented control effects");
    require(accumulator == 32'h8000_0000 && overflow_flag &&
            !overflow_mode,
            "RTL reset assigns no new ACC/OV value and preserves OVM");

    program_memory[0]  = 16'h6502;  // ZALH 2
    program_memory[1]  = 16'h6103;  // ADDS 3 -> 0x7fff_fffe
    program_memory[2]  = 16'h7f8b;  // SOVM
    program_memory[3]  = 16'h6104;  // ADDS 4 -> positive saturation
    program_memory[4]  = 16'h6605;  // ZALS 5
    program_memory[5]  = 16'h6e01;  // LDPK 1
    program_memory[6]  = 16'h610f;  // ADDS 15 -> physical address 143
    program_memory[7]  = 16'h6e00;  // LDPK 0
    program_memory[8]  = 16'h708f;  // LARK AR0,143
    program_memory[9]  = 16'h7107;  // LARK AR1,7
    program_memory[10] = 16'h6880;  // LARP 0
    program_memory[11] = 16'h61a1;  // ADDS *+,AR1
    program_memory[12] = 16'h6190;  // ADDS *-,AR0
    program_memory[13] = 16'h6e01;  // LDPK 1
    program_memory[14] = 16'h6110;  // unresolved physical address 144

    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    reset      = 1'b0;
    require(!overflow_flag && !overflow_mode &&
            accumulator == 32'h0000_0000,
            "explicit reinitialization starts an independent saturation case");

    tick();
    tick();
    tick();
    require(accumulator == 32'h7fff_fffe && overflow_mode &&
            !overflow_flag,
            "SOVM enables saturation after a nonoverflowing boundary add");
    tick();
    require(accumulator == 32'h7fff_ffff && overflow_flag && overflow_mode,
            "OVM-set ADDS saturates to the positive endpoint");
    tick();
    require(accumulator == 32'h0000_0000 && overflow_flag,
            "ZALS changes ACC without clearing sticky OV");
    tick();
    require(data_page_pointer && data_read &&
            data_address == 8'd143 && data_read_data == 16'h0002,
            "page-one ADDS reaches the final physical word");
    tick();
    require(accumulator == 32'h0000_0002 && overflow_flag,
            "page-one ADDS preserves sticky OV");

    tick();
    tick();
    tick();
    tick();
    require(!auxiliary_register_pointer &&
            auxiliary_register_0 == 16'd143 &&
            auxiliary_register_1 == 16'd7,
            "indirect ADDS setup selects AR0");
    require(data_read && data_address == 8'd143,
            "indirect ADDS reads the selected AR before update");
    tick();
    require(accumulator == 32'h0000_0004 &&
            auxiliary_register_0 == 16'd144 &&
            auxiliary_register_pointer,
            "indirect ADDS increments AR0 and installs AR1");
    require(data_read && data_address == 8'd7 &&
            data_read_data == 16'h1234,
            "second indirect ADDS uses the newly selected AR1");
    tick();
    require(accumulator == 32'h0000_1238 &&
            auxiliary_register_1 == 16'd6 &&
            !auxiliary_register_pointer,
            "indirect ADDS decrements AR1 and restores AR0");

    tick();
    require(data_page_pointer && data_read && !data_address_valid &&
            data_address == 8'd144 && !instruction_valid,
            "unresolved page-one ADDS is visible but cannot execute");
    tick();
    require(illegal && !retired && pc == 12'd14,
            "unresolved ADDS traps without architectural retirement");
    require(cycle_count == 32'd14,
            "only accepted instructions contribute to the cycle count");
    require(data_write_data == accumulator[15:0],
            "inactive write data remains a deterministic diagnostic");

    require(t_register == 16'h0000, "ADDS preserves initialized T");
    require(product_register == 32'h0000_0000,
            "ADDS preserves initialized P");
    $display("PASS tb_adds_rtl");
    $finish;
  end
endmodule

`default_nettype wire
