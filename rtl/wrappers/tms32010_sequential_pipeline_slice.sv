`default_nettype none

// ADR-0002 integration slice for reset priming and sequential one-cycle
// instructions only. Program fetch owns a separate address from the core PC.
// Multicycle, reserved, and invalid-data-address instructions park the wrapper
// before execution; the legacy phase wrapper remains responsible for the
// separately qualified multicycle traces.
module tms32010_sequential_pipeline_slice (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        rs_i,
  input  logic        clock_enable_i,
  input  logic [15:0] program_data_i,
  input  logic        debug_data_write_i,
  input  logic [7:0]  debug_data_address_i,
  input  logic [15:0] debug_data_i,

  output logic [1:0]  phase_o,
  output logic        clkout_o,
  output logic [11:0] program_address_o,
  output logic        men_n_o,
  output logic        sample_o,
  output logic        bus_active_o,

  output logic        execute_valid_o,
  output logic [11:0] execute_address_o,
  output logic [15:0] execute_word_o,
  output logic        pipeline_blocked_o,

  output logic [7:0]  data_address_o,
  output logic        data_read_o,
  output logic        data_write_o,
  output logic        data_address_valid_o,
  output logic [7:0]  data_write_address_o,
  output logic        data_write_address_valid_o,
  output logic [15:0] data_read_data_o,
  output logic [15:0] data_write_data_o,

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
  localparam logic [5:0] OP_SUBC = 6'd36;
  localparam logic [5:0] OP_SUBH = 6'd52;

  logic [11:0] program_bus_address;
  logic [11:0] next_fetch_address;
  logic        bus_clock_enable;
  logic        pipeline_boundary;
  logic        fetch_boundary;
  logic        core_reset;
  logic        execute_decoded_valid;
  logic [5:0]  execute_decoded_operation;
  logic        execute_family_supported;
  logic        core_instruction_valid;
  logic        execute_ready;
  logic        core_execute_boundary;
  logic        core_program_read;
  logic        core_program_write;
  logic        core_io_read;
  logic        core_io_write;
  logic [11:0] core_program_address;
  logic [11:0] core_program_next_address;
  logic        core_interrupt_pending;

  // The packed decoder interface is shared with the core. This wrapper needs
  // only validity and operation class to enforce its one-cycle boundary.
  /* verilator lint_off UNUSEDSIGNAL */
  logic [7:0]  unused_execute_immediate;
  logic [12:0] unused_execute_immediate_13;
  logic        unused_execute_auxiliary_register;
  logic [3:0]  unused_execute_shift;
  logic [2:0]  unused_execute_port;
  logic        unused_execute_indirect;
  logic [6:0]  unused_execute_addressing_field;
  logic [15:0] unused_core_program_write_data;
  logic [2:0]  unused_core_io_port;
  logic [15:0] unused_core_io_write_data;
  /* verilator lint_on UNUSEDSIGNAL */

  assign program_address_o = program_bus_address;
  assign next_fetch_address =
    bus_active_o
      ? program_bus_address + 12'h001
      : 12'h000;

  assign execute_family_supported =
    execute_decoded_valid &&
    (
      (execute_decoded_operation <= OP_SUBC) ||
      (execute_decoded_operation == OP_SUBH)
    );
  assign execute_ready =
    execute_valid_o &&
    execute_family_supported &&
    core_instruction_valid;
  assign pipeline_blocked_o =
    execute_valid_o &&
    !rs_i &&
    !execute_ready;

  // A blocked word parks the bus at phase zero. Reset remains able to advance
  // to its recognized falling boundary and clear both ownership domains.
  assign bus_clock_enable =
    clock_enable_i &&
    (rs_i || !pipeline_blocked_o);
  assign pipeline_boundary =
    bus_clock_enable &&
    (phase_o == 2'd3);
  assign fetch_boundary =
    pipeline_boundary &&
    bus_active_o &&
    !rs_i;
  assign core_reset = pipeline_boundary && rs_i;
  assign core_execute_boundary = fetch_boundary && execute_ready;
  assign instruction_valid_o = execute_ready;

  tms32010_decode execute_decode (
    .instruction_i       (execute_word_o),
    .valid_o             (execute_decoded_valid),
    .operation_o         (execute_decoded_operation),
    .immediate_o         (unused_execute_immediate),
    .immediate_13_o      (unused_execute_immediate_13),
    .auxiliary_register_o(unused_execute_auxiliary_register),
    .shift_o             (unused_execute_shift),
    .port_o              (unused_execute_port),
    .indirect_o          (unused_execute_indirect),
    .addressing_field_o  (unused_execute_addressing_field)
  );

  tms32010_fetch_execute fetch_execute (
    .clk_i                (clk_i),
    .initialize_i         (initialize_i),
    .reset_i              (rs_i),
    .cycle_boundary_i     (pipeline_boundary),
    .fetched_valid_i      (fetch_boundary),
    .fetched_address_i    (program_bus_address),
    .fetched_word_i       (program_data_i),
    .execute_complete_i   (execute_ready),
    .flush_i              (1'b0),
    .execute_valid_o      (execute_valid_o),
    .execute_address_o    (execute_address_o),
    .execute_word_o       (execute_word_o)
  );

  tms32010_core core (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .reset_i                       (core_reset),
    .clock_enable_i                (core_execute_boundary),
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
    .program_address_o             (core_program_address),
    .program_next_address_o        (core_program_next_address),
    .program_read_o                (core_program_read),
    .program_write_o               (core_program_write),
    .program_write_data_o          (unused_core_program_write_data),
    .program_data_i                (execute_word_o),
    .io_port_o                     (unused_core_io_port),
    .io_read_o                     (core_io_read),
    .io_write_o                    (core_io_write),
    .io_write_data_o               (unused_core_io_write_data),
    .io_read_data_i                (16'h0000),
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
    .interrupt_pending_o           (core_interrupt_pending),
    .instruction_valid_o           (core_instruction_valid),
    .retired_o                     (retired_o),
    .illegal_o                     (illegal_o),
    .cycle_count_o                 (cycle_count_o)
  );

  tms32010_program_bus program_bus (
    .clk_i          (clk_i),
    .initialize_i   (initialize_i),
    .rs_i           (rs_i),
    .clock_enable_i (bus_clock_enable),
    .program_read_i (1'b1),
    .next_address_i (next_fetch_address),
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
      assert (!(core_program_write || core_io_read || core_io_write));
      assert (!core_interrupt_pending);
      if (core_execute_boundary) begin
        assert (execute_address_o == pc_o);
        assert (core_program_address == execute_address_o);
        assert (core_program_next_address == pc_o + 12'h001);
        assert (core_program_read);
      end
      if (pipeline_blocked_o) begin
        assert (!core_execute_boundary);
      end
    end
  end
endmodule

`default_nettype wire
