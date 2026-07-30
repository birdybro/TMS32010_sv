`default_nettype none

module tb_zero_loads_rtl;
  logic        clk;
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
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
  logic        data_page_pointer;
  logic        overflow_mode;
  logic        interrupt_mask;
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_core dut (
    .clk_i                         (clk),
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
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (data_page_pointer),
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

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h7107;  // LARK AR1,7
    program_memory[1]  = 16'h7f8b;  // SOVM
    program_memory[2]  = 16'h6503;  // ZALH 3
    program_memory[3]  = 16'h6603;  // ZALS 3
    program_memory[4]  = 16'h6e01;  // LDPK 1
    program_memory[5]  = 16'h650f;  // ZALH 15 -> physical address 143
    program_memory[6]  = 16'h660f;  // ZALS 15 -> physical address 143
    program_memory[7]  = 16'h6e00;  // LDPK 0
    program_memory[8]  = 16'h7007;  // LARK AR0,7
    program_memory[9]  = 16'h6880;  // LARP 0
    program_memory[10] = 16'h65a1;  // ZALH *+,AR1
    program_memory[11] = 16'h6690;  // ZALS *-,AR0
    program_memory[12] = 16'h6e01;  // LDPK 1
    program_memory[13] = 16'h6510;  // unresolved physical address 144

    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'd3;
    debug_data         = 16'hf7ff;
    tick();
    debug_data_address = 8'd143;
    debug_data         = 16'h8421;
    tick();
    debug_data_address = 8'd7;
    debug_data         = 16'h1234;
    tick();
    debug_data_write = 1'b0;
    require(!program_read && interrupt_mask,
            "reset suppresses fetch and masks interrupts");

    reset = 1'b0;
    tick();
    require(auxiliary_register_1 == 16'd7,
            "setup LARK initializes the otherwise untouched AR1");
    tick();
    require(overflow_mode, "SOVM establishes status-preservation evidence");

    require(data_read && !data_write && data_address_valid,
            "ZALH presents a valid read without a write");
    require(data_address == 8'd3 && data_read_data == 16'hf7ff,
            "direct ZALH reads page-zero data");
    tick();
    require(accumulator == 32'hf7ff_0000 && overflow_mode,
            "ZALH loads the high half, clears low, and preserves OVM");

    require(data_read && !data_write && data_address == 8'd3 &&
            data_write_data == 16'h0000,
            "ZALS uses the same direct data address");
    tick();
    require(accumulator == 32'h0000_f7ff && overflow_mode,
            "ZALS zero-extends and preserves OVM");

    tick();
    require(data_page_pointer && data_read && data_address_valid,
            "LDPK selects page one for the following read");
    require(data_address == 8'd143 && data_read_data == 16'h8421,
            "page-one ZALH reaches the final physical RAM word");
    tick();
    require(accumulator == 32'h8421_0000,
            "page-one ZALH places data in the high half");
    require(data_read && data_address == 8'd143,
            "page-one ZALS reuses the final physical RAM word");
    tick();
    require(accumulator == 32'h0000_8421,
            "page-one ZALS zero-extends the sign-bit-set word");

    tick();
    tick();
    tick();
    require(data_read && data_address == 8'd7 &&
            data_read_data == 16'h1234,
            "indirect ZALH uses the old selected-AR address");
    tick();
    require(accumulator == 32'h1234_0000,
            "indirect ZALH applies the high-half transfer");
    require(auxiliary_register_0 == 16'd8 &&
            auxiliary_register_pointer,
            "ZALH increments AR0 and installs the requested ARP");

    require(data_read && data_address == 8'd7,
            "indirect ZALS selects the new ARP before modification");
    tick();
    require(accumulator == 32'h0000_1234,
            "indirect ZALS applies the low-half zero extension");
    require(auxiliary_register_1 == 16'd6 &&
            !auxiliary_register_pointer,
            "ZALS decrements AR1 and installs the requested ARP");

    tick();
    require(data_read && !data_address_valid && !instruction_valid,
            "unresolved ZALH read is visible but cannot execute");
    require(data_address == 8'd144,
            "unresolved ZALH address is not aliased into physical RAM");
    tick();
    require(illegal && !retired && pc == 12'd13,
            "unresolved ZALH traps without advancing PC");
    require(cycle_count == 32'd13,
            "every accepted ZALH and ZALS consumes one architectural cycle");

    $display("PASS tb_zero_loads_rtl");
    $finish;
  end
endmodule

`default_nettype wire
