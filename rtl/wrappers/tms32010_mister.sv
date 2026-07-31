`default_nettype none

// Generic FPGA/MiSTer adapter around the currently qualified explicit-pipeline
// slice. This module changes interface conventions only; it does not add
// TMS32010 instructions or Hard Drivin'-specific address decoding.
module tms32010_mister (
  input  logic        clk_i,
  input  logic        reset_i,
  input  logic        clock_enable_i,
  input  logic        bio_i,
  input  logic        int_i,

  output logic [11:0] program_address_o,
  output logic        program_read_o,
  output logic        program_write_o,
  output logic [15:0] program_write_data_o,
  input  logic [15:0] program_read_data_i,
  input  logic        program_ready_i,

  output logic [2:0]  io_port_o,
  output logic        io_read_o,
  output logic        io_write_o,
  output logic [15:0] io_write_data_o,
  input  logic [15:0] io_read_data_i,
  input  logic        io_ready_i,

  input  logic        debug_data_write_i,
  input  logic [7:0]  debug_data_address_i,
  input  logic [15:0] debug_data_i,
  output logic [7:0]  debug_data_address_o,
  output logic        debug_data_read_o,
  output logic        debug_data_write_o,
  output logic        debug_data_address_valid_o,
  output logic [7:0]  debug_data_write_address_o,
  output logic [15:0] debug_data_read_data_o,
  output logic [15:0] debug_data_write_data_o,

  output logic        reset_active_o,
  output logic        memory_wait_o,
  output logic        phase_advance_o,
  output logic [1:0]  phase_o,
  output logic        clkout_o,
  output logic        native_men_n_o,
  output logic        native_den_n_o,
  output logic        native_we_n_o,
  output logic        native_sample_o,
  output logic        native_bus_active_o,

  output logic        execute_valid_o,
  output logic [11:0] execute_address_o,
  output logic [15:0] execute_word_o,
  output logic        pipeline_blocked_o,
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
  output logic        interrupt_pending_o,
  output logic        instruction_valid_o,
  output logic        retired_o,
  output logic        illegal_o,
  output logic [31:0] cycle_count_o
);
  localparam logic [2:0] RESET_MACHINE_CYCLES = 3'd5;

  logic [2:0] reset_cycles_remaining;
  logic       wrapper_clock_enable;
  logic       raw_program_write;
  logic       raw_io_read;
  logic       raw_io_write;
  logic       raw_data_write_address_valid;
  logic       memory_wait;

  assign reset_active_o = reset_i || (reset_cycles_remaining != 3'd0);

  // The callback requests are active during native strobe phases 1 through 3.
  // A synchronous memory therefore sees the address/request before the phase-3
  // sample edge. ready may remain high for an always-ready local memory.
  assign program_read_o = !native_men_n_o;
  assign program_write_o = raw_program_write && !native_we_n_o;
  assign io_read_o = raw_io_read && !native_den_n_o;
  assign io_write_o = raw_io_write && !native_we_n_o;

  assign memory_wait_o = memory_wait;
  assign wrapper_clock_enable = clock_enable_i && !memory_wait;
  assign phase_advance_o =
    wrapper_clock_enable && (reset_active_o || !pipeline_blocked_o);

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      reset_cycles_remaining <= RESET_MACHINE_CYCLES;
    end else if (
      wrapper_clock_enable &&
      (phase_o == 2'd3) &&
      (reset_cycles_remaining != 3'd0)
    ) begin
      reset_cycles_remaining <= reset_cycles_remaining - 3'd1;
    end
  end

  // Capture a late response while phase 2 advances to phase 3. Registering the
  // hold decision avoids a combinational path from callback readiness through
  // the pipeline's instruction qualification and back into its clock enable.
  // Once held, phase 3 advances on the first host edge after ready was seen.
  always_ff @(posedge clk_i) begin
    if (reset_i || reset_active_o) begin
      memory_wait <= 1'b0;
    end else if (memory_wait) begin
      if (
        ((program_read_o || program_write_o) && program_ready_i) ||
        ((io_read_o || io_write_o) && io_ready_i)
      ) begin
        memory_wait <= 1'b0;
      end
    end else if (phase_o == 2'd2) begin
      memory_wait <=
        ((program_read_o || program_write_o) && !program_ready_i) ||
        ((io_read_o || io_write_o) && !io_ready_i);
    end
  end

  tms32010_sequential_pipeline_slice pipeline (
    .clk_i                         (clk_i),
    .initialize_i                  (reset_i),
    .rs_i                          (reset_active_o),
    .clock_enable_i                (wrapper_clock_enable),
    .bio_i                         (bio_i),
    .int_i                         (int_i),
    .program_data_i                (program_read_data_i),
    .io_read_data_i                (io_read_data_i),
    .debug_data_write_i            (debug_data_write_i),
    .debug_data_address_i          (debug_data_address_i),
    .debug_data_i                  (debug_data_i),
    .phase_o                       (phase_o),
    .clkout_o                      (clkout_o),
    .program_address_o             (program_address_o),
    .men_n_o                       (native_men_n_o),
    .den_n_o                       (native_den_n_o),
    .we_n_o                        (native_we_n_o),
    .program_write_o               (raw_program_write),
    .program_write_data_o          (program_write_data_o),
    .sample_o                      (native_sample_o),
    .bus_active_o                  (native_bus_active_o),
    .execute_valid_o               (execute_valid_o),
    .execute_address_o             (execute_address_o),
    .execute_word_o                (execute_word_o),
    .pipeline_blocked_o            (pipeline_blocked_o),
    .data_address_o                (debug_data_address_o),
    .data_read_o                   (debug_data_read_o),
    .data_write_o                  (debug_data_write_o),
    .data_address_valid_o          (debug_data_address_valid_o),
    .data_write_address_o          (debug_data_write_address_o),
    .data_write_address_valid_o    (raw_data_write_address_valid),
    .data_read_data_o              (debug_data_read_data_o),
    .data_write_data_o             (debug_data_write_data_o),
    .io_port_o                     (io_port_o),
    .io_read_o                     (raw_io_read),
    .io_write_o                    (raw_io_write),
    .io_write_data_o               (io_write_data_o),
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
    .interrupt_pending_o           (interrupt_pending_o),
    .instruction_valid_o           (instruction_valid_o),
    .retired_o                     (retired_o),
    .illegal_o                     (illegal_o),
    .cycle_count_o                 (cycle_count_o)
  );

  always_ff @(posedge clk_i) begin
    if (!reset_i) begin
      assert (!(program_read_o && program_write_o));
      assert (!(io_read_o && io_write_o));
      assert (!((program_read_o || program_write_o) && (io_read_o || io_write_o)));
      assert (!program_write_o || raw_program_write);
      assert (!debug_data_write_o || raw_data_write_address_valid);
      assert (!memory_wait_o || !wrapper_clock_enable);
      assert (!memory_wait_o || (phase_o == 2'd3));
    end
  end
endmodule

`default_nettype wire
