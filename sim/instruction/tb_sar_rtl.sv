`default_nettype none

module tb_sar_rtl;
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
    program_memory[0]  = 16'h7f8b;  // SOVM
    program_memory[1]  = 16'h7ea5;  // LACK 0xa5
    program_memory[2]  = 16'h3901;  // LAR AR1,1 -> 0xfedc
    program_memory[3]  = 16'h6e01;  // LDPK 1
    program_memory[4]  = 16'h310e;  // SAR AR1,14 -> data address 142
    program_memory[5]  = 16'h390e;  // LAR AR1,14 -> read stored word
    program_memory[6]  = 16'h6e00;  // LDPK 0
    program_memory[7]  = 16'h700a;  // LARK AR0,10
    program_memory[8]  = 16'h6880;  // LARP AR0
    program_memory[9]  = 16'h30a8;  // SAR AR0,*+
    program_memory[10] = 16'h390a;  // LAR AR1,10 -> read stored word
    program_memory[11] = 16'h700a;  // LARK AR0,10
    program_memory[12] = 16'h6880;  // LARP AR0
    program_memory[13] = 16'h3098;  // SAR AR0,*-
    program_memory[14] = 16'h700a;  // LARK AR0,10
    program_memory[15] = 16'h7155;  // LARK AR1,0x55
    program_memory[16] = 16'h6880;  // LARP AR0
    program_memory[17] = 16'h3198;  // SAR AR1,*-
    program_memory[18] = 16'h390a;  // LAR AR1,10 -> read stored word
    program_memory[19] = 16'h6e01;  // LDPK 1
    program_memory[20] = 16'h317f;  // SAR AR1,127 -> unresolved 255

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    load_data(8'd1, 16'hfedc);
    initialize = 1'b0;
    reset      = 1'b0;

    tick();  // SOVM
    tick();  // LACK
    tick();  // LAR AR1,1
    tick();  // LDPK 1
    require(
      program_read && !data_read && data_write && instruction_valid &&
      data_address_valid && data_address == 8'd142 &&
      data_write_data == 16'hfedc,
      "direct SAR presents the complete AR1 value at the DP-selected address"
    );
    tick();  // direct SAR AR1,14
    require(
      retired && auxiliary_register_1 == 16'hfedc,
      "direct SAR preserves its source auxiliary register"
    );
    require(
      accumulator == 32'h0000_00a5 && overflow_mode && !overflow_flag &&
      data_page_pointer && interrupt_mask,
      "SAR preserves accumulator, status, data page, and interrupt mask"
    );
    require(
      data_read && data_address == 8'd142 && data_read_data == 16'hfedc,
      "the following LAR observes the complete direct SAR write"
    );

    tick();  // LAR AR1,14
    tick();  // LDPK 0
    tick();  // LARK AR0,10
    tick();  // LARP AR0
    require(
      data_write && data_address_valid && data_address == 8'd10 &&
      data_write_data == 16'd11,
      "same-target SAR writes the incremented value at the old address"
    );
    tick();  // SAR AR0,*+
    require(
      auxiliary_register_0 == 16'd11 && data_read_data == 16'd11,
      "same-target SAR updates AR0 and memory to the same incremented value"
    );

    tick();  // LAR AR1,10
    tick();  // LARK AR0,10
    tick();  // LARP AR0
    require(
      data_write && data_address_valid && data_address == 8'd10 &&
      data_write_data == 16'd9,
      "same-target SAR writes the decremented value at the old address"
    );
    tick();  // SAR AR0,*-
    require(
      auxiliary_register_0 == 16'd9,
      "same-target decrement updates the selected source register"
    );

    tick();  // LARK AR0,10
    tick();  // LARK AR1,0x55
    tick();  // LARP AR0
    require(
      data_write && data_address_valid && data_address == 8'd10 &&
      data_write_data == 16'h0055,
      "other-target SAR stores the designated AR without modifying its value"
    );
    tick();  // SAR AR1,*-
    require(
      auxiliary_register_0 == 16'd9 &&
      auxiliary_register_1 == 16'h0055,
      "other-target SAR decrements only the selected address register"
    );
    require(
      data_read_data == 16'h0055 && !auxiliary_register_pointer,
      "other-target SAR writes memory and preserve form leaves ARP unchanged"
    );

    tick();  // LAR AR1,10
    tick();  // LDPK 1
    require(
      data_write && !data_address_valid && data_address == 8'hff,
      "out-of-range direct SAR exposes unresolved logical address"
    );
    tick();  // unresolved SAR traps
    require(illegal && !retired, "unresolved SAR traps without retirement");
    require(pc == 12'd20, "unresolved SAR holds PC");
    require(cycle_count == 32'd20, "unresolved SAR does not count a cycle");
    require(
      auxiliary_register_0 == 16'd9 &&
      auxiliary_register_1 == 16'h0055,
      "unresolved SAR leaves both auxiliary registers unchanged"
    );

    require(t_register == 16'h0000, "SAR preserves initialized T");
    require(product_register == 32'h0000_0000,
            "SAR preserves initialized P");
    $display("PASS tb_sar_rtl");
    $finish;
  end
endmodule

`default_nettype wire
