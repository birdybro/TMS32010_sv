`default_nettype none

module tb_model_rtl_slice;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic        bio;
  logic [11:0] program_address;
  logic        program_read;
  logic        program_write;
  logic [15:0] program_write_data;
  logic [15:0] program_data;
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
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [7:0]  data_write_address;
  logic        data_write_address_valid;
  logic [15:0] data_read_data;
  logic [15:0] data_write_data;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic [15:0] io_write_data;
  logic [15:0] io_read_data;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic [15:0] program_memory [0:4095];
  logic [15:0] data_memory [0:143];
  logic [15:0] io_input [0:7];

  string image_path;
  string data_path;
  int unsigned instruction_count;
  int unsigned bio_value;

  tms32010_core dut (
    .clk_i             (clk),
    .initialize_i      (initialize),
    .reset_i           (reset),
    .clock_enable_i    (clock_enable),
    .bio_i             (bio),
    .program_address_o (program_address),
    .program_next_address_o (),
    .program_read_o    (program_read),
    .program_write_o               (program_write),
    .program_write_data_o          (program_write_data),
    .program_data_i    (program_data),
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (io_write_data),
    .io_read_data_i                (io_read_data),
    .data_address_o    (data_address),
    .data_read_o       (data_read),
    .data_write_o      (data_write),
    .data_address_valid_o (data_address_valid),
    .data_write_address_o (data_write_address),
    .data_write_address_valid_o (data_write_address_valid),
    .data_read_data_o  (data_read_data),
    .data_write_data_o (data_write_data),
    .debug_data_write_i (debug_data_write),
    .debug_data_address_i (debug_data_address),
    .debug_data_i      (debug_data),
    .pc_o              (pc),
    .accumulator_o     (accumulator),
    .t_register_o      (t_register),
    .product_register_o (product_register),
    .auxiliary_register_0_o (auxiliary_register_0),
    .auxiliary_register_1_o (auxiliary_register_1),
    .auxiliary_register_pointer_o (auxiliary_register_pointer),
    .data_page_pointer_o (data_page_pointer),
    .stack_top_o       (stack_top),
    .stack_level_1_o   (stack_level_1),
    .stack_level_2_o   (stack_level_2),
    .stack_bottom_o    (stack_bottom),
    .overflow_flag_o   (overflow_flag),
    .overflow_mode_o   (overflow_mode),
    .interrupt_mask_o  (interrupt_mask),
    .instruction_valid_o (instruction_valid),
    .retired_o         (retired),
    .illegal_o         (illegal),
    .cycle_count_o     (cycle_count)
  );

  assign program_data = program_memory[program_address];
  assign io_read_data = io_input[io_port];

  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    if (!$value$plusargs("IMAGE=%s", image_path)) begin
      $fatal(1, "missing +IMAGE");
    end
    if (!$value$plusargs("COUNT=%d", instruction_count)) begin
      $fatal(1, "missing +COUNT");
    end
    if (!$value$plusargs("DATA=%s", data_path)) begin
      $fatal(1, "missing +DATA");
    end
    bio_value = 1;
    void'($value$plusargs("BIO=%d", bio_value));
    bio = bio_value != 0;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    for (int unsigned index = 0; index < 8; index++) begin
      io_input[index] = 16'h1000 + index[15:0];
    end
    $readmemh(image_path, program_memory);
    $readmemh(data_path, data_memory);

    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    @(posedge clk);
    #1;
    initialize = 1'b0;
    if (!interrupt_mask || overflow_flag || program_read) begin
      $fatal(1, "reset control outputs");
    end
    debug_data_write = 1'b1;
    for (int unsigned index = 0; index < 144; index++) begin
      debug_data_address = index[7:0];
      debug_data         = data_memory[index];
      @(posedge clk);
      #1;
    end
    debug_data_write = 1'b0;
    reset = 1'b0;
    #1;
    if (!program_read) begin
      $fatal(1, "program read must be active outside reset");
    end

    for (int unsigned index = 0; index < instruction_count; index++) begin
      logic [11:0] pc_before;
      logic [15:0] opcode_before;
      logic [7:0]  data_address_before;
      logic        data_read_before;
      logic        data_write_before;
      logic        data_address_valid_before;
      logic [7:0]  data_write_address_before;
      logic        data_write_address_valid_before;
      logic [15:0] data_read_data_before;
      logic [15:0] data_write_data_before;
      logic [2:0]  io_port_before;
      logic        io_read_before;
      logic        io_write_before;
      logic [15:0] io_transfer_data_before;
      logic        program_read_before;
      logic        program_write_before;
      logic [15:0] program_write_data_before;
      pc_before     = program_address;
      opcode_before = program_data;
      data_address_before       = data_address;
      data_read_before          = data_read;
      data_write_before         = data_write;
      data_address_valid_before = data_address_valid;
      data_write_address_before = data_write_address;
      data_write_address_valid_before = data_write_address_valid;
      data_read_data_before     = data_read_data;
      data_write_data_before    = data_write_data;
      io_port_before            = io_port;
      io_read_before            = io_read;
      io_write_before           = io_write;
      io_transfer_data_before   =
        io_read ? io_read_data : io_write_data;
      program_read_before       = program_read;
      program_write_before      = program_write;
      program_write_data_before = program_write_data;
      @(posedge clk);
      #1;
      if (program_write_before) begin
        program_memory[pc_before] = program_write_data_before;
      end
      $display(
        "TRACE %03x %04x %03x %08x %01x %04x %04x %01x %01x %01x %01x %01x %08x %02x %01x %01x %01x %02x %01x %04x %04x %01x %04x %08x %01x %03x %03x %03x %03x %01x %01x %01x %04x %01x %01x %04x",
        pc_before,
        opcode_before,
        pc,
        accumulator,
        overflow_mode,
        auxiliary_register_0,
        auxiliary_register_1,
        auxiliary_register_pointer,
        data_page_pointer,
        instruction_valid,
        retired,
        illegal,
        cycle_count,
        data_address_before,
        data_read_before,
        data_write_before,
        data_address_valid_before,
        data_write_address_before,
        data_write_address_valid_before,
        data_read_data_before,
        data_write_data_before,
        overflow_flag,
        t_register,
        product_register,
        interrupt_mask,
        stack_top,
        stack_level_1,
        stack_level_2,
        stack_bottom,
        io_port_before,
        io_read_before,
        io_write_before,
        io_transfer_data_before,
        program_read_before,
        program_write_before,
        program_write_data_before
      );
    end
    for (int unsigned index = 0; index < 144; index++) begin
      $display("RAM %02x %04x", index[7:0], dut.data_ram.memory[index]);
    end
    $display("PROGRAM 020 %04x", program_memory[12'h020]);
    $display("PROGRAM 021 %04x", program_memory[12'h021]);
    $display("PASS tb_model_rtl_slice");
    $finish;
  end
endmodule

`default_nettype wire
