`default_nettype none

// FORMAL-001 bounded actual-core harness for both request-arrival intervals
// of fixed direct IN and OUT instructions.
//
// The callback data and verification-only RAM preload are fixed formal
// fixtures. This proves logical transactions, not peripheral side effects or
// electrical I/O timing.
module tms32010_interrupt_io_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  (* anyconst *) logic select_out;
  (* anyconst *) logic arrival_second;

  logic [1:0]  initialize_count = 2'd0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic        initialized;
  logic        int_n;
  logic        transfer_seen = 1'b0;
  logic [1:0]  transfer_count = 2'd0;
  logic [15:0] program_data;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic        program_read;
  logic        program_write;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic [15:0] io_write_data;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [7:0]  data_write_address;
  logic        data_write_address_valid;
  logic [15:0] data_read_data;
  logic [15:0] data_write_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
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

  assign initialize = initialize_count != 2'd2;
  assign initialized = !initialize;

  // EINT retires request-free at cycle count 1. The symbolic value selects
  // the opcode or external-transfer retirement boundary.
  assign int_n =
    !(
      initialized &&
      (
        ((!arrival_second) && (cycle_count == 32'd1)) ||
        (arrival_second && (cycle_count == 32'd2))
      )
    );

  always_comb begin
    case (program_address)
      12'h000: program_data = 16'h7f82;  // EINT
      12'h001: program_data = select_out ? 16'h4f03 : 16'h4203;
      12'h002: program_data = 16'h2003;  // protected/vector direct LAC 3
      12'h003: program_data = 16'h7f89;  // nonretiring dummy-fetched ZAC
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
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (io_write_data),
    .io_read_data_i                (16'hcafe),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (data_write_address),
    .data_write_address_valid_o    (data_write_address_valid),
    .data_read_data_o              (data_read_data),
    .data_write_data_o             (data_write_data),
    .debug_data_write_i            (initialize),
    .debug_data_address_i          (8'h03),
    .debug_data_i                  (16'h1234),
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
    if (initialize_count != 2'd2) begin
      initialize_count <= initialize_count + 2'd1;
    end
    past_valid <= 1'b1;

    if (initialize) begin
      transfer_seen <= 1'b0;
      transfer_count <= 2'd0;
    end else if (clock_enable_i && (io_read || io_write)) begin
      transfer_seen <= 1'b1;
      transfer_count <= transfer_count + 2'd1;
    end

    if (initialized) begin
      assert (!illegal);
      assert (!program_write);
      assert (!(io_read && io_write));
      assert (transfer_count <= 2'd1);

      if (transfer_seen) begin
        assert (transfer_count == 2'd1);
      end else begin
        assert (transfer_count == 2'd0);
      end

      case (cycle_count)
        32'd0: begin
          assert (pc == 12'h000);
          assert (accumulator == 32'h0000_0000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h000);
          assert (program_next_address == 12'h001);
          assert (!(io_read || io_write || data_read || data_write));
        end
        32'd1: begin
          assert (pc == 12'h001);
          assert (!interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h001);
          assert (program_next_address == 12'h002);
          assert (!(io_read || io_write || data_read || data_write));
          assert (!transfer_seen);
        end
        32'd2: begin
          // The external transfer owns the second and retiring I/O interval.
          assert (pc == 12'h002);
          assert (!interrupt_mask);
          assert (interrupt_pending == !arrival_second);
          assert (instruction_valid);
          assert (!program_read);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h002);
          assert (data_address_valid);
          assert (data_address == 8'h03);
          assert (!transfer_seen);
          assert (!retired);
          if (select_out) begin
            assert (!io_read);
            assert (io_write);
            assert (io_port == 3'd7);
            assert (io_write_data == 16'h1234);
            assert (data_read);
            assert (!data_write);
            assert (data_read_data == 16'h1234);
          end else begin
            assert (io_read);
            assert (!io_write);
            assert (io_port == 3'd2);
            assert (!data_read);
            assert (data_write);
            assert (data_write_address_valid);
            assert (data_write_address == 8'h03);
            assert (data_write_data == 16'hcafe);
          end
          assert (stack_top == 12'h000);
        end
        32'd3: begin
          // I/O completion precedes deferral; LAC observes the final RAM word.
          assert (pc == 12'h002);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h003);
          assert (!(io_read || io_write));
          assert (data_read);
          assert (!data_write);
          assert (data_address_valid);
          assert (data_address == 8'h03);
          assert (data_read_data == (select_out ? 16'h1234 : 16'hcafe));
          assert (transfer_seen);
          assert (transfer_count == 2'd1);
          assert (stack_top == 12'h000);
        end
        32'd4: begin
          assert (pc == 12'h003);
          assert (
            accumulator ==
            (select_out ? 32'h0000_1234 : 32'hffff_cafe)
          );
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (!instruction_valid);
          assert (program_read);
          assert (program_address == 12'h003);
          assert (program_next_address == 12'h002);
          assert (!(io_read || io_write || data_read || data_write));
          assert (stack_top == 12'h000);
        end
        32'd5: begin
          assert (pc == 12'h002);
          assert (
            accumulator ==
            (select_out ? 32'h0000_1234 : 32'hffff_cafe)
          );
          assert (stack_top == 12'h003);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h003);
          assert (!(io_read || io_write));
          assert (data_read);
          assert (!data_write);
          assert (data_read_data == (select_out ? 16'h1234 : 16'hcafe));
          assert (transfer_seen);
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
        transfer_seen,
        transfer_count
      } == $past({
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
        transfer_seen,
        transfer_count
      }));
      assert ({
        program_address,
        program_next_address,
        program_read,
        program_write,
        io_port,
        io_read,
        io_write,
        io_write_data,
        data_address,
        data_read,
        data_write,
        data_address_valid,
        data_write_address,
        data_write_address_valid,
        data_read_data,
        data_write_data,
        instruction_valid
      } == $past({
        program_address,
        program_next_address,
        program_read,
        program_write,
        io_port,
        io_read,
        io_write,
        io_write_data,
        data_address,
        data_read,
        data_write,
        data_address_valid,
        data_write_address,
        data_write_address_valid,
        data_read_data,
        data_write_data,
        instruction_valid
      }));
    end

    cover (
      initialized &&
      !select_out &&
      !arrival_second &&
      (cycle_count == 32'd5) &&
      (accumulator == 32'hffff_cafe) &&
      (stack_top == 12'h003) &&
      (transfer_count == 2'd1) &&
      interrupt_mask &&
      !interrupt_pending
    );

    cover (
      initialized &&
      !select_out &&
      arrival_second &&
      (cycle_count == 32'd5) &&
      (accumulator == 32'hffff_cafe) &&
      (stack_top == 12'h003) &&
      (transfer_count == 2'd1) &&
      interrupt_mask &&
      !interrupt_pending
    );

    cover (
      initialized &&
      select_out &&
      !arrival_second &&
      (cycle_count == 32'd5) &&
      (accumulator == 32'h0000_1234) &&
      (stack_top == 12'h003) &&
      (transfer_count == 2'd1) &&
      interrupt_mask &&
      !interrupt_pending
    );

    cover (
      initialized &&
      select_out &&
      arrival_second &&
      (cycle_count == 32'd5) &&
      (accumulator == 32'h0000_1234) &&
      (stack_top == 12'h003) &&
      (transfer_count == 2'd1) &&
      interrupt_mask &&
      !interrupt_pending
    );
  end
endmodule

`default_nettype wire
