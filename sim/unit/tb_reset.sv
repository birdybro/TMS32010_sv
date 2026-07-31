`default_nettype none

// CTRL-001 architectural reset boundary. This test deliberately distinguishes
// documented physical-reset effects from the current provisional retention
// policy for state whose reset value TI does not list.
module tb_reset;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic        int_n;
  logic [15:0] program_data;
  logic [11:0] program_address;
  logic        program_read;
  logic        program_write;
  logic        io_read;
  logic        io_write;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
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
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        overflow_flag;
  logic        overflow_mode;
  logic        interrupt_mask;
  logic        interrupt_pending;
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
    .int_i                         (int_n),
    .program_address_o             (program_address),
    .program_next_address_o        (),
    .program_read_o                (program_read),
    .program_write_o               (program_write),
    .program_write_data_o          (),
    .program_data_i                (program_data),
    .io_port_o                     (),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (),
    .io_read_data_i                (16'h0000),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
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
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
    .overflow_flag_o               (overflow_flag),
    .overflow_mode_o               (overflow_mode),
    .interrupt_mask_o              (interrupt_mask),
    .interrupt_pending_o           (interrupt_pending),
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

  task automatic preload(
    input logic [7:0] address,
    input logic [15:0] value
  );
    debug_data_address = address;
    debug_data         = value;
    debug_data_write   = 1'b1;
    tick();
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7012;  // LARK AR0,0x12
    program_memory[1] = 16'h7134;  // LARK AR1,0x34
    program_memory[2] = 16'h6a05;  // LT 5
    program_memory[3] = 16'h8003;  // MPYK 3
    program_memory[4] = 16'h7ea5;  // LACK 0xa5
    program_memory[5] = 16'h7b06;  // LST 6
    program_memory[6] = 16'hf800;  // CALL
    program_memory[7] = 16'h0009;  // target 9, return address 8
    program_memory[9] = 16'h7f83;  // primary-unlisted: conservative trap

    initialize        = 1'b1;
    reset             = 1'b1;
    clock_enable      = 1'b1;
    int_n             = 1'b1;
    debug_data_write  = 1'b0;
    debug_data_address = 8'h00;
    debug_data        = 16'h0000;
    tick();
    initialize = 1'b0;

    // The preload port is explicitly nonarchitectural. Physical reset does
    // not clear internal RAM, so preload while reset holds execution inactive.
    preload(8'd5, 16'h0003);
    preload(8'd6, 16'hc101);   // OV=1, OVM=1, ARP=1, DP=1
    preload(8'd133, 16'hbeef); // page-one offset 5
    debug_data_write = 1'b0;

    require(!program_read && !program_write && !io_read && !io_write,
            "reset suppresses every external transaction class");
    require(!data_read && !data_write && interrupt_mask,
            "reset suppresses internal transactions and sets INTM");

    reset = 1'b0;
    repeat (6) tick();
    require(pc == 12'h006 && accumulator == 32'h0000_00a5,
            "setup establishes nonzero accumulator and reaches CALL");
    require(t_register == 16'h0003 && product_register == 32'h0000_0009,
            "setup establishes nonzero T and P");
    require(auxiliary_register_0 == 16'h0012 &&
            auxiliary_register_1 == 16'h0034 &&
            auxiliary_register_pointer && data_page_pointer,
            "setup establishes both auxiliary registers, ARP, and DP");
    require(overflow_flag && overflow_mode,
            "LST establishes nonzero OV and OVM");

    tick();
    require(pc == 12'h007 && !retired,
            "CALL opcode waits for its following target word");
    tick();
    require(pc == 12'h009 && stack_top == 12'h008 && retired,
            "CALL establishes a nonzero stack entry before reset");

    int_n = 1'b0;
    tick();
    require(illegal && !retired && pc == 12'h009,
            "unsupported word establishes trap state without retirement");
    require(interrupt_pending,
            "active interrupt level establishes pending state while masked");

    // reset_i is the already-recognized architectural reset boundary. It has
    // priority over the execution enable. The native wrapper separately tests
    // the five-cycle assertion and falling-CLKOUT recognition sequence.
    clock_enable = 1'b0;
    reset        = 1'b1;
    tick();
    require(pc == 12'h000 && interrupt_mask && !interrupt_pending,
            "physical reset clears PC/IF and sets INTM");
    require(!illegal && !retired && cycle_count == 32'h0000_0000,
            "physical reset clears control/trap bookkeeping");
    require(!program_read && !program_write && !io_read && !io_write &&
            !data_read && !data_write,
            "physical reset leaves all transaction enables inactive");
    require(!instruction_valid,
            "physical reset cannot advertise an executable instruction");

    // TI explicitly states OVM is unchanged. Retention of the other unlisted
    // state is the current PROVISIONAL FPGA policy under OQ-012, not a claim
    // about power-up or original-silicon reset behavior.
    require(accumulator == 32'h0000_00a5 && t_register == 16'h0003 &&
            product_register == 32'h0000_0009,
            "physical reset retains unlisted datapath state provisionally");
    require(auxiliary_register_0 == 16'h0012 &&
            auxiliary_register_1 == 16'h0034 &&
            auxiliary_register_pointer && data_page_pointer,
            "physical reset retains unlisted address state provisionally");
    require(stack_top == 12'h008 && stack_level_1 == 12'h000 &&
            stack_level_2 == 12'h000 && stack_bottom == 12'h000,
            "physical reset retains unlisted stack state provisionally");
    require(overflow_flag && overflow_mode,
            "physical reset preserves OVM and provisionally retains OV");

    // Release at the core boundary and consume page-one RAM. This proves that
    // neither physical reset nor the control reset path initialized RAM.
    program_memory[0] = 16'h6a05;  // LT 5 -> retained DP selects address 133
    int_n        = 1'b1;
    reset        = 1'b0;
    clock_enable = 1'b1;
    #1;
    require(instruction_valid && data_read && data_address_valid &&
            data_address == 8'd133,
            "reset release observes retained DP in direct addressing");
    tick();
    require(retired && pc == 12'h001,
            "core-boundary reset release retires address-zero LT");
    require(t_register == 16'hbeef,
            "reset release observes retained internal RAM contents");
    require(accumulator == 32'h0000_00a5 && overflow_mode,
            "post-reset LT preserves retained accumulator and OVM");

    $display("PASS tb_reset");
    $finish;
  end
endmodule

`default_nettype wire
