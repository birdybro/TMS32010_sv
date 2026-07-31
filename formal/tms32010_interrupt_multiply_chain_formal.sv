`default_nettype none

// FORMAL-001 bounded harness for data-memory MPY and repeated multiply
// interrupt deferral. See formal/README.md for assumptions and excluded claims.
module tms32010_interrupt_multiply_chain_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  logic [1:0]  initialize_count = 2'd0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic        initialized;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic        int_n;
  logic [15:0] program_data;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic        program_read;
  logic        program_write;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [15:0] data_read_data;
  logic        io_read;
  logic        io_write;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] t_register;
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

  assign initialize = initialize_count != 2'd3;
  assign initialized = !initialize;
  assign debug_data_write = initialize;

  always_comb begin
    debug_data_address = 8'h00;
    debug_data = 16'h8000;
    case (initialize_count)
      2'd0: begin
        debug_data_address = 8'h00;
        debug_data = 16'h8000;
      end
      2'd1: begin
        debug_data_address = 8'h01;
        debug_data = 16'h0002;
      end
      2'd2: begin
        debug_data_address = 8'h02;
        debug_data = 16'hffff;
      end
      default: begin
      end
    endcase
  end

  // A pulse sampled by the NOP at address 2 arms service. It remains low
  // through arbitrary stalls at that instruction and returns high afterward.
  assign int_n = !(initialized && (cycle_count == 32'd2));

  always_comb begin
    case (program_address)
      12'h000: program_data = 16'h6a00;  // LT 0: T = 0x8000
      12'h001: program_data = 16'h7f82;  // EINT
      12'h002: program_data = 16'h7f80;  // request-sampling NOP / vector NOP
      12'h003: program_data = 16'h6d01;  // protected MPY 1: -32768 * 2
      12'h004: program_data = 16'h9ffe;  // chained MPYK -2
      12'h005: program_data = 16'h6d02;  // chained MPY 2: -32768 * -1
      12'h006: program_data = 16'h7e55;  // instruction protected by final MPY
      12'h007: program_data = 16'h7f89;  // dummy-fetched ZAC
      default: program_data = 16'h7f80;  // NOP
    endcase
  end

  tms32010_core dut (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize),
    .reset_i                       (1'b0),
    .clock_enable_i                (clock_enable_i),
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
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (data_read_data),
    .data_write_data_o             (),
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (t_register),
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
    if (initialize_count != 2'd3) begin
      initialize_count <= initialize_count + 2'd1;
    end
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
          assert (data_read && data_address_valid);
          assert (data_address == 8'h00);
          assert (data_read_data == 16'h8000);
        end
        32'd1: begin
          assert (pc == 12'h001);
          assert (t_register == 16'h8000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
        end
        32'd2: begin
          assert (pc == 12'h002);
          assert (t_register == 16'h8000);
          assert (!interrupt_mask);
          assert (!interrupt_pending);
        end
        32'd3: begin
          assert (pc == 12'h003);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
          assert (data_read && data_address_valid);
          assert (data_address == 8'h01);
          assert (data_read_data == 16'h0002);
        end
        32'd4: begin
          assert (pc == 12'h004);
          assert (product_register == 32'hffff_0000);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
          assert (!data_read);
        end
        32'd5: begin
          assert (pc == 12'h005);
          assert (product_register == 32'h0001_0000);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
          assert (data_read && data_address_valid);
          assert (data_address == 8'h02);
          assert (data_read_data == 16'hffff);
        end
        32'd6: begin
          assert (pc == 12'h006);
          assert (product_register == 32'h0000_8000);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
        end
        32'd7: begin
          assert (pc == 12'h007);
          assert (accumulator == 32'h0000_0055);
          assert (product_register == 32'h0000_8000);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (!instruction_valid);
          assert (program_address == 12'h007);
          assert (program_next_address == 12'h002);
          assert (!(program_write || data_read || data_write ||
                    io_read || io_write));
        end
        32'd8: begin
          assert (pc == 12'h002);
          assert (accumulator == 32'h0000_0055);
          assert (product_register == 32'h0000_8000);
          assert (stack_top == 12'h007);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
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
        t_register,
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
        t_register,
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
        data_address,
        data_read,
        data_write,
        data_address_valid,
        data_read_data,
        io_read,
        io_write,
        instruction_valid
      } == $past({
        program_address,
        program_next_address,
        program_read,
        program_write,
        data_address,
        data_read,
        data_write,
        data_address_valid,
        data_read_data,
        io_read,
        io_write,
        instruction_valid
      }));
    end

    cover (
      initialized &&
      (cycle_count == 32'd8) &&
      (pc == 12'h002) &&
      (accumulator == 32'h0000_0055) &&
      (product_register == 32'h0000_8000) &&
      (stack_top == 12'h007) &&
      interrupt_mask &&
      !interrupt_pending
    );
  end
endmodule

`default_nettype wire
