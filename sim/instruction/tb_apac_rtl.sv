`default_nettype none

module tb_apac_rtl;
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
    program_memory[0]  = 16'h6a02;  // LT 2 -> T=1
    program_memory[1]  = 16'h8040;  // MPYK 64 -> P=64
    program_memory[2]  = 16'h7e20;  // LACK 32
    program_memory[3]  = 16'h7f8f;  // APAC -> 96
    program_memory[4]  = 16'h6500;  // ZALH 0 -> 0x7fff0000
    program_memory[5]  = 16'h6101;  // ADDS 1 -> 0x7ffffffe
    program_memory[6]  = 16'h7f8f;  // APAC positive wrap
    program_memory[7]  = 16'h7f8b;  // SOVM
    program_memory[8]  = 16'h6500;  // ZALH 0
    program_memory[9]  = 16'h6101;  // ADDS 1
    program_memory[10] = 16'h7f8f;  // APAC positive saturation
    program_memory[11] = 16'h6a02;  // LT 2
    program_memory[12] = 16'h9fc0;  // MPYK -64
    program_memory[13] = 16'h7f8a;  // ROVM
    program_memory[14] = 16'h6503;  // ZALH 3 -> 0x80000000
    program_memory[15] = 16'h6102;  // ADDS 2 -> 0x80000001
    program_memory[16] = 16'h7f8f;  // APAC negative wrap
    program_memory[17] = 16'h7f8b;  // SOVM
    program_memory[18] = 16'h6503;  // ZALH 3
    program_memory[19] = 16'h6102;  // ADDS 2
    program_memory[20] = 16'h7f8f;  // APAC negative saturation
    program_memory[21] = 16'h7f83;  // unsupported control word

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'd0;
    debug_data         = 16'h7fff;
    tick();
    debug_data_address = 8'd1;
    debug_data         = 16'hfffe;
    tick();
    debug_data_address = 8'd2;
    debug_data         = 16'h0001;
    tick();
    debug_data_address = 8'd3;
    debug_data         = 16'h8000;
    tick();
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    tick();
    require(!program_read && interrupt_mask,
            "reset suppresses fetch and masks interrupts");

    reset = 1'b0;
    tick();
    require(t_register == 16'h0001,
            "LT establishes the multiplier source");
    tick();
    require(product_register == 32'h0000_0040,
            "MPYK establishes the positive P operand");
    tick();
    require(accumulator == 32'h0000_0020 &&
            instruction_valid && program_read &&
            program_address == 12'd3,
            "primary example reaches APAC with ACC=32 and P=64");
    require(!data_read && !data_write && !data_address_valid,
            "APAC has no logical data-memory transaction");

    tick();
    require(retired && accumulator == 32'h0000_0060 &&
            product_register == 32'h0000_0040,
            "APAC primary example produces 96 and preserves P");
    require(!overflow_flag && !overflow_mode,
            "nonoverflowing APAC leaves clear OV and OVM unchanged");
    tick();
    tick();
    require(accumulator == 32'h7fff_fffe &&
            !data_read && !data_write && !data_address_valid,
            "positive boundary reaches APAC through program-only activity");

    tick();
    require(accumulator == 32'h8000_003e &&
            overflow_flag && !overflow_mode,
            "APAC wraps positive overflow and sets sticky OV when OVM is clear");
    tick();
    tick();
    tick();
    require(accumulator == 32'h7fff_fffe &&
            overflow_flag && overflow_mode,
            "positive saturation setup preserves sticky OV");
    require(!data_read && !data_write && !data_address_valid,
            "saturating APAC remains program-only");

    tick();
    require(accumulator == 32'h7fff_ffff &&
            product_register == 32'h0000_0040,
            "APAC saturates positive overflow and preserves P");
    tick();
    require(t_register == 16'h0001,
            "negative-product setup reloads T");
    tick();
    require(product_register == 32'hffff_ffc0,
            "MPYK establishes the negative P operand");
    tick();
    tick();
    tick();
    require(accumulator == 32'h8000_0001 &&
            overflow_flag && !overflow_mode,
            "negative boundary reaches APAC with OVM clear");
    require(!data_read && !data_write && !data_address_valid,
            "negative-overflow APAC has no data transaction");

    tick();
    require(accumulator == 32'h7fff_ffc1 &&
            product_register == 32'hffff_ffc0 &&
            overflow_flag && !overflow_mode,
            "APAC wraps negative overflow and preserves P");
    tick();
    tick();
    tick();
    require(accumulator == 32'h8000_0001 &&
            overflow_flag && overflow_mode,
            "negative saturation setup preserves sticky OV");

    tick();
    require(accumulator == 32'h8000_0000 &&
            product_register == 32'hffff_ffc0,
            "APAC saturates negative overflow to the signed endpoint");
    require(overflow_flag && overflow_mode &&
            t_register == 16'h0001,
            "APAC preserves P, T, sticky OV, and OVM");
    require(auxiliary_register_0 == 16'h0000 &&
            auxiliary_register_1 == 16'h0000 &&
            !auxiliary_register_pointer && !data_page_pointer,
            "APAC leaves address state unchanged");
    require(pc == 12'd21 && cycle_count == 32'd21,
            "every APAC consumes exactly one instruction cycle");
    require(!instruction_valid,
            "adjacent unsupported control word remains invalid");

    tick();
    require(illegal && !retired && pc == 12'd21 &&
            cycle_count == 32'd21,
            "unsupported word traps without changing qualified APAC state");
    require(accumulator == 32'h8000_0000 &&
            product_register == 32'hffff_ffc0,
            "trap preserves the final APAC result");
    require(data_write_data == accumulator[15:0] &&
            data_read_data == 16'h7fff && data_address == 8'h00,
            "inactive data outputs remain deterministic diagnostics");

    $display("PASS tb_apac_rtl");
    $finish;
  end
endmodule

`default_nettype wire
