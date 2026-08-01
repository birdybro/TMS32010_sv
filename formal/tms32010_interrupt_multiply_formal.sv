`default_nettype none

// FORMAL-001 bounded harness for MPYK interrupt deferral and held-low
// relatching. See formal/README.md for assumptions and excluded claims.
module tms32010_interrupt_multiply_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  logic        initialized = 1'b0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic        int_n;
  logic [15:0] program_data;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic        program_read;
  logic        program_write;
  logic        data_read;
  logic        data_write;
  logic        io_read;
  logic        io_write;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [31:0] product_register;
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        interrupt_mask;
  logic        interrupt_pending;
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;

  assign initialize = !initialized;

  // The first EINT executes without a request. INT then remains low from the
  // following NOP through acknowledge and vector execution.
  assign int_n = !(initialized && (cycle_count >= 32'd1));

  always_comb begin
    case (program_address)
      12'h000: program_data = 16'h7f82;  // EINT
      12'h001: program_data = 16'h7f80;  // request-sampling NOP
      12'h002: program_data = 16'h8002;  // protected MPYK, then vector MPYK
      12'h003: program_data = 16'h7e44;  // instruction protected by MPYK
      12'h004: program_data = 16'h7f89;  // dummy-fetched ZAC
      default: program_data = 16'h7f80;  // NOP
    endcase
  end

  tms32010_core dut (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize),
    .reset_i                       (1'b0),
    .clock_enable_i                (clock_enable_i),
    .internal_ram_read_enable_i    (clock_enable_i),
    .bio_i                         (1'b1),
    .int_i                         (int_n),
    .program_address_o             (program_address),
    .program_next_address_o        (program_next_address),
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
    .t_register_o                  (),
    .product_register_o            (product_register),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (interrupt_mask),
    .interrupt_pending_o           (interrupt_pending),
    .instruction_valid_o           (instruction_valid),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
  );

  always_ff @(posedge clk_i) begin
    initialized <= 1'b1;
    past_valid <= 1'b1;

    if (initialized) begin
      assert (!illegal);
      assert (program_read);
      assert (!(program_read && program_write));

      case (cycle_count)
        32'd0: begin
          assert (pc == 12'h000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
        end
        32'd1: begin
          assert (pc == 12'h001);
          assert (!interrupt_mask);
          assert (!interrupt_pending);
        end
        32'd2: begin
          assert (pc == 12'h002);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
        end
        32'd3: begin
          assert (pc == 12'h003);
          assert (product_register == 32'h0000_0000);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
        end
        32'd4: begin
          assert (pc == 12'h004);
          assert (accumulator == 32'h0000_0044);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (!instruction_valid);
          assert (program_address == 12'h004);
          assert (program_next_address == 12'h002);
          assert (!(program_write || data_read || data_write ||
                    io_read || io_write));
        end
        32'd5: begin
          assert (pc == 12'h002);
          assert (accumulator == 32'h0000_0044);
          assert (stack_top == 12'h004);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
        end
        32'd6: begin
          assert (pc == 12'h003);
          assert (accumulator == 32'h0000_0044);
          assert (product_register == 32'h0000_0000);
          assert (stack_top == 12'h004);
          assert (interrupt_mask);
          assert (interrupt_pending);
        end
        default: begin
        end
      endcase
    end

    if (
      past_valid &&
      $past(initialized) &&
      !$past(clock_enable_i)
    ) begin
      assert ({
        pc,
        accumulator,
        product_register,
        stack_top,
        stack_level_1,
        stack_level_2,
        stack_bottom,
        interrupt_mask,
        interrupt_pending,
        illegal,
        cycle_count
      } == $past({
        pc,
        accumulator,
        product_register,
        stack_top,
        stack_level_1,
        stack_level_2,
        stack_bottom,
        interrupt_mask,
        interrupt_pending,
        illegal,
        cycle_count
      }));
      assert ({
        program_address,
        program_next_address,
        program_read,
        program_write,
        data_read,
        data_write,
        io_read,
        io_write,
        instruction_valid
      } == $past({
        program_address,
        program_next_address,
        program_read,
        program_write,
        data_read,
        data_write,
        io_read,
        io_write,
        instruction_valid
      }));
    end

    cover (
      initialized &&
      (cycle_count == 32'd6) &&
      (pc == 12'h003) &&
      (accumulator == 32'h0000_0044) &&
      (stack_top == 12'h004) &&
      interrupt_mask &&
      interrupt_pending
    );
  end
endmodule

`default_nettype wire
