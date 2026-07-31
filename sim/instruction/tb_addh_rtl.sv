`default_nettype none

module tb_addh_rtl;
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
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
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
    .stack_top_o                   (),
    .stack_level_1_o               (),
    .stack_level_2_o               (),
    .stack_bottom_o                (),
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
    for (int unsigned case_index = 0; case_index < 4; case_index++) begin
      int unsigned base;
      base = case_index * 8;
      program_memory[base + 0] = 16'h7b05 + case_index[15:0];
      program_memory[base + 1] = 16'h6500;  // high half 0x7fff
      program_memory[base + 2] = 16'h6102;  // low half 0x1357
      program_memory[base + 3] = 16'h6003;  // positive signed wrap
      program_memory[base + 4] = 16'h7b05 + case_index[15:0];
      program_memory[base + 5] = 16'h6501;  // high half 0x8000
      program_memory[base + 6] = 16'h6102;  // low half 0x1357
      program_memory[base + 7] = 16'h6004;  // negative signed wrap
    end

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    load_data(8'd0, 16'h7fff);
    load_data(8'd1, 16'h8000);
    load_data(8'd2, 16'h1357);
    load_data(8'd3, 16'h0001);
    load_data(8'd4, 16'hffff);
    load_data(8'd5, 16'h0000);  // OV=0, OVM=0
    load_data(8'd6, 16'h4000);  // OV=0, OVM=1
    load_data(8'd7, 16'h8000);  // OV=1, OVM=0
    load_data(8'd8, 16'hc000);  // OV=1, OVM=1
    load_data(8'd9, 16'hffff);
    load_data(8'd143, 16'h0002);
    initialize = 1'b0;
    reset      = 1'b0;
    #1;
    require(program_read && interrupt_mask,
            "ADDH test begins with an active fetch and masked interrupts");

    for (int unsigned case_index = 0; case_index < 4; case_index++) begin
      logic expected_ov;
      logic expected_ovm;
      expected_ov  = case_index[1];
      expected_ovm = case_index[0];

      tick();  // LST
      tick();  // ZALH 0x7fff
      tick();  // ADDS low half
      require(data_read && !data_write && data_address_valid &&
              data_address == 8'd3 && data_read_data == 16'h0001,
              "ADDH exposes one qualified data read before retirement");
      if (case_index == 0) begin
        clock_enable = 1'b0;
        tick();
        require(pc == 12'd3 && accumulator == 32'h7fff_1357 &&
                cycle_count == 32'd3 && data_read && data_address_valid,
                "clock-enable stall holds ADDH state and read transaction");
        clock_enable = 1'b1;
      end
      tick();
      require(accumulator == 32'h8000_1357 &&
              overflow_flag == expected_ov &&
              overflow_mode == expected_ovm,
              "positive high-half wrap preserves low ACC, OV, and OVM");
      require(retired && !illegal,
              "positive-boundary ADDH retires normally");

      tick();  // LST restores the selected incoming status
      tick();  // ZALH 0x8000
      tick();  // ADDS low half
      require(data_read && data_address == 8'd4 &&
              data_read_data == 16'hffff,
              "second ADDH presents its complete 16-bit operand");
      tick();
      require(accumulator == 32'h7fff_1357 &&
              overflow_flag == expected_ov &&
              overflow_mode == expected_ovm,
              "negative high-half wrap preserves low ACC, OV, and OVM");
      require(cycle_count == ((case_index + 1) * 8),
              "each accepted ADDH remains a one-cycle instruction");
    end
    require(t_register == 16'h0000 && product_register == 32'h0000_0000,
            "ADDH preserves initialized T and P across boundary matrix");
    require(interrupt_mask,
            "ADDH and the status fixtures do not change interrupt masking");

    program_memory[0]  = 16'h7f89;  // ZAC
    program_memory[1]  = 16'h6e01;  // LDPK 1
    program_memory[2]  = 16'h600f;  // ADDH 15 -> physical address 143
    program_memory[3]  = 16'h6e00;  // LDPK 0
    program_memory[4]  = 16'h708f;  // LARK AR0,143
    program_memory[5]  = 16'h7109;  // LARK AR1,9
    program_memory[6]  = 16'h6880;  // LARP 0
    program_memory[7]  = 16'h60a1;  // ADDH *+,AR1
    program_memory[8]  = 16'h6090;  // ADDH *-,AR0
    program_memory[9]  = 16'h6e01;  // LDPK 1
    program_memory[10] = 16'h6010;  // unresolved physical address 144
    initialize = 1'b1;
    tick();
    initialize = 1'b0;

    tick();
    tick();
    require(data_page_pointer && data_read && data_address_valid &&
            data_address == 8'd143 && data_read_data == 16'h0002,
            "page-one ADDH reaches the final physical data word");
    tick();
    require(accumulator == 32'h0002_0000 && !overflow_flag &&
            !overflow_mode,
            "direct ADDH adds into ACC high and preserves low/status");
    tick();
    tick();
    tick();
    tick();
    require(!auxiliary_register_pointer &&
            auxiliary_register_0 == 16'd143 &&
            auxiliary_register_1 == 16'd9 &&
            data_read && data_address == 8'd143,
            "indirect ADDH uses the selected old AR address");
    tick();
    require(accumulator == 32'h0004_0000 &&
            auxiliary_register_0 == 16'd144 &&
            auxiliary_register_pointer &&
            data_read && data_address == 8'd9,
            "first indirect ADDH updates AR0 and installs AR1 afterward");
    tick();
    require(accumulator == 32'h0003_0000 &&
            auxiliary_register_1 == 16'd8 &&
            !auxiliary_register_pointer,
            "second indirect ADDH decrements AR1 and restores AR0");

    tick();
    require(data_page_pointer && data_read && !data_address_valid &&
            data_address == 8'd144 && !instruction_valid,
            "unresolved page-one ADDH is visible but cannot execute");
    tick();
    require(illegal && !retired && pc == 12'd10 && cycle_count == 32'd10,
            "unresolved ADDH traps without architectural retirement");

    $display("PASS tb_addh_rtl");
    $finish;
  end
endmodule

`default_nettype wire
