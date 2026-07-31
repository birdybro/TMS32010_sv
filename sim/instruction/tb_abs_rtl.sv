`default_nettype none

module tb_abs_rtl;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic [11:0] program_address;
  logic        program_read;
  logic [15:0] program_data;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [7:0]  data_write_address;
  logic        data_write_address_valid;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic        overflow_flag;
  logic        overflow_mode;
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
    .data_address_o                (),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (data_write_address),
    .data_write_address_valid_o    (data_write_address_valid),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                   (),
    .stack_level_1_o               (),
    .stack_level_2_o               (),
    .stack_bottom_o                (),
    .overflow_flag_o               (overflow_flag),
    .overflow_mode_o               (overflow_mode),
    .interrupt_mask_o              (),
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

  task automatic execute_abs_and_require(
    input logic [31:0] expected_accumulator,
    input logic        expected_ov,
    input logic        expected_ovm,
    input logic [31:0] expected_cycle
  );
    require(program_data == 16'h7f88 && instruction_valid,
            "ABS exact word decodes at its execution boundary");
    require(program_read && !data_read && !data_write &&
            !data_address_valid && !data_write_address_valid,
            "ABS has only its normal program transaction");
    tick();
    require(retired && !illegal,
            "ABS retires without an illegal indication");
    require(accumulator == expected_accumulator,
            "ABS produces the expected signed magnitude");
    require(overflow_flag == expected_ov &&
            overflow_mode == expected_ovm,
            "ABS preserves OV and OVM");
    require(cycle_count == expected_cycle,
            "ABS consumes exactly one instruction cycle");
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h6500;  // ZALH 0 -> 0xffff0000
    program_memory[1]  = 16'h7f88;  // ordinary negative ABS
    program_memory[2]  = 16'h7f88;  // nonnegative ABS
    program_memory[3]  = 16'h7b03;  // LST 3 -> OV=1, OVM=1
    program_memory[4]  = 16'h6501;  // ZALH 1 -> 0x80000000
    program_memory[5]  = 16'h7f88;  // OVM saturation
    program_memory[6]  = 16'h7f8a;  // ROVM, preserve OV
    program_memory[7]  = 16'h6501;  // restore most-negative ACC
    program_memory[8]  = 16'h7f88;  // OVM-clear wrap
    program_memory[9]  = 16'h7b04;  // LST 4 -> OV=0, OVM=0
    program_memory[10] = 16'h7f88;  // preserve clear OV
    program_memory[11] = 16'h7f8b;  // SOVM
    program_memory[12] = 16'h7f88;  // saturate while OV remains clear
    program_memory[13] = 16'h7f89;  // ZAC
    program_memory[14] = 16'h7f88;  // zero remains zero
    program_memory[15] = 16'h7f83;  // unsupported control word

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'd0;
    debug_data         = 16'hffff;
    tick();
    debug_data_address = 8'd1;
    debug_data         = 16'h8000;
    tick();
    debug_data_address = 8'd3;
    debug_data         = 16'hc000;
    tick();
    debug_data_address = 8'd4;
    debug_data         = 16'h0000;
    tick();
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    tick();
    require(!program_read,
            "physical reset suppresses instruction fetch");

    reset = 1'b0;
    tick();
    require(accumulator == 32'hffff_0000 && cycle_count == 32'd1,
            "ZALH establishes an ordinary negative input");
    execute_abs_and_require(32'h0001_0000, 1'b0, 1'b0, 32'd2);
    execute_abs_and_require(32'h0001_0000, 1'b0, 1'b0, 32'd3);

    tick();
    require(overflow_flag && overflow_mode && cycle_count == 32'd4,
            "LST establishes set OV and OVM");
    tick();
    require(accumulator == 32'h8000_0000 && cycle_count == 32'd5,
            "ZALH establishes the most-negative input");
    execute_abs_and_require(32'h7fff_ffff, 1'b1, 1'b1, 32'd6);

    tick();
    require(overflow_flag && !overflow_mode && cycle_count == 32'd7,
            "ROVM clears only the mode bit");
    tick();
    execute_abs_and_require(32'h8000_0000, 1'b1, 1'b0, 32'd9);

    tick();
    require(!overflow_flag && !overflow_mode && cycle_count == 32'd10,
            "LST establishes clear OV and OVM");
    execute_abs_and_require(32'h8000_0000, 1'b0, 1'b0, 32'd11);

    tick();
    require(!overflow_flag && overflow_mode && cycle_count == 32'd12,
            "SOVM preserves clear OV");
    execute_abs_and_require(32'h7fff_ffff, 1'b0, 1'b1, 32'd13);

    tick();
    require(accumulator == 32'h0000_0000 && cycle_count == 32'd14,
            "ZAC establishes zero");
    execute_abs_and_require(32'h0000_0000, 1'b0, 1'b1, 32'd15);

    require(!instruction_valid,
            "adjacent unsupported control word remains invalid");
    tick();
    require(illegal && !retired && pc == 12'd15 && cycle_count == 32'd15,
            "unsupported word traps without changing ABS results");

    $display("PASS tb_abs_rtl");
    $finish;
  end
endmodule

`default_nettype wire
