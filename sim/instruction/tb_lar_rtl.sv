`default_nettype none

module tb_lar_rtl;
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
    program_memory[1]  = 16'h7ea5;  // LACK 0xa5
    program_memory[2]  = 16'h6e01;  // LDPK 1
    program_memory[3]  = 16'h390e;  // LAR AR1,14 -> data address 142
    program_memory[4]  = 16'h6e00;  // LDPK 0
    program_memory[5]  = 16'h7007;  // LARK AR0,7
    program_memory[6]  = 16'h6880;  // LARP AR0
    program_memory[7]  = 16'h3891;  // LAR AR0,*-,AR1
    program_memory[8]  = 16'h708f;  // LARK AR0,0x8f
    program_memory[9]  = 16'h7155;  // LARK AR1,0x55
    program_memory[10] = 16'h6880;  // LARP AR0
    program_memory[11] = 16'h39a8;  // LAR AR1,*+
    program_memory[12] = 16'h6e01;  // LDPK 1
    program_memory[13] = 16'h387f;  // LAR AR0,127 -> unresolved 255

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    load_data(8'd142, 16'hfedc);
    load_data(8'd7, 16'h1234);
    load_data(8'd143, 16'hcafe);
    initialize = 1'b0;
    reset      = 1'b0;

    tick();  // SOVM
    tick();  // LACK
    tick();  // LDPK 1
    require(
      program_read && data_read && !data_write && instruction_valid &&
      data_address_valid && data_address == 8'd142 &&
      data_read_data == 16'hfedc,
      "direct LAR uses DP and presents a valid internal read"
    );
    require(
      data_page_pointer && interrupt_mask &&
      data_write_data == 16'h00a5,
      "direct LAR preserves control state and does not alter write data"
    );
    tick();  // direct LAR AR1,14
    require(
      retired && auxiliary_register_1 == 16'hfedc,
      "direct LAR loads all 16 bits into designated AR1"
    );
    require(
      accumulator == 32'h0000_00a5 && overflow_mode && !overflow_flag,
      "LAR preserves accumulator and overflow status"
    );

    tick();  // LDPK 0
    tick();  // LARK AR0,7
    tick();  // LARP AR0
    require(
      data_read && data_address_valid && data_address == 8'd7,
      "self-addressed indirect LAR reads the old selected-AR address"
    );
    tick();  // LAR AR0,*-,AR1
    require(
      auxiliary_register_0 == 16'h1234,
      "self-addressed LAR suppresses decrement of the loaded value"
    );
    require(
      auxiliary_register_pointer,
      "self-addressed LAR still applies requested next ARP"
    );

    tick();  // LARK AR0,0x8f
    tick();  // LARK AR1,0x55
    tick();  // LARP AR0
    require(
      data_read && data_address_valid && data_address == 8'd143,
      "other-target indirect LAR reads through selected AR0"
    );
    tick();  // LAR AR1,*+
    require(
      auxiliary_register_0 == 16'h0090,
      "other-target LAR retains normal selected-AR postincrement"
    );
    require(
      auxiliary_register_1 == 16'hcafe,
      "other-target LAR loads designated AR1"
    );
    require(
      !auxiliary_register_pointer,
      "preserve form leaves ARP unchanged"
    );

    tick();  // LDPK 1
    require(
      data_read && !data_address_valid && data_address == 8'hff,
      "out-of-range direct LAR exposes unresolved logical address"
    );
    tick();  // unresolved LAR traps
    require(illegal && !retired, "unresolved LAR traps without retirement");
    require(pc == 12'd13, "unresolved LAR holds PC");
    require(cycle_count == 32'd13, "unresolved LAR does not count a cycle");
    require(
      auxiliary_register_0 == 16'h0090 &&
      auxiliary_register_1 == 16'hcafe,
      "unresolved LAR leaves both auxiliary registers unchanged"
    );

    require(t_register == 16'h0000, "LAR preserves initialized T");
    $display("PASS tb_lar_rtl");
    $finish;
  end
endmodule

`default_nettype wire
