`default_nettype none

module tb_mar_rtl;
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
    .internal_ram_read_enable_i    (clock_enable),
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
    program_memory[2]  = 16'h3800;  // LAR AR0,0 -> 0xfe00
    program_memory[3]  = 16'h3901;  // LAR AR1,1 -> 0xa1ff
    program_memory[4]  = 16'h6880;  // LARP AR0
    program_memory[5]  = 16'h6898;  // MAR *-
    program_memory[6]  = 16'h68a1;  // MAR *+,AR1
    program_memory[7]  = 16'h68a8;  // MAR *+
    program_memory[8]  = 16'h687f;  // direct MAR is NOP
    program_memory[9]  = 16'h6890;  // MAR *-,AR0
    program_memory[10] = 16'h68b8;  // unsupported simultaneous update

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    load_data(8'd0, 16'hfe00);
    load_data(8'd1, 16'ha1ff);
    initialize = 1'b0;
    reset      = 1'b0;

    tick();  // SOVM
    tick();  // LACK
    tick();  // LAR AR0
    tick();  // LAR AR1
    tick();  // LARP AR0

    require(
      program_read && instruction_valid &&
      !data_read && !data_write && !data_address_valid &&
      data_address == 8'h00 && data_read_data == 16'hfe00 &&
      data_write_data == 16'h00a5,
      "indirect MAR exposes no logical data-memory transaction"
    );
    tick();  // MAR *-
    require(
      retired && auxiliary_register_0 == 16'hffff &&
      auxiliary_register_1 == 16'ha1ff &&
      !auxiliary_register_pointer,
      "MAR decrement wraps only the selected AR low nine bits"
    );
    require(
      accumulator == 32'h0000_00a5 && overflow_mode && !overflow_flag &&
      !data_page_pointer && interrupt_mask,
      "MAR preserves accumulator and unrelated status"
    );

    tick();  // MAR *+,AR1
    require(
      auxiliary_register_0 == 16'hfe00 &&
      auxiliary_register_pointer,
      "MAR increments before replacing ARP"
    );

    tick();  // MAR *+ on AR1
    require(
      auxiliary_register_1 == 16'ha000 &&
      auxiliary_register_pointer,
      "MAR increment wraps AR1 low nine bits and preserves high bits"
    );

    require(
      instruction_valid && !data_read && !data_write && !data_address_valid,
      "direct MAR also exposes no data-memory transaction"
    );
    tick();  // direct MAR
    require(
      auxiliary_register_0 == 16'hfe00 &&
      auxiliary_register_1 == 16'ha000 &&
      auxiliary_register_pointer,
      "direct MAR is an architectural NOP"
    );

    tick();  // MAR *-,AR0
    require(
      auxiliary_register_1 == 16'ha1ff &&
      !auxiliary_register_pointer,
      "MAR decrements selected AR before replacing ARP"
    );
    require(pc == 12'd10 && cycle_count == 32'd10,
            "every legal MAR form consumes one architectural cycle");

    tick();  // unsupported simultaneous-update MAR
    require(illegal && !retired,
            "unsupported simultaneous-update MAR traps fail-closed");
    require(pc == 12'd10 && cycle_count == 32'd10,
            "unsupported MAR does not advance PC or cycle count");
    require(
      auxiliary_register_0 == 16'hfe00 &&
      auxiliary_register_1 == 16'ha1ff &&
      !auxiliary_register_pointer,
      "unsupported MAR leaves auxiliary state unchanged"
    );

    require(t_register == 16'h0000, "MAR preserves initialized T");
    require(product_register == 32'h0000_0000,
            "MAR preserves initialized P");
    $display("PASS tb_mar_rtl");
    $finish;
  end
endmodule

`default_nettype wire
