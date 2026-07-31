`default_nettype none

module tb_interrupt_model_rtl;
  logic        clk;
  logic        initialize;
  logic        int_n;
  logic [11:0] program_address;
  logic [15:0] program_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [11:0] stack_top;
  logic        interrupt_mask;
  logic        interrupt_pending;
  logic        retired;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_core dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .reset_i                       (1'b0),
    .clock_enable_i                (1'b1),
    .bio_i                         (1'b1),
    .int_i                         (int_n),
    .program_address_o             (program_address),
    .program_next_address_o        (),
    .program_read_o                (),
    .program_write_o               (),
    .program_write_data_o          (),
    .program_data_i                (program_data),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .io_write_data_o               (),
    .io_read_data_i                (16'h0000),
    .data_address_o                (),
    .data_read_o                   (),
    .data_write_o                  (),
    .data_address_valid_o          (),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (interrupt_mask),
    .interrupt_pending_o           (interrupt_pending),
    .instruction_valid_o           (),
    .retired_o                     (retired),
    .illegal_o                     (),
    .cycle_count_o                 (cycle_count)
  );

  assign program_data = program_memory[program_address];

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    @(posedge clk);
    #1;
  endtask

  task automatic emit_trace(input int unsigned index);
    $display(
      "TRACE %0d %03x %08x %03x %0d %0d %0d %0d",
      index,
      pc,
      accumulator,
      stack_top,
      interrupt_mask,
      interrupt_pending,
      cycle_count,
      retired
    );
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7f82;  // EINT
    program_memory[1] = 16'h7e2a;  // protected LACK
    program_memory[2] = 16'h7e5a;  // dummy fetch, then vector execution

    initialize = 1'b1;
    int_n = 1'b1;
    tick();
    initialize = 1'b0;

    int_n = 1'b0;
    tick();
    emit_trace(0);
    int_n = 1'b1;
    tick();
    emit_trace(1);
    tick();
    emit_trace(2);
    tick();
    emit_trace(3);

    $finish;
  end
endmodule

`default_nettype wire
