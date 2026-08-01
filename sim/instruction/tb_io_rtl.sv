`default_nettype none

module tb_io_rtl;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic [15:0] io_read_data;
  logic [11:0] program_address;
  logic        program_read;
  logic [15:0] program_data;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic [15:0] io_write_data;
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
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
  logic        data_page_pointer;
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
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
    .program_address_o             (program_address),
    .program_next_address_o        (),
    .program_read_o                (program_read),
    .program_write_o               (),
    .program_write_data_o          (),
    .program_data_i                (program_data),
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (io_write_data),
    .io_read_data_i                (io_read_data),
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
    .accumulator_o                 (),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (data_page_pointer),
    .stack_top_o                    (),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (),
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
    program_memory[0] = 16'h4203;  // IN 3,PA2
    program_memory[1] = 16'h4f03;  // OUT 3,PA7
    program_memory[2] = 16'h7008;  // LARK AR0,8
    program_memory[3] = 16'h7128;  // LARK AR1,40
    program_memory[4] = 16'h6880;  // LARP AR0
    program_memory[5] = 16'h41a1;  // IN *+,PA1,AR1
    program_memory[6] = 16'h4d98;  // OUT *-,PA5, preserve ARP
    program_memory[7] = 16'h6e01;  // LDPK 1
    program_memory[8] = 16'h4010;  // IN 16,PA0 -> unresolved address 144

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    io_read_data       = 16'h1111;
    debug_data_write   = 1'b1;
    debug_data_address = 8'd40;
    debug_data         = 16'hcafe;
    tick();
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    tick();
    require(!program_read && !io_read && !io_write,
            "reset suppresses all external transactions");

    reset = 1'b0;
    #1;
    require(program_read && instruction_valid &&
            !io_read && !io_write && !data_read && !data_write,
            "IN opcode begins as a pure program read");
    tick();
    require(!retired && !illegal && pc == 12'd1 &&
            cycle_count == 32'd1 && !program_read,
            "IN opcode sample enters a second machine cycle");
    require(io_read && !io_write && io_port == 3'd2 &&
            data_write && !data_read && data_address_valid &&
            data_address == 8'd3 && data_write_address == 8'd3 &&
            data_write_address_valid && data_write_data == 16'h1111,
            "IN exposes the selected port and internal write");

    io_read_data = 16'h1234;
    clock_enable = 1'b0;
    tick();
    require(io_read && io_port == 3'd2 && data_write &&
            data_write_data == 16'h1234 &&
            pc == 12'd1 && cycle_count == 32'd1 && !retired,
            "clock-enable stall holds the transfer while input remains live");
    clock_enable = 1'b1;
    tick();
    require(retired && !illegal && pc == 12'd1 &&
            cycle_count == 32'd2 && program_read &&
            !io_read && !io_write,
            "IN retires only at the second enabled boundary");

    tick();
    require(!retired && pc == 12'd2 && cycle_count == 32'd3 &&
            !program_read && !io_read && io_write &&
            io_port == 3'd7 && io_write_data == 16'h1234,
            "OUT second cycle reads the word committed by IN");
    require(data_read && !data_write && data_address == 8'd3 &&
            data_read_data == 16'h1234,
            "OUT exposes its concurrent internal RAM read");
    tick();
    require(retired && pc == 12'd2 && cycle_count == 32'd4,
            "OUT consumes exactly two cycles");

    repeat (3) tick();
    require(pc == 12'd5 && cycle_count == 32'd7 &&
            auxiliary_register_0 == 16'd8 &&
            auxiliary_register_1 == 16'd40 &&
            !auxiliary_register_pointer,
            "address-register setup retires normally");

    io_read_data = 16'hbeef;
    tick();
    require(!retired && io_read && io_port == 3'd1 &&
            data_write && data_address == 8'd8,
            "indirect IN uses the old selected AR");
    tick();
    require(retired && pc == 12'd6 && cycle_count == 32'd9 &&
            auxiliary_register_0 == 16'd9 &&
            auxiliary_register_1 == 16'd40 &&
            auxiliary_register_pointer,
            "indirect IN post-increments and selects next ARP at retirement");

    tick();
    require(!retired && io_write && io_port == 3'd5 &&
            io_write_data == 16'hcafe && data_address == 8'd40,
            "indirect OUT reads old AR1 and drives selected port");
    tick();
    require(retired && pc == 12'd7 && cycle_count == 32'd11 &&
            auxiliary_register_0 == 16'd9 &&
            auxiliary_register_1 == 16'd39 &&
            auxiliary_register_pointer,
            "indirect OUT decrements AR1 and preserves ARP");

    tick();
    require(retired && data_page_pointer && pc == 12'd8 &&
            cycle_count == 32'd12,
            "page-one setup reaches unresolved direct address");
    require(!instruction_valid && program_read &&
            !io_read && !io_write && !data_read && !data_write,
            "unresolved IN does not start a port or RAM transaction");
    tick();
    require(illegal && !retired && pc == 12'd8 &&
            cycle_count == 32'd12 &&
            auxiliary_register_0 == 16'd9 &&
            auxiliary_register_1 == 16'd39 &&
            auxiliary_register_pointer && data_page_pointer,
            "unresolved IN traps before any architectural effect");

    $display("PASS tb_io_rtl");
    $finish;
  end
endmodule

`default_nettype wire
