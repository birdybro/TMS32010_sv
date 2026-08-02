`default_nettype none

// Symbolic contract for every architectural field and every possible LST
// source word. The reference constructs the SST representation bit by bit.
module tms32010_status_word_formal (
  input logic        overflow_i,
  input logic        overflow_mode_i,
  input logic        interrupt_mask_i,
  input logic        auxiliary_register_pointer_i,
  input logic        data_page_pointer_i,
  input logic [15:0] load_word_i
);
  logic [15:0] expected_store_word;
  logic [15:0] store_word;
  logic        loaded_overflow;
  logic        loaded_overflow_mode;
  logic        loaded_auxiliary_register_pointer;
  logic        loaded_data_page_pointer;
  integer      bit_index;

  always_comb begin
    expected_store_word = 16'h0000;
    for (bit_index = 0; bit_index < 16; bit_index = bit_index + 1) begin
      case (bit_index)
        0: expected_store_word[bit_index] = data_page_pointer_i;
        8: expected_store_word[bit_index] = auxiliary_register_pointer_i;
        13: expected_store_word[bit_index] = interrupt_mask_i;
        14: expected_store_word[bit_index] = overflow_mode_i;
        15: expected_store_word[bit_index] = overflow_i;
        default: expected_store_word[bit_index] = 1'b1;
      endcase
    end
  end

  tms32010_status_word dut (
    .overflow_i                          (overflow_i),
    .overflow_mode_i                     (overflow_mode_i),
    .interrupt_mask_i                    (interrupt_mask_i),
    .auxiliary_register_pointer_i        (auxiliary_register_pointer_i),
    .data_page_pointer_i                 (data_page_pointer_i),
    .load_overflow_i                     (load_word_i[15]),
    .load_overflow_mode_i                (load_word_i[14]),
    .load_auxiliary_register_pointer_i   (load_word_i[8]),
    .load_data_page_pointer_i            (load_word_i[0]),
    .store_word_o                        (store_word),
    .loaded_overflow_o                   (loaded_overflow),
    .loaded_overflow_mode_o              (loaded_overflow_mode),
    .loaded_auxiliary_register_pointer_o (loaded_auxiliary_register_pointer),
    .loaded_data_page_pointer_o          (loaded_data_page_pointer)
  );

  always_comb begin
    assert (store_word == expected_store_word);
    assert (loaded_overflow == load_word_i[15]);
    assert (loaded_overflow_mode == load_word_i[14]);
    assert (loaded_auxiliary_register_pointer == load_word_i[8]);
    assert (loaded_data_page_pointer == load_word_i[0]);

    cover (store_word == 16'h1efe);
    cover (store_word == 16'hffff);
    cover (load_word_i == 16'hc101);
    cover (load_word_i == 16'h3efe);
    cover (
      load_word_i == 16'h3cfe &&
      !loaded_overflow && !loaded_overflow_mode &&
      !loaded_auxiliary_register_pointer && !loaded_data_page_pointer
    );
  end
endmodule

`default_nettype wire
