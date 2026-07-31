create_clock -name clk_i -period 20.000 [get_ports {clk_i}]
derive_clock_uncertainty

# This is an internal-timing synthesis harness, not an integration wrapper.
# Interface timing depends on the eventual memory/host wrapper, so every
# non-clock harness port is explicitly excluded rather than assigned invented
# board delays. The integrated wrapper must replace these false paths with
# real I/O or register-to-register constraints.
set_false_path -from \
  [get_ports {initialize_i rs_i clock_enable_i program_data_i[*] \
              debug_data_write_i debug_data_address_i[*] debug_data_i[*]}]
set_false_path -to \
  [get_ports {pc_o[*] accumulator_o[*] t_register_o[*] product_register_o[*] \
              auxiliary_register_0_o[*] auxiliary_register_1_o[*] \
              auxiliary_register_pointer_o data_page_pointer_o \
              overflow_flag_o overflow_mode_o interrupt_mask_o instruction_valid_o \
              retired_o illegal_o \
              cycle_count_o[*] phase_o[*] clkout_o native_address_o[*] \
              men_n_o sample_o native_active_o data_address_o[*] \
              data_read_o data_write_o data_address_valid_o \
              data_read_data_o[*] data_write_data_o[*]}]
