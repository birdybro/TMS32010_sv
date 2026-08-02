`default_nettype none

// FORMAL-001 bounded explicit-pipeline TBLW harness with a full prior stack.
// Four nested CALLs establish distinct stack words before one fixed indirect
// table write. The program target differs from PC+1 so ACC ownership and the
// repeated sequential fetch remain independently observable.
module tms32010_pipeline_table_indirect_stack_write_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  logic [1:0]  initialize_count = 2'd0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic        initialized;
  logic [15:0] mutable_program_word = 16'h7f80;
  logic        write_seen = 1'b0;
  logic [1:0]  write_count = 2'd0;
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

  assign initialize = initialize_count != 2'd2;
  assign initialized = !initialize;

  always_comb begin
    case (program_address)
      12'h000: program_data = 16'hf800;  // CALL 0x010
      12'h001: program_data = 16'h0010;
      12'h010: program_data = 16'hf800;  // CALL 0x030
      12'h011: program_data = 16'h0030;
      12'h030: program_data = 16'hf800;  // CALL 0x050
      12'h031: program_data = 16'h0050;
      12'h050: program_data = 16'hf800;  // CALL 0x080
      12'h051: program_data = 16'h0080;
      12'h080: program_data = 16'h7005;  // LARK AR0,5
      12'h081: program_data = 16'h7109;  // LARK AR1,9
      12'h082: program_data = 16'h6881;  // LARP 1
      12'h083: program_data = 16'h7e86;  // LACK table address 0x086
      12'h084: program_data = 16'h7d90;  // TBLW *-,AR0
      12'h085: program_data = 16'h7f89;  // discarded then repeated ZAC
      12'h086: program_data = mutable_program_word;
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
    .debug_data_write_i            (initialize),
    .debug_data_address_i          (8'h09),
    .debug_data_i                  (16'h7e44),
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
    if (initialize_count != 2'd2) begin
      initialize_count <= initialize_count + 2'd1;
    end
    past_valid <= 1'b1;

    if (initialize) begin
      mutable_program_word <= 16'h7f80;
      write_seen <= 1'b0;
      write_count <= 2'd0;
    end else if (
      clock_enable_i &&
      bus_active &&
      (phase == 2'd3) &&
      program_write
    ) begin
      assert (cycle_count == 32'd13);
      assert (program_address == 12'h086);
      assert (program_write_data == 16'h7e44);
      mutable_program_word <= program_write_data;
      write_seen <= 1'b1;
      write_count <= write_count + 2'd1;
    end

    if (initialized) begin
      assert (!illegal);
      assert (!pipeline_blocked);
      assert (den_n);
      assert (!io_read);
      assert (!io_write);
      assert (!data_write);
      assert (interrupt_mask);
      assert (!interrupt_pending);
      assert (write_count <= 2'd1);
      assert (!(
        (!men_n && !we_n) ||
        (!men_n && !den_n) ||
        (!den_n && !we_n)
      ));

      if (program_write) begin
        assert (bus_active);
        assert (cycle_count == 32'd13);
        assert (execute_valid);
        assert (execute_address == 12'h084);
        assert (execute_word == 16'h7d90);
        assert (program_address == 12'h086);
        assert (program_write_data == 16'h7e44);
        assert (data_read);
        assert (data_address_valid);
        assert (data_address == 8'h09);
        assert (data_read_data == 16'h7e44);
        assert (men_n);
        assert (we_n == (phase == 2'd0));
      end else if (bus_active) begin
        assert (we_n);
        assert (men_n == (phase == 2'd0));
      end else begin
        assert (men_n);
        assert (we_n);
      end

      // The core's combinational decode diagnostics are meaningful only when
      // the pipeline marks the execute word valid. DEN remains inactive for
      // invalid words, so do not misclassify an unstrobed diagnostic as an
      // architectural data-memory transaction.
      if (data_read && execute_valid) begin
        assert (cycle_count == 32'd13);
        assert (program_write);
        assert (data_address_valid);
        assert (data_address == 8'h09);
        assert (data_read_data == 16'h7e44);
      end

      if (write_seen) begin
        assert (mutable_program_word == 16'h7e44);
        assert (write_count == 2'd1);
      end else begin
        assert (mutable_program_word == 16'h7f80);
        assert (write_count == 2'd0);
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
        32'd10: begin
          assert (pc == 12'h082);
          assert (accumulator == 32'h0000_0000);
          assert (auxiliary_register_0 == 16'h0005);
          assert (auxiliary_register_1 == 16'h0009);
          assert (!auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h082);
          assert (execute_word == 16'h6881);
          assert (program_address == 12'h083);
        end
        32'd11: begin
          assert (pc == 12'h083);
          assert (accumulator == 32'h0000_0000);
          assert (auxiliary_register_0 == 16'h0005);
          assert (auxiliary_register_1 == 16'h0009);
          assert (auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h083);
          assert (execute_word == 16'h7e86);
          assert (program_address == 12'h084);
        end
        32'd12: begin
          assert (pc == 12'h084);
          assert (accumulator == 32'h0000_0086);
          assert (auxiliary_register_0 == 16'h0005);
          assert (auxiliary_register_1 == 16'h0009);
          assert (auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h084);
          assert (execute_word == 16'h7d90);
          assert (program_address == 12'h085);
          assert (!program_write);
          assert (!data_read);
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h002);
          assert (!write_seen);
        end
        32'd13: begin
          assert (pc == 12'h085);
          assert (accumulator == 32'h0000_0086);
          assert (auxiliary_register_0 == 16'h0005);
          assert (auxiliary_register_1 == 16'h0009);
          assert (auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h084);
          assert (execute_word == 16'h7d90);
          assert (program_address == 12'h086);
          assert (program_write);
          assert (program_write_data == 16'h7e44);
          assert (data_read && !data_write);
          assert (data_address_valid);
          assert (data_address == 8'h09);
          assert (data_read_data == 16'h7e44);
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h002);
          assert (!write_seen);
        end
        32'd14: begin
          assert (pc == 12'h085);
          assert (accumulator == 32'h0000_0086);
          assert (auxiliary_register_0 == 16'h0005);
          assert (auxiliary_register_1 == 16'h0009);
          assert (auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h084);
          assert (execute_word == 16'h7d90);
          assert (program_address == 12'h085);
          assert (!program_write);
          assert (!data_read);
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h002);
          assert (write_seen);
        end
        32'd15: begin
          assert (pc == 12'h085);
          assert (accumulator == 32'h0000_0086);
          assert (auxiliary_register_0 == 16'h0005);
          assert (auxiliary_register_1 == 16'h0008);
          assert (!auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h085);
          assert (execute_word == 16'h7f89);
          assert (program_address == 12'h086);
          assert (!(data_read || data_write));
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h012);
          assert (write_seen);
        end
        32'd16: begin
          assert (pc == 12'h086);
          assert (accumulator == 32'h0000_0000);
          assert (auxiliary_register_0 == 16'h0005);
          assert (auxiliary_register_1 == 16'h0008);
          assert (!auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h086);
          assert (execute_word == 16'h7e44);
          assert (program_address == 12'h087);
          assert (!(data_read || data_write));
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h012);
          assert (write_seen);
        end
        32'd17: begin
          assert (pc == 12'h087);
          assert (accumulator == 32'h0000_0044);
          assert (auxiliary_register_0 == 16'h0005);
          assert (auxiliary_register_1 == 16'h0008);
          assert (!auxiliary_register_pointer);
          assert (execute_valid);
          assert (execute_address == 12'h087);
          assert (execute_word == 16'h7f80);
          assert (program_address == 12'h088);
          assert (!(data_read || data_write));
          assert (stack_top == 12'h052);
          assert (stack_level_1 == 12'h032);
          assert (stack_level_2 == 12'h012);
          assert (stack_bottom == 12'h012);
          assert (write_seen);
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
        mutable_program_word,
        write_seen,
        write_count
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
        mutable_program_word,
        write_seen,
        write_count
      }));
    end

    cover (
      initialized &&
      (cycle_count == 32'd17) &&
      (pc == 12'h087) &&
      (accumulator == 32'h0000_0044) &&
      (mutable_program_word == 16'h7e44) &&
      (auxiliary_register_0 == 16'h0005) &&
      (auxiliary_register_1 == 16'h0008) &&
      !auxiliary_register_pointer &&
      ({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
        {12'h052, 12'h032, 12'h012, 12'h012}) &&
      write_seen &&
      (write_count == 2'd1)
    );
  end
endmodule

`default_nettype wire
