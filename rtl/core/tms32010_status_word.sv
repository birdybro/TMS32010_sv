`default_nettype none

// Portable architectural status-word pack/extract relation. The caller maps
// the four writable LST word positions to the load inputs and owns LST/SST
// addressing, old/new ordering, commits, and INTM preservation.
module tms32010_status_word (
  input  logic        overflow_i,
  input  logic        overflow_mode_i,
  input  logic        interrupt_mask_i,
  input  logic        auxiliary_register_pointer_i,
  input  logic        data_page_pointer_i,
  input  logic        load_overflow_i,
  input  logic        load_overflow_mode_i,
  input  logic        load_auxiliary_register_pointer_i,
  input  logic        load_data_page_pointer_i,
  output logic [15:0] store_word_o,
  output logic        loaded_overflow_o,
  output logic        loaded_overflow_mode_o,
  output logic        loaded_auxiliary_register_pointer_o,
  output logic        loaded_data_page_pointer_o
);
  always_comb begin
    store_word_o = {
      overflow_i,
      overflow_mode_i,
      interrupt_mask_i,
      4'hf,
      auxiliary_register_pointer_i,
      7'h7f,
      data_page_pointer_i
    };

    loaded_overflow_o                    = load_overflow_i;
    loaded_overflow_mode_o               = load_overflow_mode_i;
    loaded_auxiliary_register_pointer_o  = load_auxiliary_register_pointer_i;
    loaded_data_page_pointer_o           = load_data_page_pointer_i;
  end
endmodule

`default_nettype wire
