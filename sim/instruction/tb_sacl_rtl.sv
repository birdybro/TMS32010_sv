`default_nettype none

module tb_sacl_rtl;
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

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h7f8b;  // SOVM
    program_memory[1]  = 16'h6e00;  // LDPK 0
    program_memory[2]  = 16'h2003;  // LAC 3
    program_memory[3]  = 16'h5004;  // SACL 4
    program_memory[4]  = 16'h2004;  // LAC 4
    program_memory[5]  = 16'h6e01;  // LDPK 1
    program_memory[6]  = 16'h7e5a;  // LACK 0x5a
    program_memory[7]  = 16'h500f;  // SACL 15 -> physical address 143
    program_memory[8]  = 16'h200f;  // LAC 15
    program_memory[9]  = 16'h718f;  // LARK AR1,143
    program_memory[10] = 16'h6881;  // LARP 1
    program_memory[11] = 16'h7ec3;  // LACK 0xc3
    program_memory[12] = 16'h50a0;  // SACL *+,0,AR0
    program_memory[13] = 16'h200f;  // LAC 15
    program_memory[14] = 16'h7000;  // LARK AR0,0
    program_memory[15] = 16'h7eef;  // LACK 0xef
    program_memory[16] = 16'h5098;  // SACL *-, preserve ARP
    program_memory[17] = 16'h6e00;  // LDPK 0
    program_memory[18] = 16'h2000;  // LAC 0
    program_memory[19] = 16'h6e01;  // LDPK 1
    program_memory[20] = 16'h5010;  // page-one address 144, unresolved

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'd3;
    debug_data         = 16'h8421;
    tick();
    initialize = 1'b0;
    debug_data_write = 1'b0;
    require(!overflow_flag, "explicit initialization clears OV");
    require(!program_read && interrupt_mask,
            "reset suppresses fetch and masks interrupts");
    require(!data_read && !data_write, "reset suppresses logical data access");

    reset = 1'b0;
    tick();
    tick();
    require(!data_page_pointer, "LDPK selects page zero");
    require(data_read && data_address == 8'd3, "LAC source address");
    tick();
    require(accumulator == 32'hffff_8421, "LAC establishes 32-bit store source");

    require(data_write && !data_read && data_address_valid,
            "direct SACL requests a logical write");
    require(data_address == 8'd4 && data_write_data == 16'h8421,
            "direct SACL exposes address and ACC low word");
    tick();
    require(accumulator == 32'hffff_8421, "SACL preserves full accumulator");
    require(overflow_mode, "SACL preserves status");
    require(data_read && data_address == 8'd4,
            "following LAC reads the written address");
    require(data_read_data == 16'h8421, "direct SACL updates internal RAM");
    tick();

    tick();
    require(data_page_pointer, "LDPK selects page one");
    tick();
    require(data_write && data_address == 8'd143,
            "page-one SACL reaches final physical word");
    require(data_write_data == 16'h005a, "page-one SACL writes ACC low");
    tick();
    require(data_read && data_read_data == 16'h005a,
            "page-one write is visible to LAC");
    tick();

    tick();
    tick();
    tick();
    require(auxiliary_register_pointer, "LARP selects AR1");
    require(data_write && data_address == 8'd143,
            "indirect SACL uses preincrement address");
    require(data_write_data == 16'h00c3, "indirect SACL write data");
    tick();
    require(auxiliary_register_1 == 16'd144,
            "indirect increment updates low counter");
    require(!auxiliary_register_pointer, "indirect SACL installs next ARP");
    require(data_read && data_read_data == 16'h00c3,
            "indirect write updates selected word");
    tick();

    tick();
    tick();
    require(data_write && data_address == 8'd0,
            "decrementing SACL uses old address");
    tick();
    require(auxiliary_register_0 == 16'h01ff,
            "decrement wraps the low nine-bit counter");
    require(!auxiliary_register_pointer, "preserve mode retains ARP");

    tick();
    require(!data_page_pointer, "second LDPK selects page zero");
    require(data_read && data_address == 8'd0,
            "direct LAC observes wrapped-store destination");
    require(data_read_data == 16'h00ef, "decrementing SACL updated RAM");
    tick();
    tick();
    require(data_page_pointer, "final LDPK selects page one");

    require(data_write && !data_address_valid,
            "unresolved write address is visible but invalid");
    require(data_address == 8'd144 && data_write_data == 16'h00ef,
            "invalid write is not aliased");
    tick();
    require(illegal && !retired && !instruction_valid,
            "unresolved SACL address traps without write retirement");
    require(pc == 12'd20 && cycle_count == 32'd20,
            "unresolved SACL cannot advance architectural state");

    require(t_register == 16'h0000, "SACL preserves initialized T");
    require(product_register == 32'h0000_0000,
            "SACL preserves initialized P");
    $display("PASS tb_sacl_rtl");
    $finish;
  end
endmodule

`default_nettype wire
