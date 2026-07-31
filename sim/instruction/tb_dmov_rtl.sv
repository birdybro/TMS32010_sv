`default_nettype none

module tb_dmov_rtl;
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
    .t_register_o                 (t_register),
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
    program_memory[2]  = 16'h6500;  // ZALH 0 -> 0x7fff0000
    program_memory[3]  = 16'h6101;  // ADDS 1 -> 0x7fffffff
    program_memory[4]  = 16'h6102;  // ADDS 2 -> 0x80000000, OV=1
    program_memory[5]  = 16'h7f8b;  // SOVM
    program_memory[6]  = 16'h7008;  // LARK AR0,8
    program_memory[7]  = 16'h7128;  // LARK AR1,40
    program_memory[8]  = 16'h6880;  // LARP AR0
    program_memory[9]  = 16'h6908;  // DMOV 8 -> 9
    program_memory[10] = 16'h6a09;  // LT 9: read back direct move
    program_memory[11] = 16'h6e01;  // LDPK 1
    program_memory[12] = 16'h6900;  // DMOV 128 -> 129
    program_memory[13] = 16'h6e00;  // LDPK 0
    program_memory[14] = 16'h697f;  // DMOV 127 -> 128
    program_memory[15] = 16'h7008;  // LARK AR0,8
    program_memory[16] = 16'h69a1;  // DMOV *+,AR1
    program_memory[17] = 16'h6e01;  // LDPK 1
    program_memory[18] = 16'h690f;  // DMOV 143 -> unresolved 144

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'd0;
    debug_data         = 16'h0000;
    write_data_word(8'd0, 16'h7fff);
    write_data_word(8'd1, 16'hffff);
    write_data_word(8'd2, 16'h0001);
    write_data_word(8'd8, 16'h0043);
    write_data_word(8'd9, 16'h0002);
    write_data_word(8'd127, 16'hcafe);
    write_data_word(8'd128, 16'hbeef);
    write_data_word(8'd129, 16'h1111);
    write_data_word(8'd143, 16'hface);
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    tick();
    require(!program_read && interrupt_mask,
            "reset suppresses fetch and masks interrupts");

    reset = 1'b0;
    repeat (9) tick();
    require(pc == 12'd9 && cycle_count == 32'd9 &&
            accumulator == 32'h8000_0000 &&
            t_register == 16'h0001 && product_register == 32'd15 &&
            auxiliary_register_0 == 16'd8 &&
            auxiliary_register_1 == 16'd40 &&
            !auxiliary_register_pointer && !data_page_pointer &&
            overflow_flag && overflow_mode && interrupt_mask,
            "DMOV setup establishes nontrivial unrelated state");
    require(data_read && data_write && data_address_valid &&
            data_write_address_valid && data_address == 8'd8 &&
            data_write_address == 8'd9 && data_read_data == 16'h0043 &&
            data_write_data == 16'h0043 && instruction_valid,
            "DMOV exposes distinct source-read and next-address write");

    tick();
    require(retired && pc == 12'd10 && cycle_count == 32'd10,
            "DMOV retires in exactly one cycle");
    require(accumulator == 32'h8000_0000 &&
            t_register == 16'h0001 && product_register == 32'd15 &&
            auxiliary_register_0 == 16'd8 &&
            auxiliary_register_1 == 16'd40 &&
            !auxiliary_register_pointer && !data_page_pointer &&
            overflow_flag && overflow_mode && interrupt_mask,
            "direct DMOV preserves arithmetic, address, and status state");
    require(data_read && !data_write && data_address == 8'd9 &&
            data_read_data == 16'h0043,
            "the following read observes DMOV's committed destination");

    tick();
    tick();
    require(data_page_pointer && t_register == 16'h0043,
            "readback and page-one setup retire normally");
    require(data_read && data_write && data_address == 8'd128 &&
            data_write_address == 8'd129 &&
            data_read_data == 16'hbeef && data_write_data == 16'hbeef,
            "page-one DMOV uses the complete eight-bit internal address");

    tick();
    tick();
    require(!data_page_pointer,
            "page-zero setup does not disturb DMOV arithmetic state");
    require(data_read && data_write && data_address == 8'd127 &&
            data_write_address == 8'd128 &&
            data_read_data == 16'hcafe && data_write_data == 16'hcafe,
            "DMOV crosses the 127-to-128 data-page boundary");

    tick();
    tick();
    require(data_read && data_write && data_address == 8'd8 &&
            data_write_address == 8'd9 &&
            data_read_data == 16'h0043 && data_write_data == 16'h0043,
            "indirect DMOV reads from the old selected AR");
    tick();
    require(auxiliary_register_0 == 16'd9 &&
            auxiliary_register_1 == 16'd40 &&
            auxiliary_register_pointer,
            "DMOV completes its move before common AR/ARP post-update");
    require(accumulator == 32'h8000_0000 &&
            t_register == 16'h0043 && product_register == 32'd15 &&
            overflow_flag && overflow_mode,
            "all DMOV variants preserve unrelated arithmetic state");

    tick();
    require(data_page_pointer && pc == 12'd18 && cycle_count == 32'd18,
            "accepted setup and DMOV instructions each consume one cycle");
    require(data_read && data_write && data_address_valid &&
            !data_write_address_valid && !instruction_valid &&
            data_address == 8'd143 && data_write_address == 8'd144 &&
            data_read_data == 16'hface,
            "unresolved DMOV destination is explicit before execution");
    tick();
    require(illegal && !retired && pc == 12'd18 &&
            cycle_count == 32'd18,
            "unresolved DMOV destination traps without retirement");
    require(accumulator == 32'h8000_0000 &&
            t_register == 16'h0043 && product_register == 32'd15 &&
            auxiliary_register_0 == 16'd9 &&
            auxiliary_register_1 == 16'd40 &&
            auxiliary_register_pointer && data_page_pointer &&
            overflow_flag && overflow_mode && interrupt_mask,
            "failed DMOV changes no architectural state");

    $display("PASS tb_dmov_rtl");
    $finish;
  end
endmodule

`default_nettype wire
