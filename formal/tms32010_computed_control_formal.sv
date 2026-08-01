`default_nettype none

// ADR-0003 bounded proof over the actual core. The fixed program exercises
// CALA, a target instruction, RET, and the returned instruction. Arbitrary
// clock_enable_i proves that either half of each two-cycle instruction may
// stall without early stack or PC effects. Pin-level address sequencing is a
// separate property of tms32010_sequential_pipeline_slice.
module tms32010_computed_control_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  logic        initialized = 1'b0;
  logic        past_valid = 1'b0;
  logic        initialize;
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
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        instruction_valid;
  logic        illegal;
  logic [31:0] cycle_count;

  assign initialize = !initialized;

  always_comb begin
    case (program_address)
      12'h000: program_data = 16'h7e06; // LACK 6
      12'h001: program_data = 16'h7f8c; // CALA
      12'h002: program_data = 16'h7eee; // returned LACK 0xee
      12'h006: program_data = 16'h7e44; // CALA target
      12'h007: program_data = 16'h7f8d; // RET
      12'h008: program_data = 16'h7edd; // discarded LACK 0xdd
      default: program_data = 16'h7f80;
    endcase
  end

  tms32010_core dut (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize),
    .reset_i                       (1'b0),
    .clock_enable_i                (clock_enable_i),
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
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
    .product_register_o            (),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
    .overflow_flag_o                (),
    .overflow_mode_o                (),
    .interrupt_mask_o               (),
    .interrupt_pending_o            (),
    .instruction_valid_o            (instruction_valid),
    .retired_o                      (),
    .illegal_o                      (illegal),
    .cycle_count_o                  (cycle_count)
  );

  always_ff @(posedge clk_i) begin
    initialized <= 1'b1;
    past_valid  <= 1'b1;

    if (initialized) begin
      assert (!illegal);
      assert (instruction_valid);
      assert (program_read && !program_write);
      assert (!(data_read || data_write || io_read || io_write));

      case (cycle_count)
        32'd0: begin
          assert (pc == 12'h000 && accumulator == 32'h0000_0000);
          assert ({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
                  48'h000_000_000_000);
          assert (program_next_address == 12'h001);
        end
        32'd1: begin
          assert (pc == 12'h001 && accumulator == 32'h0000_0006);
          assert (stack_top == 12'h000);
          assert (program_next_address == 12'h006);
        end
        32'd2: begin
          assert (pc == 12'h002 && accumulator == 32'h0000_0006);
          assert ({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
                  48'h000_000_000_000);
          assert (program_next_address == 12'h006);
        end
        32'd3: begin
          assert (pc == 12'h006 && accumulator == 32'h0000_0006);
          assert ({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
                  48'h002_000_000_000);
          assert (program_next_address == 12'h007);
        end
        32'd4: begin
          assert (pc == 12'h007 && accumulator == 32'h0000_0044);
          assert (stack_top == 12'h002);
          assert (program_next_address == 12'h002);
        end
        32'd5: begin
          assert (pc == 12'h008 && accumulator == 32'h0000_0044);
          assert ({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
                  48'h002_000_000_000);
          assert (program_next_address == 12'h002);
        end
        32'd6: begin
          assert (pc == 12'h002 && accumulator == 32'h0000_0044);
          assert ({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
                  48'h000_000_000_000);
          assert (program_next_address == 12'h003);
        end
        32'd7: begin
          assert (pc == 12'h003 && accumulator == 32'h0000_00ee);
          assert ({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
                  48'h000_000_000_000);
        end
        default: begin
        end
      endcase
    end

    if (past_valid && $past(initialized) && !$past(clock_enable_i)) begin
      assert ({
        pc,
        accumulator,
        stack_top,
        stack_level_1,
        stack_level_2,
        stack_bottom,
        illegal,
        cycle_count
      } == $past({
        pc,
        accumulator,
        stack_top,
        stack_level_1,
        stack_level_2,
        stack_bottom,
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
      (cycle_count == 32'd7) &&
      (pc == 12'h003) &&
      (accumulator == 32'h0000_00ee) &&
      (stack_top == 12'h000)
    );
  end
endmodule

`default_nettype wire
