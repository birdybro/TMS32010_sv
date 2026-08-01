`default_nettype none

// CTRL-001 bounded proof for the core's already-recognized architectural
// reset boundary. Native RS assertion duration, phase recognition, and first
// fetch timing are separate properties of tms32010_program_bus.
module tms32010_reset_formal (
  input logic clk_i,
  input logic reset_i,
  input logic clock_enable_i
);
  logic        initialized = 1'b0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic [15:0] program_data;
  logic [11:0] program_address;
  logic        program_read;
  logic        program_write;
  logic        io_read;
  logic        io_write;
  logic        data_read;
  logic        data_write;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] t_register;
  logic [31:0] product_register;
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
  logic        data_page_pointer;
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        overflow_flag;
  logic        overflow_mode;
  logic        interrupt_mask;
  logic        interrupt_pending;
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;

  assign initialize = !initialized;

  // A short primary-qualified program makes the retention cover nonvacuous:
  // SOVM establishes explicitly retained OVM, then LACK establishes ACC state
  // whose reset behavior is unlisted and provisionally retained under OQ-012.
  always_comb begin
    case (program_address)
      12'h000: program_data = 16'h7f8b; // SOVM
      12'h001: program_data = 16'h7e5a; // LACK 0x5a
      default: program_data = 16'h7f80; // NOP
    endcase
  end

  tms32010_core dut (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize),
    .reset_i                       (reset_i),
    .clock_enable_i                (clock_enable_i),
    .internal_ram_read_enable_i    (clock_enable_i),
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
    .program_address_o             (program_address),
    .program_next_address_o        (),
    .program_read_o                (program_read),
    .program_write_o               (program_write),
    .program_write_data_o          (),
    .program_data_i                (program_data),
    .io_port_o                     (),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (),
    .io_read_data_i                (16'h0000),
    .data_address_o                (),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
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
    .t_register_o                  (t_register),
    .product_register_o            (product_register),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (data_page_pointer),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
    .overflow_flag_o               (overflow_flag),
    .overflow_mode_o               (overflow_mode),
    .interrupt_mask_o              (interrupt_mask),
    .interrupt_pending_o           (interrupt_pending),
    .instruction_valid_o           (instruction_valid),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
  );

  always_ff @(posedge clk_i) begin
    initialized <= 1'b1;
    past_valid  <= 1'b1;

    if (initialized && reset_i) begin
      assert (!program_read && !program_write);
      assert (!io_read && !io_write);
      assert (!data_read && !data_write);
      assert (!instruction_valid);
    end

    if (past_valid) begin
      if ($past(initialize)) begin
        assert (pc == 12'h000);
        assert (accumulator == 32'h0000_0000);
        assert (t_register == 16'h0000);
        assert (product_register == 32'h0000_0000);
        assert (auxiliary_register_0 == 16'h0000);
        assert (auxiliary_register_1 == 16'h0000);
        assert (!auxiliary_register_pointer);
        assert (!data_page_pointer);
        assert ({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
                48'h0000_0000_0000);
        assert (!overflow_flag && !overflow_mode);
        assert (interrupt_mask && !interrupt_pending);
        assert (!retired && !illegal && cycle_count == 32'h0000_0000);
      end else if ($past(reset_i)) begin
        // TI-defined physical-reset effects.
        assert (pc == 12'h000);
        assert (interrupt_mask && !interrupt_pending);
        assert (!retired && !illegal && cycle_count == 32'h0000_0000);

        // OVM retention is TI-defined. Every other member of this bundle is
        // only the current PROVISIONAL FPGA retention policy under OQ-012.
        assert ({
          accumulator,
          t_register,
          product_register,
          auxiliary_register_0,
          auxiliary_register_1,
          auxiliary_register_pointer,
          data_page_pointer,
          stack_top,
          stack_level_1,
          stack_level_2,
          stack_bottom,
          overflow_flag,
          overflow_mode
        } == $past({
          accumulator,
          t_register,
          product_register,
          auxiliary_register_0,
          auxiliary_register_1,
          auxiliary_register_pointer,
          data_page_pointer,
          stack_top,
          stack_level_1,
          stack_level_2,
          stack_bottom,
          overflow_flag,
          overflow_mode
        }));
      end
    end

    cover (
      initialized &&
      reset_i &&
      (pc == 12'h000) &&
      (accumulator == 32'h0000_005a) &&
      overflow_mode &&
      interrupt_mask &&
      !instruction_valid
    );
  end
endmodule

`default_nettype wire
