`default_nettype none

module tb_lac_rtl;
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
  logic [15:0] t_register;
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
    .t_register_o                  (t_register),
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
    program_memory[0]  = 16'h7f8b;  // SOVM
    program_memory[1]  = 16'h6e00;  // LDPK 0
    program_memory[2]  = 16'h2f03;  // LAC 3,15
    program_memory[3]  = 16'h6e01;  // LDPK 1
    program_memory[4]  = 16'h200f;  // LAC 15 -> physical address 143
    program_memory[5]  = 16'h718f;  // LARK AR1,143
    program_memory[6]  = 16'h6881;  // LARP 1
    program_memory[7]  = 16'h24a0;  // LAC *+,4,0
    program_memory[8]  = 16'h7000;  // LARK AR0,0
    program_memory[9]  = 16'h2098;  // LAC *-,0, preserve ARP
    program_memory[10] = 16'h2010;  // page-one address 144, unresolved

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    tick();
    initialize = 1'b0;
    require(!overflow_flag, "explicit initialization clears OV");
    require(!program_read && interrupt_mask && !data_write,
            "reset control outputs");
    load_data(8'd3, 16'h8000);
    load_data(8'd143, 16'h1234);
    load_data(8'd0, 16'hff80);

    reset = 1'b0;
    tick();
    require(overflow_mode, "SOVM establishes overflow mode");
    tick();
    require(retired && !data_page_pointer, "LDPK selects page zero");

    require(data_read && data_address_valid, "direct LAC requests valid RAM");
    require(data_address == 8'd3, "direct LAC exposes address three");
    require(data_read_data == 16'h8000, "direct LAC exposes RAM operand");
    tick();
    require(accumulator == 32'hc000_0000,
            "LAC sign extends before maximum shift");
    require(data_write_data == accumulator[15:0],
            "inactive logical write data follows ACC low");
    require(pc == 12'd3 && cycle_count == 32'd3, "direct LAC is one cycle");
    require(overflow_mode, "LAC does not change overflow mode");

    tick();
    require(data_page_pointer, "LDPK selects page one");
    require(data_read && data_address == 8'd143,
            "page-one direct LAC reaches last physical word");
    tick();
    require(accumulator == 32'h0000_1234, "page-one direct LAC loads word");

    tick();
    tick();
    require(auxiliary_register_pointer, "LARP selects AR1");
    require(data_read && data_address == 8'd143,
            "indirect LAC uses preincrement address");
    tick();
    require(accumulator == 32'h0001_2340, "indirect LAC shifts operand");
    require(auxiliary_register_1 == 16'd144,
            "indirect increment updates low counter");
    require(!auxiliary_register_pointer, "indirect LAC installs next ARP");

    tick();
    require(data_read && data_address == 8'd0, "decrement reads old address");
    tick();
    require(accumulator == 32'hffff_ff80, "indirect negative load");
    require(auxiliary_register_0 == 16'h01ff,
            "decrement wraps the low nine-bit counter");
    require(!auxiliary_register_pointer, "preserve mode retains ARP");
    require(overflow_mode, "indirect LAC does not change overflow mode");

    require(data_read && !data_address_valid,
            "unresolved address is visible but invalid");
    require(data_address == 8'd144, "invalid direct address is not aliased");
    tick();
    require(illegal && !retired && !instruction_valid,
            "unresolved RAM address traps");
    require(pc == 12'd10 && cycle_count == 32'd10,
            "unresolved address cannot retire or advance PC");

    require(t_register == 16'h0000, "LAC preserves initialized T");
    $display("PASS tb_lac_rtl");
    $finish;
  end
endmodule

`default_nettype wire
