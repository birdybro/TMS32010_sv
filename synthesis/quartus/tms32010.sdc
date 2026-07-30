create_clock -name clk_i -period 20.000 [get_ports {clk_i}]
derive_clock_uncertainty

set_input_delay -clock clk_i -max 2.000 \
  [get_ports {reset_i clock_enable_i program_data_i[*]}]
set_input_delay -clock clk_i -min 0.000 \
  [get_ports {reset_i clock_enable_i program_data_i[*]}]

set_output_delay -clock clk_i -max 2.000 \
  [get_ports {program_address_o[*] program_read_o pc_o[*] accumulator_o[*] \
              overflow_mode_o interrupt_mask_o retired_o illegal_o \
              cycle_count_o[*]}]
set_output_delay -clock clk_i -min 0.000 \
  [get_ports {program_address_o[*] program_read_o pc_o[*] accumulator_o[*] \
              overflow_mode_o interrupt_mask_o retired_o illegal_o \
              cycle_count_o[*]}]
