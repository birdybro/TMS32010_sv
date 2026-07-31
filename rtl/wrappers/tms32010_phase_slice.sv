`default_nettype none

// Integration wrapper for the qualified one-cycle sequential slice, two-cycle
// control-flow reads, and two-cycle native I/O transfers. This is not yet the
// complete TMS32010 fetch pipeline.
module tms32010_phase_slice (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        rs_i,
  input  logic        clock_enable_i,
  input  logic        bio_i,
  input  logic [15:0] program_data_i,
  input  logic [15:0] io_read_data_i,
  input  logic        debug_data_write_i,
  input  logic [7:0]  debug_data_address_i,
  input  logic [15:0] debug_data_i,

  output logic [1:0]  phase_o,
  output logic        clkout_o,
  output logic [11:0] program_address_o,
  output logic        men_n_o,
  output logic        den_n_o,
  output logic        we_n_o,
  output logic        sample_o,
  output logic        bus_active_o,
  output logic [7:0]  data_address_o,
  output logic        data_read_o,
  output logic        data_write_o,
  output logic        data_address_valid_o,
  output logic [7:0]  data_write_address_o,
  output logic        data_write_address_valid_o,
  output logic [15:0] data_read_data_o,
  output logic [15:0] data_write_data_o,
  output logic [2:0]  io_port_o,
  output logic        io_read_o,
  output logic        io_write_o,
  output logic [15:0] io_write_data_o,

  output logic [11:0] pc_o,
  output logic [31:0] accumulator_o,
  output logic [15:0] t_register_o,
  output logic [31:0] product_register_o,
  output logic [15:0] auxiliary_register_0_o,
  output logic [15:0] auxiliary_register_1_o,
  output logic        auxiliary_register_pointer_o,
  output logic        data_page_pointer_o,
  output logic [11:0] stack_top_o,
  output logic [11:0] stack_level_1_o,
  output logic [11:0] stack_level_2_o,
  output logic [11:0] stack_bottom_o,
  output logic        overflow_flag_o,
  output logic        overflow_mode_o,
  output logic        interrupt_mask_o,
  output logic        instruction_valid_o,
  output logic        retired_o,
  output logic        illegal_o,
  output logic [31:0] cycle_count_o
);
  logic [11:0] logical_program_address;
  logic [11:0] logical_program_next_address;
  logic        logical_program_read;
  logic        logical_io_read;
  logic        logical_io_write;
  logic [2:0]  logical_io_port;
  logic [11:0] program_bus_address;
  logic        core_reset;
  logic        execute_boundary;
  logic [11:0] next_program_address;

  // The physical reset is sampled at the same falling-CLKOUT boundary as the
  // native phase engine. initialize_i remains a separate FPGA-only control.
  assign core_reset =
    clock_enable_i & (phase_o == 2'd3) & rs_i;

  // The core supplies the next address because control flow can select its
  // target at the second program-read sampling boundary.
  assign execute_boundary =
    clock_enable_i & bus_active_o & (phase_o == 2'd3) &
    (
      logical_program_read ||
      logical_io_read ||
      logical_io_write
    ) & ~rs_i;
  assign next_program_address =
    bus_active_o
      ? logical_program_next_address
      : 12'h000;
  assign program_address_o =
    (logical_io_read || logical_io_write)
      ? {9'h000, logical_io_port}
      : program_bus_address;
  assign den_n_o =
    ~bus_active_o | ~logical_io_read | (phase_o == 2'd0);
  assign we_n_o =
    ~bus_active_o | ~logical_io_write | (phase_o == 2'd0);
  assign io_port_o = logical_io_port;
  assign io_read_o = logical_io_read;
  assign io_write_o = logical_io_write;

  tms32010_core core (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .reset_i                       (core_reset),
    .clock_enable_i                (execute_boundary),
    .bio_i                         (bio_i),
    .program_address_o             (logical_program_address),
    .program_next_address_o        (logical_program_next_address),
    .program_read_o                (logical_program_read),
    .program_data_i                (program_data_i),
    .io_port_o                     (logical_io_port),
    .io_read_o                     (logical_io_read),
    .io_write_o                    (logical_io_write),
    .io_write_data_o               (io_write_data_o),
    .io_read_data_i                (io_read_data_i),
    .data_address_o                (data_address_o),
    .data_read_o                   (data_read_o),
    .data_write_o                  (data_write_o),
    .data_address_valid_o          (data_address_valid_o),
    .data_write_address_o          (data_write_address_o),
    .data_write_address_valid_o    (data_write_address_valid_o),
    .data_read_data_o              (data_read_data_o),
    .data_write_data_o             (data_write_data_o),
    .debug_data_write_i            (debug_data_write_i),
    .debug_data_address_i          (debug_data_address_i),
    .debug_data_i                  (debug_data_i),
    .pc_o                          (pc_o),
    .accumulator_o                 (accumulator_o),
    .t_register_o                  (t_register_o),
    .product_register_o            (product_register_o),
    .auxiliary_register_0_o        (auxiliary_register_0_o),
    .auxiliary_register_1_o        (auxiliary_register_1_o),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer_o),
    .data_page_pointer_o           (data_page_pointer_o),
    .stack_top_o                    (stack_top_o),
    .stack_level_1_o                (stack_level_1_o),
    .stack_level_2_o                (stack_level_2_o),
    .stack_bottom_o                 (stack_bottom_o),
    .overflow_flag_o               (overflow_flag_o),
    .overflow_mode_o               (overflow_mode_o),
    .interrupt_mask_o              (interrupt_mask_o),
    .instruction_valid_o           (instruction_valid_o),
    .retired_o                     (retired_o),
    .illegal_o                     (illegal_o),
    .cycle_count_o                 (cycle_count_o)
  );

  tms32010_program_bus program_bus (
    .clk_i          (clk_i),
    .initialize_i   (initialize_i),
    .rs_i           (rs_i),
    .clock_enable_i (clock_enable_i),
    .program_read_i (logical_program_read),
    .next_address_i (next_program_address),
    .phase_o        (phase_o),
    .clkout_o       (clkout_o),
    .address_o      (program_bus_address),
    .men_n_o        (men_n_o),
    .sample_o       (sample_o),
    .active_o       (bus_active_o)
  );

  always_ff @(posedge clk_i) begin
    if (!initialize_i) begin
      assert (!(retired_o && !sample_o));
      assert (logical_program_address == pc_o);
      assert (!(
        (!men_n_o && !den_n_o) ||
        (!men_n_o && !we_n_o) ||
        (!den_n_o && !we_n_o)
      ));
    end
  end
endmodule

`default_nettype wire
