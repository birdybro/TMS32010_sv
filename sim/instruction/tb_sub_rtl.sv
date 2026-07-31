`default_nettype none

module tb_sub_rtl;
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
    program_memory[0] = 16'h7e24;  // LACK 0x24
    program_memory[1] = 16'h1000;  // SUB 0
    program_memory[2] = 16'h1301;  // SUB 1,3
    program_memory[3] = 16'h1f06;  // SUB 6,15
    program_memory[4] = 16'h6502;  // ZALH 2
    program_memory[5] = 16'h6103;  // ADDS 3 -> 0x7fffffff
    program_memory[6] = 16'h1001;  // SUB 1 -> positive wrap
    program_memory[7] = 16'h1004;  // SUB 4 -> sticky-OV check
    program_memory[8] = 16'h6505;  // ZALH 5
    program_memory[9] = 16'h1006;  // SUB 6 -> negative wrap

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    load_data(8'd0, 16'h0011);
    load_data(8'd1, 16'hffff);
    load_data(8'd2, 16'h7fff);
    load_data(8'd3, 16'hffff);
    load_data(8'd4, 16'h0000);
    load_data(8'd5, 16'h8000);
    load_data(8'd6, 16'h0001);
    load_data(8'd7, 16'hffff);
    load_data(8'd143, 16'h0002);
    initialize = 1'b0;
    reset      = 1'b0;
    #1;
    require(program_read && interrupt_mask,
            "SUB test begins with an active fetch and masked interrupts");

    tick();
    require(data_read && !data_write && data_address_valid &&
            data_address == 8'd0 && data_read_data == 16'h0011,
            "SUB exposes its selected internal-data word");
    tick();
    require(accumulator == 32'h0000_0013 && !overflow_flag,
            "SUB matches TI's 0x24 minus 0x11 example");
    tick();
    require(accumulator == 32'h0000_001b && !overflow_flag,
            "SUB sign-extends a negative word before shifting");
    tick();
    require(accumulator == 32'hffff_801b && !overflow_flag,
            "SUB supports the maximum documented left shift");
    tick();
    tick();
    require(accumulator == 32'h7fff_ffff,
            "setup reaches the positive subtraction boundary");
    tick();
    require(accumulator == 32'h8000_0000 && overflow_flag &&
            !overflow_mode,
            "OVM-clear positive SUB overflow wraps and sets sticky OV");
    tick();
    require(accumulator == 32'h8000_0000 && overflow_flag,
            "nonoverflowing SUB does not clear sticky OV");
    tick();
    require(accumulator == 32'h8000_0000,
            "negative subtraction boundary setup is exact");
    tick();
    require(accumulator == 32'h7fff_ffff && overflow_flag &&
            !overflow_mode,
            "OVM-clear negative SUB overflow wraps at the opposite endpoint");
    require(pc == 12'd10 && cycle_count == 32'd10,
            "each accepted SUB consumes one architectural cycle");

    program_memory[0]  = 16'h6502;  // ZALH 2
    program_memory[1]  = 16'h6103;  // ADDS 3 -> 0x7fffffff
    program_memory[2]  = 16'h7f8b;  // SOVM
    program_memory[3]  = 16'h1001;  // SUB -1 -> positive saturation
    program_memory[4]  = 16'h6505;  // ZALH 5 -> 0x80000000
    program_memory[5]  = 16'h1006;  // SUB 1 -> negative saturation
    program_memory[6]  = 16'h7f89;  // ZAC
    program_memory[7]  = 16'h6e01;  // LDPK 1
    program_memory[8]  = 16'h110f;  // SUB 15,1 -> physical address 143
    program_memory[9]  = 16'h6e00;  // LDPK 0
    program_memory[10] = 16'h708f;  // LARK AR0,143
    program_memory[11] = 16'h7107;  // LARK AR1,7
    program_memory[12] = 16'h6880;  // LARP 0
    program_memory[13] = 16'h12a1;  // SUB *+,2,AR1
    program_memory[14] = 16'h1090;  // SUB *-,0,AR0
    program_memory[15] = 16'h6e01;  // LDPK 1
    program_memory[16] = 16'h1010;  // unresolved physical address 144

    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    reset      = 1'b0;
    require(!overflow_flag && !overflow_mode,
            "explicit reinitialization begins independent saturation cases");

    tick();
    tick();
    tick();
    tick();
    require(accumulator == 32'h7fff_ffff && overflow_flag && overflow_mode,
            "OVM-set positive SUB overflow saturates at 0x7fffffff");
    tick();
    tick();
    require(accumulator == 32'h8000_0000 && overflow_flag && overflow_mode,
            "OVM-set negative SUB overflow saturates at 0x80000000");

    tick();
    tick();
    require(data_page_pointer && data_read &&
            data_address == 8'd143 && data_read_data == 16'h0002,
            "page-one SUB reaches the final physical word");
    tick();
    require(accumulator == 32'hffff_fffc && overflow_flag,
            "page-one shifted SUB preserves sticky OV");
    tick();
    tick();
    tick();
    tick();
    require(!auxiliary_register_pointer &&
            auxiliary_register_0 == 16'd143 &&
            auxiliary_register_1 == 16'd7,
            "indirect SUB setup selects AR0");
    require(data_read && data_address == 8'd143,
            "indirect SUB reads the selected AR before update");
    tick();
    require(accumulator == 32'hffff_fff4 &&
            auxiliary_register_0 == 16'd144 &&
            auxiliary_register_pointer,
            "indirect shifted SUB increments AR0 and installs AR1");
    require(data_read && data_address == 8'd7 &&
            data_read_data == 16'hffff,
            "second indirect SUB uses newly selected AR1");
    tick();
    require(accumulator == 32'hffff_fff5 &&
            auxiliary_register_1 == 16'd6 &&
            !auxiliary_register_pointer,
            "indirect SUB subtracts -1, decrements AR1, and restores AR0");

    tick();
    require(data_page_pointer && data_read && !data_address_valid &&
            data_address == 8'd144 && !instruction_valid,
            "unresolved page-one SUB is visible but cannot execute");
    tick();
    require(illegal && !retired && pc == 12'd16,
            "unresolved SUB traps without architectural retirement");
    require(cycle_count == 32'd16,
            "only accepted instructions contribute to the cycle count");
    require(data_write_data == accumulator[15:0],
            "inactive write data remains deterministic");

    require(t_register == 16'h0000, "SUB preserves initialized T");
    require(product_register == 32'h0000_0000,
            "SUB preserves initialized P");
    $display("PASS tb_sub_rtl");
    $finish;
  end
endmodule

`default_nettype wire
