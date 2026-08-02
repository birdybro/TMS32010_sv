`default_nettype none

// FORMAL-001 bounded native-phase TBLW/interrupt-composition harness.
//
// A branch keeps vector location 2 distinct from the table-writing program.
// Independent symbolic selectors assert and hold INT low beginning in any of
// the four represented native phases of any of TBLW's three machine cycles.
// This models logical falling-boundary ownership, not analog setup/hold or the
// physical synchronizer and edge-latch behavior.
module tms32010_pipeline_table_write_interrupt_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  (* anyconst *) logic [1:0] arrival_interval;
  (* anyconst *) logic [1:0] arrival_phase;
  (* anyconst *) logic [5:0] pause_step;

  logic [1:0]  initialize_count = 2'd0;
  logic [5:0]  formal_step = 6'd0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic        initialized;
  logic        int_n;
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
  logic        instruction_valid;
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
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        interrupt_mask;
  logic        interrupt_pending;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic        selected_request_interval;
  logic        completed;

  assign initialize = initialize_count != 2'd2;
  assign initialized = !initialize;

  always_comb begin
    assume (arrival_interval <= 2'd2);
    assume (pause_step >= 6'd10);
    assume (pause_step <= 6'd54);
    assume (clock_enable_i == (formal_step != pause_step));
  end

  // cycle_count 4, 5, and 6 are respectively the discarded-PC+1, WE, and
  // repeated-PC+1 intervals of the fixed TBLW. Once selected, the request is
  // held through that interval's enabled falling-CLKOUT sampling boundary.
  assign selected_request_interval =
    ((arrival_interval == 2'd0) && (cycle_count == 32'd4)) ||
    ((arrival_interval == 2'd1) && (cycle_count == 32'd5)) ||
    ((arrival_interval == 2'd2) && (cycle_count == 32'd6));
  assign int_n = !(
    initialized &&
    selected_request_interval &&
    (phase >= arrival_phase)
  );

  always_comb begin
    case (program_address)
      12'h000: program_data = 16'hf900;  // B 0x010
      12'h001: program_data = 16'h0010;
      12'h002: program_data = 16'h7e55;  // vector LACK 0x55
      12'h003: program_data = 16'h7f80;  // vector successor NOP
      12'h010: program_data = 16'h7f82;  // EINT
      12'h011: program_data = 16'h7e17;  // LACK table target 0x017
      12'h012: program_data = 16'h7d00;  // direct TBLW data address 0
      12'h013: program_data = 16'h7e66;  // protected LACK 0x66
      12'h014: program_data = 16'h7f89;  // discarded dummy-fetched ZAC
      12'h017: program_data = mutable_program_word;
      default: program_data = 16'h7f80;
    endcase
  end

  assign completed =
    initialized &&
    (cycle_count == 32'd10) &&
    (pc == 12'h003) &&
    (accumulator == 32'h0000_0055) &&
    (stack_top == 12'h014) &&
    (stack_level_1 == 12'h000) &&
    (stack_level_2 == 12'h000) &&
    (stack_bottom == 12'h000) &&
    interrupt_mask &&
    !interrupt_pending &&
    (mutable_program_word == 16'h7e44) &&
    write_seen &&
    (write_count == 2'd1);

  tms32010_sequential_pipeline_slice dut (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize),
    .rs_i                          (1'b0),
    .clock_enable_i                (clock_enable_i),
    .bio_i                         (1'b1),
    .int_i                         (int_n),
    .program_data_i                (program_data),
    .io_read_data_i                (16'h0000),
    .debug_data_write_i            (initialize),
    .debug_data_address_i          (8'h00),
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
    formal_step <= formal_step + 6'd1;
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
      assert (cycle_count == 32'd5);
      assert (program_address == 12'h017);
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
      assert (write_count <= 2'd1);
      assert (!(
        (!men_n && !we_n) ||
        (!men_n && !den_n) ||
        (!den_n && !we_n)
      ));

      if (program_write) begin
        assert (bus_active);
        assert (cycle_count == 32'd5);
        assert (execute_valid);
        assert (execute_address == 12'h012);
        assert (execute_word == 16'h7d00);
        assert (program_address == 12'h017);
        assert (program_write_data == 16'h7e44);
        assert (data_read);
        assert (data_address_valid);
        assert (data_address == 8'h00);
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

      if (data_read && execute_valid) begin
        assert (cycle_count == 32'd5);
        assert (program_write);
        assert (data_address_valid);
        assert (data_address == 8'h00);
        assert (data_read_data == 16'h7e44);
      end

      if (write_seen) begin
        assert (mutable_program_word == 16'h7e44);
        assert (write_count == 2'd1);
      end else begin
        assert (mutable_program_word == 16'h7f80);
        assert (write_count == 2'd0);
      end

      // The symbolic request is high outside its selected table interval,
      // then remains low from the selected phase through the sample boundary.
      if (
        selected_request_interval &&
        (phase >= arrival_phase)
      ) begin
        assert (!int_n);
      end else begin
        assert (int_n);
      end

      case (cycle_count)
        32'd0: begin
          assert (pc == 12'h000);
          assert (accumulator == 32'h0000_0000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (stack_top == 12'h000);
          if (execute_valid) begin
            assert (execute_address == 12'h000);
            assert (execute_word == 16'hf900);
            assert (program_address == 12'h001);
          end else begin
            // Before the first fetch primes the execute slot, the program bus
            // completes its documented release synchronization at address 0.
            assert (program_address == 12'h000);
          end
        end
        32'd1: begin
          assert (pc == 12'h001);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (execute_valid);
          assert (execute_address == 12'h000);
          assert (execute_word == 16'hf900);
          assert (program_address == 12'h010);
          assert (stack_top == 12'h000);
        end
        32'd2: begin
          assert (pc == 12'h010);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (execute_valid);
          assert (execute_address == 12'h010);
          assert (execute_word == 16'h7f82);
          assert (program_address == 12'h011);
          assert (stack_top == 12'h000);
        end
        32'd3: begin
          assert (pc == 12'h011);
          assert (!interrupt_mask);
          assert (!interrupt_pending);
          assert (execute_valid);
          assert (execute_address == 12'h011);
          assert (execute_word == 16'h7e17);
          assert (program_address == 12'h012);
          assert (stack_top == 12'h000);
        end
        32'd4: begin
          assert (pc == 12'h012);
          assert (accumulator == 32'h0000_0017);
          assert (!interrupt_mask);
          assert (!interrupt_pending);
          assert (execute_valid);
          assert (instruction_valid);
          assert (execute_address == 12'h012);
          assert (execute_word == 16'h7d00);
          assert (program_address == 12'h013);
          assert (!program_write);
          assert (!data_read);
          assert (stack_top == 12'h000);
          assert (!write_seen);
        end
        32'd5: begin
          assert (pc == 12'h013);
          assert (accumulator == 32'h0000_0017);
          assert (!interrupt_mask);
          assert (interrupt_pending == (arrival_interval == 2'd0));
          assert (execute_valid);
          assert (instruction_valid);
          assert (execute_address == 12'h012);
          assert (execute_word == 16'h7d00);
          assert (program_address == 12'h017);
          assert (program_write);
          assert (data_read && !data_write);
          assert (data_address_valid);
          assert (data_address == 8'h00);
          assert (data_read_data == 16'h7e44);
          assert (stack_top == 12'h000);
          assert (!write_seen);
        end
        32'd6: begin
          assert (pc == 12'h013);
          assert (accumulator == 32'h0000_0017);
          assert (!interrupt_mask);
          assert (interrupt_pending == (arrival_interval <= 2'd1));
          assert (execute_valid);
          assert (instruction_valid);
          assert (execute_address == 12'h012);
          assert (execute_word == 16'h7d00);
          assert (program_address == 12'h013);
          assert (!program_write);
          assert (!data_read);
          assert (stack_top == 12'h000);
          assert (write_seen);
        end
        32'd7: begin
          assert (pc == 12'h013);
          assert (accumulator == 32'h0000_0017);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (execute_valid);
          assert (instruction_valid);
          assert (execute_address == 12'h013);
          assert (execute_word == 16'h7e66);
          assert (program_address == 12'h014);
          assert (!program_write);
          assert (!data_read);
          assert (stack_top == 12'h000);
          assert (write_seen);
        end
        32'd8: begin
          assert (pc == 12'h014);
          assert (accumulator == 32'h0000_0066);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (!execute_valid);
          assert (!instruction_valid);
          assert (program_address == 12'h002);
          assert (stack_top == 12'h000);
          assert (write_seen);
        end
        32'd9: begin
          assert (pc == 12'h002);
          assert (accumulator == 32'h0000_0066);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (execute_valid);
          assert (instruction_valid);
          assert (execute_address == 12'h002);
          assert (execute_word == 16'h7e55);
          assert (program_address == 12'h003);
          assert (stack_top == 12'h014);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
          assert (write_seen);
        end
        32'd10: begin
          assert (pc == 12'h003);
          assert (accumulator == 32'h0000_0055);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (execute_valid);
          assert (instruction_valid);
          assert (execute_address == 12'h003);
          assert (execute_word == 16'h7f80);
          assert (program_address == 12'h004);
          assert (stack_top == 12'h014);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
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
        instruction_valid,
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
        write_count,
        int_n
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
        instruction_valid,
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
        write_count,
        int_n
      }));
    end

    cover (completed && (arrival_interval == 2'd0) && (arrival_phase == 2'd0));
    cover (completed && (arrival_interval == 2'd0) && (arrival_phase == 2'd1));
    cover (completed && (arrival_interval == 2'd0) && (arrival_phase == 2'd2));
    cover (completed && (arrival_interval == 2'd0) && (arrival_phase == 2'd3));
    cover (completed && (arrival_interval == 2'd1) && (arrival_phase == 2'd0));
    cover (completed && (arrival_interval == 2'd1) && (arrival_phase == 2'd1));
    cover (completed && (arrival_interval == 2'd1) && (arrival_phase == 2'd2));
    cover (completed && (arrival_interval == 2'd1) && (arrival_phase == 2'd3));
    cover (completed && (arrival_interval == 2'd2) && (arrival_phase == 2'd0));
    cover (completed && (arrival_interval == 2'd2) && (arrival_phase == 2'd1));
    cover (completed && (arrival_interval == 2'd2) && (arrival_phase == 2'd2));
    cover (completed && (arrival_interval == 2'd2) && (arrival_phase == 2'd3));
  end
endmodule

`default_nettype wire
