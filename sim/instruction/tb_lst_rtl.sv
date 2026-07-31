`default_nettype none

module tb_lst_rtl;
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

  task automatic require_lst_read(
    input logic [7:0] expected_address,
    input logic [15:0] expected_word,
    input string label
  );
    require(program_read, {label, " keeps the program fetch active"});
    require(data_read && !data_write && data_address_valid,
            {label, " exposes one read-only logical data transaction"});
    require(data_address == expected_address && data_read_data == expected_word,
            {label, " selects the expected pre-state address and word"});
    require(!data_write_address_valid,
            {label, " has no logical data write destination"});
    require(data_write_data == accumulator[15:0],
            {label, " leaves the inactive write datapath unchanged"});
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h7e5a;  // LACK 0x5a
    program_memory[1]  = 16'h7f8b;  // SOVM
    program_memory[2]  = 16'h6e01;  // LDPK 1
    program_memory[3]  = 16'h7f82;  // EINT
    program_memory[4]  = 16'h7b0f;  // LST 15, old DP selects address 143
    program_memory[5]  = 16'h7b7f;  // LST 127, new DP selects address 127
    program_memory[6]  = 16'h7005;  // LARK AR0,5
    program_memory[7]  = 16'h7106;  // LARK AR1,6
    program_memory[8]  = 16'h6880;  // LARP 0
    program_memory[9]  = 16'h7ba1;  // LST *+,AR1; source ARP=0 wins
    program_memory[10] = 16'h6881;  // LARP 1
    program_memory[11] = 16'h7b90;  // LST *-,AR0; source ARP=1 wins
    program_memory[12] = 16'h7b10;  // unresolved physical address 144

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'd143;
    debug_data         = 16'ha100;  // OV=1 OVM=0 INTM-source=1 ARP=1 DP=0
    tick();
    initialize = 1'b0;
    debug_data_address = 8'd127;
    debug_data         = 16'h6101;  // OV=0 OVM=1 INTM-source=1 ARP=1 DP=1
    tick();
    debug_data_address = 8'd5;
    debug_data         = 16'h8000;  // OV=1 OVM=0 ARP=0 DP=0
    tick();
    debug_data_address = 8'd6;
    debug_data         = 16'h4101;  // OV=0 OVM=1 ARP=1 DP=1
    tick();
    debug_data_write = 1'b0;
    require(!program_read && interrupt_mask,
            "reset suppresses fetch and masks interrupts");

    reset = 1'b0;
    for (int unsigned index = 0; index < 4; index++) begin
      tick();
    end
    require(pc == 12'd4 && !interrupt_mask && data_page_pointer &&
            overflow_mode && !overflow_flag,
            "setup establishes nontrivial status and cleared INTM");
    require_lst_read(8'd143, 16'ha100, "direct LST");

    clock_enable = 1'b0;
    for (int unsigned index = 0; index < 3; index++) begin
      tick();
      require(!retired && pc == 12'd4 && cycle_count == 32'd4,
              "clock-enable stall holds direct LST at its boundary");
      require(!interrupt_mask && data_page_pointer &&
              overflow_mode && !overflow_flag,
              "clock-enable stall preserves pre-LST status");
      require_lst_read(8'd143, 16'ha100, "stalled direct LST");
    end
    clock_enable = 1'b1;
    tick();
    require(retired && pc == 12'd5 && cycle_count == 32'd5,
            "direct LST consumes exactly one accepted cycle");
    require(overflow_flag && !overflow_mode &&
            auxiliary_register_pointer && !data_page_pointer &&
            !interrupt_mask,
            "LST loads OV/OVM/ARP/DP and preserves INTM");
    require_lst_read(8'd127, 16'h6101,
                     "following direct LST with newly loaded DP");

    tick();
    require(!overflow_flag && overflow_mode &&
            auxiliary_register_pointer && data_page_pointer &&
            !interrupt_mask,
            "second direct LST loads defined fields and ignores source INTM");

    tick();
    tick();
    tick();
    require(pc == 12'd9 && auxiliary_register_0 == 16'd5 &&
            auxiliary_register_1 == 16'd6 && !auxiliary_register_pointer,
            "LARK/LARP setup selects AR0 without disturbing loaded status");
    require_lst_read(8'd5, 16'h8000, "incrementing indirect LST");

    tick();
    require(auxiliary_register_0 == 16'd6 &&
            !auxiliary_register_pointer &&
            overflow_flag && !overflow_mode && !data_page_pointer &&
            !interrupt_mask,
            "LST increments old AR0 while memory ARP=0 overrides encoded AR1");

    tick();
    require(auxiliary_register_pointer,
            "explicit LARP selects AR1 for the decrementing case");
    require_lst_read(8'd6, 16'h4101, "decrementing indirect LST");

    tick();
    require(auxiliary_register_1 == 16'd5 &&
            auxiliary_register_pointer &&
            !overflow_flag && overflow_mode && data_page_pointer &&
            !interrupt_mask,
            "LST decrements old AR1 while memory ARP=1 overrides encoded AR0");
    require(accumulator == 32'h0000_005a &&
            t_register == 16'h0000 && product_register == 32'h0000_0000,
            "all LST forms preserve unrelated datapath registers");
    require(data_read && !data_address_valid && !instruction_valid &&
            data_address == 8'd144,
            "unresolved direct LST exposes its address but cannot execute");

    tick();
    require(illegal && !retired && pc == 12'd12 &&
            cycle_count == 32'd12,
            "unresolved LST traps without state or cycle-count changes");
    require(auxiliary_register_0 == 16'd6 &&
            auxiliary_register_1 == 16'd5 &&
            auxiliary_register_pointer &&
            !overflow_flag && overflow_mode && data_page_pointer &&
            !interrupt_mask,
            "unresolved LST produces no architectural side effects");

    $display("PASS tb_lst_rtl");
    $finish;
  end
endmodule

`default_nettype wire
