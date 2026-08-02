`default_nettype none

// FORMAL-001 bounded actual-core harness for interrupt arrival during every
// represented interval of the six accumulator-conditional branch families.
//
// The symbolic fixture crosses each predicate with negative, zero, and
// positive ACC values. This proves logical core sequencing only; it does not
// establish original-package pin ownership for the inferred branch intervals.
module tms32010_interrupt_accumulator_branches_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  (* anyconst *) logic [2:0] branch_family;
  (* anyconst *) logic [1:0] accumulator_class;
  (* anyconst *) logic       arrival_second;

  logic [1:0]  initialize_count = 2'd0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic        initialized;
  logic        int_n;
  logic [15:0] preload_data;
  logic [15:0] branch_opcode;
  logic [31:0] expected_initial_accumulator;
  logic        expected_branch_taken;
  logic [11:0] expected_protected_pc;
  logic [11:0] expected_return_pc;
  logic [15:0] program_data;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic        program_read;
  logic        program_write;
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
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;

  assign initialize = initialize_count != 2'd2;
  assign initialized = !initialize;

  always_comb begin
    assume (branch_family <= 3'd5);
    assume (accumulator_class <= 2'd2);
  end

  // The branch-family values follow opcode order FA through FF. Keeping this
  // table explicit makes the formal fixture independently auditable.
  always_comb begin
    case (branch_family)
      3'd0: branch_opcode = 16'hfa00;  // BLZ
      3'd1: branch_opcode = 16'hfb00;  // BLEZ
      3'd2: branch_opcode = 16'hfc00;  // BGZ
      3'd3: branch_opcode = 16'hfd00;  // BGEZ
      3'd4: branch_opcode = 16'hfe00;  // BNZ
      3'd5: branch_opcode = 16'hff00;  // BZ
      default: branch_opcode = 16'h0000;
    endcase
  end

  always_comb begin
    case (accumulator_class)
      2'd0: begin
        preload_data = 16'hffff;
        expected_initial_accumulator = 32'hffff_ffff;
      end
      2'd1: begin
        preload_data = 16'h0000;
        expected_initial_accumulator = 32'h0000_0000;
      end
      2'd2: begin
        preload_data = 16'h0001;
        expected_initial_accumulator = 32'h0000_0001;
      end
      default: begin
        preload_data = 16'h0000;
        expected_initial_accumulator = 32'h0000_0000;
      end
    endcase
  end

  // Independent truth table for the documented signed/zero predicates.
  always_comb begin
    case (branch_family)
      3'd0: expected_branch_taken = accumulator_class == 2'd0;  // BLZ
      3'd1: expected_branch_taken = accumulator_class != 2'd2;  // BLEZ
      3'd2: expected_branch_taken = accumulator_class == 2'd2;  // BGZ
      3'd3: expected_branch_taken = accumulator_class != 2'd0;  // BGEZ
      3'd4: expected_branch_taken = accumulator_class != 2'd1;  // BNZ
      3'd5: expected_branch_taken = accumulator_class == 2'd1;  // BZ
      default: expected_branch_taken = 1'b0;
    endcase
  end

  assign expected_protected_pc =
    expected_branch_taken ? 12'h010 : 12'h004;
  assign expected_return_pc = expected_protected_pc + 12'h001;

  // EINT retires request-free at cycle count 2. The symbolic value selects
  // the branch-opcode interval or the canonical-operand interval.
  assign int_n =
    !(
      initialized &&
      (
        ((!arrival_second) && (cycle_count == 32'd2)) ||
        (arrival_second && (cycle_count == 32'd3))
      )
    );

  always_comb begin
    case (program_address)
      12'h000: program_data = 16'h2000;  // direct LAC 0 sets ACC class
      12'h001: program_data = 16'h7f82;  // EINT
      12'h002: program_data = branch_opcode;
      12'h003: program_data = 16'h0010;  // canonical target operand
      12'h004: program_data = 16'h7e44;  // untaken protected LACK 0x44
      12'h005: program_data = 16'h7f89;  // untaken dummy-fetched ZAC
      12'h010: program_data = 16'h7e44;  // taken protected LACK 0x44
      12'h011: program_data = 16'h7f89;  // taken dummy-fetched ZAC
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
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (data_write_address),
    .data_write_address_valid_o    (data_write_address_valid),
    .data_read_data_o              (data_read_data),
    .data_write_data_o             (data_write_data),
    .debug_data_write_i            (initialize),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (preload_data),
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

    if (initialized) begin
      assert (!illegal);
      assert (program_read);
      assert (!program_write);
      assert (!(io_read || io_write || data_write));
      assert (data_read == (cycle_count == 32'd0));

      case (cycle_count)
        32'd0: begin
          assert (pc == 12'h000);
          assert (accumulator == 32'h0000_0000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_address == 12'h000);
          assert (program_next_address == 12'h001);
          assert (data_address_valid);
          assert (data_address == 8'h00);
          assert (data_read_data == preload_data);
        end
        32'd1: begin
          assert (pc == 12'h001);
          assert (accumulator == expected_initial_accumulator);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_address == 12'h001);
          assert (program_next_address == 12'h002);
        end
        32'd2: begin
          assert (pc == 12'h002);
          assert (accumulator == expected_initial_accumulator);
          assert (!interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h003);
          assert (stack_top == 12'h000);
        end
        32'd3: begin
          // Branch ownership retains the canonical operand and cannot enter.
          assert (pc == 12'h003);
          assert (accumulator == expected_initial_accumulator);
          assert (!interrupt_mask);
          assert (interrupt_pending == !arrival_second);
          assert (instruction_valid);
          assert (!retired);
          assert (program_address == 12'h003);
          assert (program_next_address == expected_protected_pc);
          assert (stack_top == 12'h000);
        end
        32'd4: begin
          // Both branch outcomes resolve before interrupt deferral begins.
          assert (pc == expected_protected_pc);
          assert (accumulator == expected_initial_accumulator);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
          assert (program_address == expected_protected_pc);
          assert (program_next_address == expected_return_pc);
          assert (stack_top == 12'h000);
        end
        32'd5: begin
          assert (pc == expected_return_pc);
          assert (accumulator == 32'h0000_0044);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (!instruction_valid);
          assert (program_address == expected_return_pc);
          assert (program_next_address == 12'h002);
          assert (stack_top == 12'h000);
        end
        32'd6: begin
          assert (pc == 12'h002);
          assert (accumulator == 32'h0000_0044);
          assert (stack_top == expected_return_pc);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h003);
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
        cycle_count
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
        data_write_address,
        data_write_address_valid,
        data_read_data,
        data_write_data,
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
        data_write_address,
        data_write_address_valid,
        data_read_data,
        data_write_data,
        io_read,
        io_write,
        instruction_valid
      }));
    end
  end

  // One cover per family/class/arrival tuple makes every cross-product cell,
  // rather than only each selector value in isolation, independently reachable.
  generate
    for (
      genvar family_index = 0;
      family_index < 6;
      family_index = family_index + 1
    ) begin : cover_family
      for (
        genvar accumulator_index = 0;
        accumulator_index < 3;
        accumulator_index = accumulator_index + 1
      ) begin : cover_accumulator
        for (
          genvar arrival_index = 0;
          arrival_index < 2;
          arrival_index = arrival_index + 1
        ) begin : cover_arrival
          localparam logic [2:0] FAMILY_VALUE = family_index;
          localparam logic [1:0] ACCUMULATOR_VALUE = accumulator_index;
          localparam logic ARRIVAL_VALUE = arrival_index;

          always_ff @(posedge clk_i) begin
            cover (
              initialized &&
              (branch_family == FAMILY_VALUE) &&
              (accumulator_class == ACCUMULATOR_VALUE) &&
              (arrival_second == ARRIVAL_VALUE) &&
              (cycle_count == 32'd6) &&
              (pc == 12'h002) &&
              (accumulator == 32'h0000_0044) &&
              (stack_top == expected_return_pc) &&
              interrupt_mask &&
              !interrupt_pending
            );
          end
        end
      end
    end
  endgenerate
endmodule

`default_nettype wire
