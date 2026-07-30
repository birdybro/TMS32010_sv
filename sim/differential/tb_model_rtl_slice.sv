`default_nettype none

module tb_model_rtl_slice;
  logic        clk;
  logic        reset;
  logic        clock_enable;
  logic [11:0] program_address;
  logic        program_read;
  logic [15:0] program_data;
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

  string image_path;
  int unsigned instruction_count;

  tms32010_core dut (
    .clk_i             (clk),
    .reset_i           (reset),
    .clock_enable_i    (clock_enable),
    .program_address_o (program_address),
    .program_read_o    (program_read),
    .program_data_i    (program_data),
    .pc_o              (pc),
    .accumulator_o     (accumulator),
    .auxiliary_register_0_o (auxiliary_register_0),
    .auxiliary_register_1_o (auxiliary_register_1),
    .auxiliary_register_pointer_o (auxiliary_register_pointer),
    .data_page_pointer_o (data_page_pointer),
    .overflow_mode_o   (overflow_mode),
    .interrupt_mask_o  (interrupt_mask),
    .instruction_valid_o (instruction_valid),
    .retired_o         (retired),
    .illegal_o         (illegal),
    .cycle_count_o     (cycle_count)
  );

  assign program_data = program_memory[program_address];

  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    if (!$value$plusargs("IMAGE=%s", image_path)) begin
      $fatal(1, "missing +IMAGE");
    end
    if (!$value$plusargs("COUNT=%d", instruction_count)) begin
      $fatal(1, "missing +COUNT");
    end
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    $readmemh(image_path, program_memory);

    reset        = 1'b1;
    clock_enable = 1'b1;
    @(posedge clk);
    #1;
    if (!interrupt_mask || program_read) begin
      $fatal(1, "reset control outputs");
    end
    reset = 1'b0;
    #1;
    if (!program_read) begin
      $fatal(1, "program read must be active outside reset");
    end

    for (int unsigned index = 0; index < instruction_count; index++) begin
      logic [11:0] pc_before;
      logic [15:0] opcode_before;
      pc_before     = program_address;
      opcode_before = program_data;
      @(posedge clk);
      #1;
      $display(
        "TRACE %03x %04x %03x %08x %01x %04x %04x %01x %01x %01x %01x %01x %08x",
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
        cycle_count
      );
    end
    $display("PASS tb_model_rtl_slice");
    $finish;
  end
endmodule

`default_nettype wire
