`default_nettype none

module tb_subh_rtl;
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
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
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
    .stack_top_o                   (),
    .stack_level_1_o               (),
    .stack_level_2_o               (),
    .stack_bottom_o                (),
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
    program_memory[0] = 16'h6500;  // ZALH 0
    program_memory[1] = 16'h6101;  // ADDS 1
    program_memory[2] = 16'h6202;  // SUBH 2, TI high-half example
    program_memory[3] = 16'h6503;  // ZALH 3
    program_memory[4] = 16'h6104;  // ADDS 4
    program_memory[5] = 16'h6205;  // SUBH 5, negative wrap
    program_memory[6] = 16'h6206;  // SUBH 6, sticky-OV check

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    load_data(8'd0, 16'h0017);
    load_data(8'd1, 16'h4567);
    load_data(8'd2, 16'h0005);
    load_data(8'd3, 16'h8000);
    load_data(8'd4, 16'h1234);
    load_data(8'd5, 16'h0001);
    load_data(8'd6, 16'h0000);
    load_data(8'd7, 16'h7fff);
    load_data(8'd8, 16'hffff);
    load_data(8'd143, 16'h0002);
    initialize = 1'b0;
    reset      = 1'b0;
    #1;
    require(program_read && interrupt_mask,
            "SUBH test begins with an active fetch and masked interrupts");

    tick();
    tick();
    require(data_read && !data_write && data_address_valid &&
            data_address == 8'd2 && data_read_data == 16'h0005,
            "SUBH presents its selected internal-data word");
    tick();
    require(accumulator == 32'h0012_4567 && !overflow_flag,
            "SUBH matches TI high-half subtraction and preserves ACC low");
    tick();
    tick();
    tick();
    require(accumulator == 32'h7fff_1234 && overflow_flag &&
            !overflow_mode,
            "OVM-clear SUBH negative overflow wraps and preserves ACC low");
    tick();
    require(accumulator == 32'h7fff_1234 && overflow_flag,
            "nonoverflowing SUBH does not clear sticky OV");
    require(pc == 12'd7 && cycle_count == 32'd7,
            "each accepted SUBH consumes one architectural cycle");

    program_memory[0] = 16'h6503;  // ZALH 3
    program_memory[1] = 16'h6104;  // ADDS 4
    program_memory[2] = 16'h7f8b;  // SOVM
    program_memory[3] = 16'h6205;  // negative saturation
    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    reset      = 1'b0;

    tick();
    tick();
    tick();
    tick();
    require(accumulator == 32'h8000_0000 && overflow_flag && overflow_mode,
            "OVM-set SUBH negative overflow replaces the full accumulator");

    program_memory[0] = 16'h6507;  // ZALH 7
    program_memory[1] = 16'h6104;  // ADDS 4
    program_memory[2] = 16'h6208;  // positive wrap via negative operand
    initialize = 1'b1;
    tick();
    initialize = 1'b0;

    tick();
    tick();
    tick();
    require(accumulator == 32'h8000_1234 && overflow_flag &&
            !overflow_mode,
            "OVM-clear SUBH positive overflow wraps and preserves ACC low");

    program_memory[0] = 16'h6507;  // ZALH 7
    program_memory[1] = 16'h6104;  // ADDS 4
    program_memory[2] = 16'h7f8b;  // SOVM
    program_memory[3] = 16'h6208;  // positive saturation
    initialize = 1'b1;
    tick();
    initialize = 1'b0;

    tick();
    tick();
    tick();
    tick();
    require(accumulator == 32'h7fff_ffff && overflow_flag && overflow_mode,
            "OVM-set SUBH positive overflow replaces the full accumulator");

    program_memory[0]  = 16'h7f89;  // ZAC
    program_memory[1]  = 16'h6e01;  // LDPK 1
    program_memory[2]  = 16'h620f;  // SUBH 15 -> physical address 143
    program_memory[3]  = 16'h6e00;  // LDPK 0
    program_memory[4]  = 16'h708f;  // LARK AR0,143
    program_memory[5]  = 16'h7108;  // LARK AR1,8
    program_memory[6]  = 16'h6880;  // LARP 0
    program_memory[7]  = 16'h62a1;  // SUBH *+,AR1
    program_memory[8]  = 16'h6290;  // SUBH *-,AR0
    program_memory[9]  = 16'h6e01;  // LDPK 1
    program_memory[10] = 16'h6210;  // unresolved physical address 144
    initialize = 1'b1;
    tick();
    initialize = 1'b0;

    tick();
    tick();
    require(data_page_pointer && data_read &&
            data_address == 8'd143 && data_read_data == 16'h0002,
            "page-one SUBH reaches the final physical word");
    tick();
    require(accumulator == 32'hfffe_0000 && !overflow_flag,
            "page-one SUBH aligns its source to ACC high");
    tick();
    tick();
    tick();
    tick();
    require(!auxiliary_register_pointer &&
            auxiliary_register_0 == 16'd143 &&
            auxiliary_register_1 == 16'd8,
            "indirect SUBH setup selects AR0");
    require(data_read && data_address == 8'd143,
            "indirect SUBH reads the selected AR before update");
    tick();
    require(accumulator == 32'hfffc_0000 &&
            auxiliary_register_0 == 16'd144 &&
            auxiliary_register_pointer,
            "indirect SUBH increments AR0 and installs AR1");
    require(data_read && data_address == 8'd8 &&
            data_read_data == 16'hffff,
            "second indirect SUBH uses newly selected AR1");
    tick();
    require(accumulator == 32'hfffd_0000 &&
            auxiliary_register_1 == 16'd7 &&
            !auxiliary_register_pointer,
            "indirect SUBH decrements AR1 and restores AR0");

    tick();
    require(data_page_pointer && data_read && !data_address_valid &&
            data_address == 8'd144 && !instruction_valid,
            "unresolved page-one SUBH is visible but cannot execute");
    tick();
    require(illegal && !retired && pc == 12'd10,
            "unresolved SUBH traps without architectural retirement");
    require(cycle_count == 32'd10,
            "only accepted instructions contribute to the cycle count");
    require(t_register == 16'h0000, "SUBH preserves initialized T");
    require(product_register == 32'h0000_0000,
            "SUBH preserves initialized P");
    require(data_write_data == accumulator[15:0],
            "inactive write data remains deterministic");

    $display("PASS tb_subh_rtl");
    $finish;
  end
endmodule

`default_nettype wire
