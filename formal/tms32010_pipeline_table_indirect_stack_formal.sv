`default_nettype none

// FORMAL-001 bounded explicit-pipeline TBLR harness with a full prior stack.
// Four nested CALLs establish distinct stack words before one fixed indirect
// table read. This proves a primary-backed logical path, not arbitrary code,
// package delays, or analog clock-stopping behavior.
module tms32010_pipeline_table_indirect_stack_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  logic        initialized = 1'b0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic [1:0]  transfer_count = 2'd0;
  logic [15:0] program_data;
  logic [1:0]  phase;
  logic [11:0] program_address;
  logic        men_n;
  logic        den_n;
  logic        we_n;
  logic        program_write;
  logic [15:0] program_write_data;
  logic        sample;
  logic        bus_active;
  logic        execute_valid;
  logic [11:0] execute_address;
  logic [15:0] execute_word;
  logic        pipeline_blocked;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [7:0]  data_write_address;
  logic        data_write_address_valid;
  logic [15:0] data_read_data;
  logic [15:0] data_write_data;
  logic        io_read;
  logic        io_write;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        interrupt_mask;
  logic        interrupt_pending;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;

  assign initialize = !initialized;

  always_comb begin
    case (program_address)
      12'h000: program_data = 16'hf800;  // CALL 0x010
      12'h001: program_data = 16'h0010;
      12'h010: program_data = 16'hf800;  // CALL 0x030
      12'h011: program_data = 16'h0030;
      12'h020: program_data = 16'hb33c;  // table source word
      12'h030: program_data = 16'hf800;  // CALL 0x050
      12'h031: program_data = 16'h0050;
      12'h050: program_data = 16'hf800;  // CALL 0x080
      12'h051: program_data = 16'h0080;
      12'h080: program_data = 16'h7005;  // LARK AR0,5
      12'h081: program_data = 16'h7109;  // LARK AR1,9
      12'h082: program_data = 16'h7e20;  // LACK table address 0x020
      12'h083: program_data = 16'h67a1;  // TBLR *+,AR1
      12'h084: program_data = 16'h2005;  // repeated LAC 5
      default: program_data = 16'h7f80;  // NOP
    endcase
  end

  tms32010_sequential_pipeline_slice dut (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize),
    .rs_i                          (1'b0),
    .clock_enable_i                (clock_enable_i),
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
    .program_data_i                (program_data),
    .io_read_data_i                (16'h0000),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
    .phase_o                       (phase),
    .clkout_o                      (),
    .program_address_o             (program_address),
    .men_n_o                       (men_n),
    .den_n_o                       (den_n),
    .we_n_o                        (we_n),
    .program_write_o               (program_write),
    .program_write_data_o          (program_write_data),
    .sample_o                      (sample),
    .bus_active_o                  (bus_active),
    .execute_valid_o               (execute_valid),
    .execute_address_o             (execute_address),
    .execute_word_o                (execute_word),
    .pipeline_blocked_o            (pipeline_blocked),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (data_write_address),
    .data_write_address_valid_o    (data_write_address_valid),
    .data_read_data_o              (data_read_data),
    .data_write_data_o             (data_write_data),
    .io_port_o                     (),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (interrupt_mask),
    .interrupt_pending_o           (interrupt_pending),
    .instruction_valid_o           (),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
  );

  always_ff @(posedge clk_i) begin
    initialized <= 1'b1;
    past_valid <= 1'b1;

    if (initialize) begin
      transfer_count <= 2'd0;
    end else if (
      clock_enable_i &&
      bus_active &&
      (phase == 2'd3) &&
      data_write
    ) begin
      assert (cycle_count == 32'd12);
      assert (program_address == 12'h020);
      assert (data_address_valid);
      assert (data_write_address_valid);
      assert (data_address == 8'h05);
      assert (data_write_address == 8'h05);
      assert (data_write_data == 16'hb33c);
      transfer_count <= transfer_count + 2'd1;
    end

    if (initialized) begin
      assert (!illegal);
      assert (!pipeline_blocked);
      assert (den_n);
      assert (we_n);
      assert (!program_write);
      assert (!io_read);
      assert (!io_write);
      assert (!(data_read && data_write));
      assert (!(data_write && !data_write_address_valid));
      assert (interrupt_mask);
      assert (!interrupt_pending);
      assert (transfer_count <= 2'd1);

      if (bus_active) begin
        assert (men_n == (phase == 2'd0));
      end else begin
        assert (men_n);
      end

      if (data_write) begin
        assert (cycle_count == 32'd12);
        assert (execute_valid);
        assert (execute_address == 12'h083);
        assert (execute_word == 16'h67a1);
        assert (program_address == 12'h020);
        assert (data_address_valid);
        assert (data_write_address_valid);
        assert (data_address == 8'h05);
        assert (data_write_address == 8'h05);
        assert (data_write_data == 16'hb33c);
      end

      case (cycle_count)
        32'd0: begin
          assert (pc == 12'h000);
          assert (accumulator == 32'h0000_0000);
          assert (stack_top == 12'h000);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
        end
        32'd2: begin
          assert (pc == 12'h010);
          assert (stack_top == 12'h002);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
        end
        32'd4: begin
          assert (pc == 12'h030);
          assert (stack_top == 12'h012);
          assert (stack_level_1 == 12'h002);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
        end
        32'd6: begin
          assert (pc == 12'h050);
          assert (stack_top == 12'h032);
          assert (stack_level_1 == 12'h012);
          assert (stack_level_2 == 12'h002);
          assert (stack_bottom == 12'h000);
        end
        32'd8: begin
          assert (pc == 12'h080);
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h002);
        end
        32'd11: begin
          assert (pc == 12'h083);
          assert (accumulator == 32'h0000_0020);
          assert (auxiliary_register_0 == 16'h0005);
          assert (auxiliary_register_1 == 16'h0009);
          assert (!auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h083);
          assert (execute_word == 16'h67a1);
          assert (program_address == 12'h084);
          assert (!(data_read || data_write));
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h002);
          assert (transfer_count == 2'd0);
        end
        32'd12: begin
          assert (pc == 12'h084);
          assert (accumulator == 32'h0000_0020);
          assert (auxiliary_register_0 == 16'h0005);
          assert (auxiliary_register_1 == 16'h0009);
          assert (!auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h083);
          assert (execute_word == 16'h67a1);
          assert (program_address == 12'h020);
          assert (!data_read && data_write);
          assert (data_address_valid);
          assert (data_write_address_valid);
          assert (data_address == 8'h05);
          assert (data_write_address == 8'h05);
          assert (data_write_data == 16'hb33c);
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h002);
          assert (transfer_count == 2'd0);
        end
        32'd13: begin
          assert (pc == 12'h084);
          assert (accumulator == 32'h0000_0020);
          assert (auxiliary_register_0 == 16'h0005);
          assert (auxiliary_register_1 == 16'h0009);
          assert (!auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h083);
          assert (execute_word == 16'h67a1);
          assert (program_address == 12'h084);
          assert (!(data_read || data_write));
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h002);
          assert (transfer_count == 2'd1);
        end
        32'd14: begin
          assert (pc == 12'h084);
          assert (accumulator == 32'h0000_0020);
          assert (auxiliary_register_0 == 16'h0006);
          assert (auxiliary_register_1 == 16'h0009);
          assert (auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h084);
          assert (execute_word == 16'h2005);
          assert (program_address == 12'h085);
          assert (data_read && !data_write);
          assert (data_address_valid);
          assert (data_address == 8'h05);
          assert (data_read_data == 16'hb33c);
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h012);
          assert (transfer_count == 2'd1);
        end
        32'd15: begin
          assert (pc == 12'h085);
          assert (accumulator == 32'hffff_b33c);
          assert (auxiliary_register_0 == 16'h0006);
          assert (auxiliary_register_1 == 16'h0009);
          assert (auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h085);
          assert (execute_word == 16'h7f80);
          assert (program_address == 12'h086);
          assert (!(data_read || data_write));
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h012);
          assert (transfer_count == 2'd1);
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
        phase,
        program_address,
        men_n,
        den_n,
        we_n,
        program_write,
        program_write_data,
        bus_active,
        execute_valid,
        execute_address,
        execute_word,
        pipeline_blocked,
        data_address,
        data_read,
        data_write,
        data_address_valid,
        data_write_address,
        data_write_address_valid,
        data_read_data,
        data_write_data,
        io_read,
        io_write,
        pc,
        accumulator,
        auxiliary_register_0,
        auxiliary_register_1,
        auxiliary_register_pointer,
        stack_top,
        stack_level_1,
        stack_level_2,
        stack_bottom,
        interrupt_mask,
        interrupt_pending,
        illegal,
        cycle_count,
        transfer_count
      } == $past({
        phase,
        program_address,
        men_n,
        den_n,
        we_n,
        program_write,
        program_write_data,
        bus_active,
        execute_valid,
        execute_address,
        execute_word,
        pipeline_blocked,
        data_address,
        data_read,
        data_write,
        data_address_valid,
        data_write_address,
        data_write_address_valid,
        data_read_data,
        data_write_data,
        io_read,
        io_write,
        pc,
        accumulator,
        auxiliary_register_0,
        auxiliary_register_1,
        auxiliary_register_pointer,
        stack_top,
        stack_level_1,
        stack_level_2,
        stack_bottom,
        interrupt_mask,
        interrupt_pending,
        illegal,
        cycle_count,
        transfer_count
      }));
    end

    cover (
      initialized &&
      (cycle_count == 32'd15) &&
      (pc == 12'h085) &&
      (accumulator == 32'hffff_b33c) &&
      (auxiliary_register_0 == 16'h0006) &&
      (auxiliary_register_1 == 16'h0009) &&
      auxiliary_register_pointer &&
      ({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
        {12'h052, 12'h032, 12'h012, 12'h012}) &&
      (transfer_count == 2'd1)
    );
  end
endmodule

`default_nettype wire
