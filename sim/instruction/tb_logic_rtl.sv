`default_nettype none

module tb_logic_rtl;
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
    program_memory[0]  = 16'h6500;  // ZALH 0
    program_memory[1]  = 16'h6101;  // ADDS 1
    program_memory[2]  = 16'h7f8b;  // SOVM
    program_memory[3]  = 16'h6102;  // ADDS 2, positive saturation
    program_memory[4]  = 16'h6503;  // ZALH 3
    program_memory[5]  = 16'h6104;  // ADDS 4
    program_memory[6]  = 16'h7805;  // XOR 5
    program_memory[7]  = 16'h7906;  // AND 6
    program_memory[8]  = 16'h6503;  // ZALH 3
    program_memory[9]  = 16'h6104;  // ADDS 4
    program_memory[10] = 16'h7a07;  // OR 7
    program_memory[11] = 16'h6e01;  // LDPK 1
    program_memory[12] = 16'h780f;  // XOR 15 -> physical address 143
    program_memory[13] = 16'h6e00;  // LDPK 0
    program_memory[14] = 16'h7008;  // LARK AR0,8
    program_memory[15] = 16'h7109;  // LARK AR1,9
    program_memory[16] = 16'h6880;  // LARP 0
    program_memory[17] = 16'h79a1;  // AND *+,AR1
    program_memory[18] = 16'h7a90;  // OR *-,AR0
    program_memory[19] = 16'h6e01;  // LDPK 1
    program_memory[20] = 16'h7810;  // unresolved physical address 144

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    load_data(8'd0, 16'h7fff);
    load_data(8'd1, 16'hfffe);
    load_data(8'd2, 16'h0002);
    load_data(8'd3, 16'h1234);
    load_data(8'd4, 16'h5678);
    load_data(8'd5, 16'hf0f0);
    load_data(8'd6, 16'h00ff);
    load_data(8'd7, 16'hf000);
    load_data(8'd8, 16'h0f0f);
    load_data(8'd9, 16'hf000);
    load_data(8'd143, 16'hffff);
    initialize = 1'b0;
    require(!program_read && interrupt_mask,
            "explicit initialization establishes deterministic control state");
    reset = 1'b0;

    tick();
    tick();
    tick();
    tick();
    require(accumulator == 32'h7fff_ffff && overflow_flag && overflow_mode,
            "setup establishes sticky OV and OVM without wrapping ACC");
    require(data_read && !data_write && data_address == 8'd3,
            "ZALH following the setup exposes its internal read");

    tick();
    tick();
    require(accumulator == 32'h1234_5678 && overflow_flag && overflow_mode,
            "nonlogic setup restores both accumulator halves and status");
    require(data_read && data_address_valid && data_address == 8'd5 &&
            data_read_data == 16'hf0f0,
            "XOR exposes its selected internal-data word");
    tick();
    require(accumulator == 32'h1234_a688,
            "XOR changes the low accumulator half and preserves the high half");
    require(overflow_flag && overflow_mode,
            "XOR leaves OV and OVM unchanged");
    require(data_read && data_address == 8'd6 &&
            data_read_data == 16'h00ff,
            "AND exposes its selected internal-data word");
    tick();
    require(accumulator == 32'h0000_0088,
            "AND masks the low half and clears the high accumulator half");
    require(overflow_flag && overflow_mode,
            "AND leaves OV and OVM unchanged");

    tick();
    tick();
    require(accumulator == 32'h1234_5678,
            "second setup restores a nonzero high accumulator half");
    require(data_read && data_address == 8'd7 &&
            data_read_data == 16'hf000,
            "OR exposes its selected internal-data word");
    tick();
    require(accumulator == 32'h1234_f678,
            "OR changes the low accumulator half and preserves the high half");
    require(overflow_flag && overflow_mode,
            "OR leaves OV and OVM unchanged");

    tick();
    require(data_page_pointer && data_read &&
            data_address == 8'd143 && data_read_data == 16'hffff,
            "page-one XOR reaches the final physical internal word");
    tick();
    require(accumulator == 32'h1234_0987 &&
            overflow_flag && overflow_mode,
            "page-one XOR preserves the high half and arithmetic status");

    tick();
    tick();
    tick();
    tick();
    require(!auxiliary_register_pointer &&
            auxiliary_register_0 == 16'd8 &&
            auxiliary_register_1 == 16'd9,
            "indirect logic setup selects AR0");
    require(data_read && data_address == 8'd8 &&
            data_read_data == 16'h0f0f,
            "indirect AND reads the selected AR before update");
    tick();
    require(accumulator == 32'h0000_0907 &&
            auxiliary_register_0 == 16'd9 &&
            auxiliary_register_pointer,
            "indirect AND increments AR0 and installs AR1");
    require(data_read && data_address == 8'd9 &&
            data_read_data == 16'hf000,
            "indirect OR uses the newly selected AR1");
    tick();
    require(accumulator == 32'h0000_f907 &&
            auxiliary_register_1 == 16'd8 &&
            !auxiliary_register_pointer,
            "indirect OR decrements AR1 and restores AR0");
    require(overflow_flag && overflow_mode,
            "indirect logic preserves sticky arithmetic status");

    tick();
    require(data_page_pointer && data_read && !data_address_valid &&
            data_address == 8'd144 && !instruction_valid,
            "unresolved page-one XOR is visible but cannot execute");
    tick();
    require(illegal && !retired && pc == 12'd20,
            "unresolved XOR traps without architectural retirement");
    require(cycle_count == 32'd20,
            "each accepted logic instruction consumes one cycle");
    require(data_write_data == accumulator[15:0],
            "inactive write data remains deterministic");

    $display("PASS tb_logic_rtl");
    $finish;
  end
endmodule

`default_nettype wire
