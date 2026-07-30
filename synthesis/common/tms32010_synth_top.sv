`default_nettype none

// Synthesis-only harness: elaborates both independently verified partial RTL
// blocks without claiming that their temporary interfaces are integrated.
module tms32010_synth_top (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        rs_i,
  input  logic        clock_enable_i,
  input  logic [15:0] program_data_i,
  input  logic [11:0] next_address_i,

  output logic [11:0] program_address_o,
  output logic        program_read_o,
  output logic [11:0] pc_o,
  output logic [31:0] accumulator_o,
  output logic [15:0] auxiliary_register_0_o,
  output logic [15:0] auxiliary_register_1_o,
  output logic        auxiliary_register_pointer_o,
  output logic        data_page_pointer_o,
  output logic        overflow_mode_o,
  output logic        interrupt_mask_o,
  output logic        retired_o,
  output logic        illegal_o,
  output logic [31:0] cycle_count_o,

  output logic [1:0]  phase_o,
  output logic        clkout_o,
  output logic [11:0] native_address_o,
  output logic        men_n_o,
  output logic        sample_o,
  output logic        native_active_o
);
  tms32010_core core (
    .clk_i             (clk_i),
    .reset_i           (initialize_i | rs_i),
    .clock_enable_i    (clock_enable_i),
    .program_address_o (program_address_o),
    .program_read_o    (program_read_o),
    .program_data_i    (program_data_i),
    .pc_o              (pc_o),
    .accumulator_o     (accumulator_o),
    .auxiliary_register_0_o (auxiliary_register_0_o),
    .auxiliary_register_1_o (auxiliary_register_1_o),
    .auxiliary_register_pointer_o (auxiliary_register_pointer_o),
    .data_page_pointer_o (data_page_pointer_o),
    .overflow_mode_o   (overflow_mode_o),
    .interrupt_mask_o  (interrupt_mask_o),
    .retired_o         (retired_o),
    .illegal_o         (illegal_o),
    .cycle_count_o     (cycle_count_o)
  );

  tms32010_program_bus program_bus (
    .clk_i          (clk_i),
    .initialize_i   (initialize_i),
    .rs_i           (rs_i),
    .clock_enable_i (clock_enable_i),
    .next_address_i (next_address_i),
    .phase_o        (phase_o),
    .clkout_o       (clkout_o),
    .address_o      (native_address_o),
    .men_n_o        (men_n_o),
    .sample_o       (sample_o),
    .active_o       (native_active_o)
  );
endmodule

`default_nettype wire
