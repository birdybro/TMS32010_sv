`default_nettype none

// FORMAL-001 bounded actual-core harness for request arrival during any of
// the three represented cycles of one fixed direct TBLW instruction.
//
// The mutable program word implements a synchronous verification memory
// contract at an enabled logical program-write boundary. It does not model
// original-package subphases or electrical write timing.
module tms32010_interrupt_table_write_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  (* anyconst *) logic [1:0] arrival_interval;

  logic [1:0]  initialize_count = 2'd0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic        initialized;
  logic        int_n;
  logic [15:0] mutable_program_word = 16'h7f82;
  logic        write_seen = 1'b0;
  logic [1:0]  write_count = 2'd0;
  logic [15:0] program_data;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic        program_read;
  logic        program_write;
  logic [15:0] program_write_data;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [15:0] data_read_data;
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
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;

  assign initialize = initialize_count != 2'd2;
  assign initialized = !initialize;

  always_comb begin
    assume (arrival_interval <= 2'd2);
  end

  // EINT retires request-free at cycle count 1. The symbolic value selects
  // the enabled boundary after the opcode, discarded fetch, or table write.
  assign int_n =
    !(
      initialized &&
      (
        ((arrival_interval == 2'd0) && (cycle_count == 32'd1)) ||
        ((arrival_interval == 2'd1) && (cycle_count == 32'd2)) ||
        ((arrival_interval == 2'd2) && (cycle_count == 32'd3))
      )
    );

  always_comb begin
    case (program_address)
      12'h000: program_data = mutable_program_word;
      12'h001: program_data = 16'h7d00;  // direct TBLW data address 0
      12'h002: program_data = 16'h7e55;  // protected/vector LACK 0x55
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
    .program_write_data_o          (program_write_data),
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
    .debug_data_write_i            (initialize),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h7e44),
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
      mutable_program_word <= 16'h7f82;
      write_seen <= 1'b0;
      write_count <= 2'd0;
    end else if (clock_enable_i && program_write) begin
      assert (program_address == 12'h000);
      assert (program_write_data == 16'h7e44);
      mutable_program_word <= program_write_data;
      write_seen <= 1'b1;
      write_count <= write_count + 2'd1;
    end

    if (initialized) begin
      assert (!illegal);
      assert (program_read == !program_write);
      assert (data_read == program_write);
      assert (!data_write);
      assert (!(io_read || io_write));
      assert (program_write == (cycle_count == 32'd3));
      assert (write_count <= 2'd1);

      if (write_seen) begin
        assert (mutable_program_word == 16'h7e44);
        assert (write_count == 2'd1);
      end else begin
        assert (mutable_program_word == 16'h7f82);
        assert (write_count == 2'd0);
      end

      case (cycle_count)
        32'd0: begin
          assert (pc == 12'h000);
          assert (accumulator == 32'h0000_0000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_address == 12'h000);
          assert (program_next_address == 12'h001);
        end
        32'd1: begin
          assert (pc == 12'h001);
          assert (!interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_address == 12'h001);
          assert (program_next_address == 12'h002);
        end
        32'd2: begin
          // Opcode completion enters the table sequence without retirement.
          assert (pc == 12'h002);
          assert (!interrupt_mask);
          assert (interrupt_pending == (arrival_interval == 2'd0));
          assert (instruction_valid);
          assert (!retired);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h002);
          assert (!write_seen);
          assert (stack_top == 12'h000);
        end
        32'd3: begin
          // The transfer reads RAM 0 and writes its word to program address 0.
          assert (pc == 12'h002);
          assert (!interrupt_mask);
          assert (interrupt_pending == (arrival_interval <= 2'd1));
          assert (instruction_valid);
          assert (!retired);
          assert (program_address == 12'h000);
          assert (program_next_address == 12'h002);
          assert (program_write_data == 16'h7e44);
          assert (data_address_valid);
          assert (data_address == 8'h00);
          assert (data_read_data == 16'h7e44);
          assert (!write_seen);
          assert (stack_top == 12'h000);
        end
        32'd4: begin
          // TBLW and the enabled external write complete before deferral.
          assert (pc == 12'h002);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h003);
          assert (write_seen);
          assert (mutable_program_word == 16'h7e44);
          assert (stack_top == 12'h000);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
        end
        32'd5: begin
          assert (pc == 12'h003);
          assert (accumulator == 32'h0000_0055);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (!instruction_valid);
          assert (program_address == 12'h003);
          assert (program_next_address == 12'h002);
          assert (write_seen);
          assert (stack_top == 12'h000);
        end
        32'd6: begin
          assert (pc == 12'h002);
          assert (accumulator == 32'h0000_0055);
          assert (stack_top == 12'h003);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h003);
          assert (write_seen);
          assert (write_count == 2'd1);
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
        mutable_program_word,
        write_seen,
        write_count
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
        mutable_program_word,
        write_seen,
        write_count
      }));
      assert ({
        program_address,
        program_next_address,
        program_read,
        program_write,
        program_write_data,
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
        program_write_data,
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
      (arrival_interval == 2'd0) &&
      (cycle_count == 32'd6) &&
      (pc == 12'h002) &&
      (accumulator == 32'h0000_0055) &&
      (stack_top == 12'h003) &&
      (mutable_program_word == 16'h7e44) &&
      (write_count == 2'd1) &&
      interrupt_mask &&
      !interrupt_pending
    );

    cover (
      initialized &&
      (arrival_interval == 2'd1) &&
      (cycle_count == 32'd6) &&
      (pc == 12'h002) &&
      (accumulator == 32'h0000_0055) &&
      (stack_top == 12'h003) &&
      (mutable_program_word == 16'h7e44) &&
      (write_count == 2'd1) &&
      interrupt_mask &&
      !interrupt_pending
    );

    cover (
      initialized &&
      (arrival_interval == 2'd2) &&
      (cycle_count == 32'd6) &&
      (pc == 12'h002) &&
      (accumulator == 32'h0000_0055) &&
      (stack_top == 12'h003) &&
      (mutable_program_word == 16'h7e44) &&
      (write_count == 2'd1) &&
      interrupt_mask &&
      !interrupt_pending
    );
  end
endmodule

`default_nettype wire
