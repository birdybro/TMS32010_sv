`default_nettype none

// FORMAL-001 bounded harness for the explicit TBLR fetch/execute pipeline.
//
// A fixed primary-backed sequence sets ACC to program address 4, executes
// direct TBLR 0, repeats the discarded following fetch, and consumes the
// committed RAM word with LAC 0. The external clock enable remains arbitrary.
// See formal/README.md for the exact bound and excluded claims.
module tms32010_pipeline_table_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  logic        initialized = 1'b0;
  logic        past_valid = 1'b0;
  logic        initialize;
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
      12'h000: program_data = 16'h7e04;  // LACK 4
      12'h001: program_data = 16'h6700;  // TBLR 0
      12'h002: program_data = 16'h2000;  // LAC 0, repeated after discard
      12'h003: program_data = 16'h7f80;  // NOP
      12'h004: program_data = 16'h1234;  // table source word
      default: program_data = 16'h7f80;
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
    .instruction_valid_o           (),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
  );

  always_ff @(posedge clk_i) begin
    initialized <= 1'b1;
    past_valid <= 1'b1;

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

      if (bus_active) begin
        assert (men_n == (phase == 2'd0));
      end else begin
        assert (men_n);
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
        32'd1: begin
          assert (pc == 12'h001);
          assert (accumulator == 32'h0000_0004);
          assert (execute_valid);
          assert (execute_address == 12'h001);
          assert (execute_word == 16'h6700);
          assert (program_address == 12'h002);
          assert (!data_read);
          assert (!data_write);
        end
        32'd2: begin
          assert (pc == 12'h002);
          assert (accumulator == 32'h0000_0004);
          assert (execute_valid);
          assert (execute_address == 12'h001);
          assert (execute_word == 16'h6700);
          assert (program_address == 12'h004);
          assert (!data_read);
          assert (data_write);
          assert (data_address_valid);
          assert (data_address == 8'h00);
          assert (data_write_address_valid);
          assert (data_write_address == 8'h00);
          assert (data_write_data == 16'h1234);
        end
        32'd3: begin
          assert (pc == 12'h002);
          assert (accumulator == 32'h0000_0004);
          assert (execute_valid);
          assert (execute_address == 12'h001);
          assert (execute_word == 16'h6700);
          assert (program_address == 12'h002);
          assert (!data_read);
          assert (!data_write);
        end
        32'd4: begin
          assert (pc == 12'h002);
          assert (accumulator == 32'h0000_0004);
          assert (execute_valid);
          assert (execute_address == 12'h002);
          assert (execute_word == 16'h2000);
          assert (program_address == 12'h003);
          assert (!data_write);
          assert (data_read_data == 16'h1234);
        end
        32'd5: begin
          assert (pc == 12'h003);
          assert (accumulator == 32'h0000_1234);
          assert (execute_valid);
          assert (execute_address == 12'h003);
          assert (execute_word == 16'h7f80);
          assert (program_address == 12'h004);
          assert (!data_read);
          assert (!data_write);
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
        stack_top,
        stack_level_1,
        stack_level_2,
        stack_bottom,
        interrupt_mask,
        interrupt_pending,
        illegal,
        cycle_count
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
        stack_top,
        stack_level_1,
        stack_level_2,
        stack_bottom,
        interrupt_mask,
        interrupt_pending,
        illegal,
        cycle_count
      }));
    end

    cover (
      initialized &&
      (cycle_count == 32'd5) &&
      (pc == 12'h003) &&
      (accumulator == 32'h0000_1234) &&
      (data_read_data == 16'h1234)
    );
  end
endmodule

`default_nettype wire
