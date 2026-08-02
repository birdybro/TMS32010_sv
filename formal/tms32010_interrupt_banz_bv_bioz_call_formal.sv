`default_nettype none

// FORMAL-001 bounded actual-core harness for interrupt arrival during every
// represented interval of BANZ, BV, BIOZ, and CALL.
//
// Seven scenarios cover both predicates for each conditional family and the
// unconditional CALL path. This proves logical core sequencing only; it does
// not establish original-package pin ownership for the inferred intervals.
module tms32010_interrupt_banz_bv_bioz_call_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  (* anyconst *) logic [2:0] control_scenario;
  (* anyconst *) logic       arrival_second;

  logic [1:0]  initialize_count = 2'd0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic        initialized;
  logic        int_n;
  logic        bio;
  logic [15:0] preload_data;
  logic [15:0] setup_opcode;
  logic [15:0] control_opcode;
  logic        setup_reads_data;
  logic        expected_taken;
  logic [31:0] expected_setup_accumulator;
  logic [15:0] expected_setup_ar0;
  logic [15:0] expected_retired_ar0;
  logic        expected_setup_overflow;
  logic [11:0] expected_protected_pc;
  logic [11:0] expected_return_pc;
  logic [11:0] expected_call_stack_top;
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
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        overflow_flag;
  logic        overflow_mode;
  logic        interrupt_mask;
  logic        interrupt_pending;
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;

  assign initialize = initialize_count != 2'd2;
  assign initialized = !initialize;

  always_comb begin
    assume (control_scenario <= 3'd6);
  end

  // The scenarios are explicit and independent of the RTL's control helpers:
  // 0 BANZ zero, 1 BANZ one, 2 BV clear, 3 BV set,
  // 4 BIOZ high, 5 BIOZ low, and 6 CALL.
  always_comb begin
    preload_data               = 16'h0000;
    setup_opcode               = 16'h7ea5;  // LACK 0xa5
    control_opcode             = 16'hf800;  // CALL
    setup_reads_data           = 1'b0;
    expected_taken             = 1'b1;
    expected_setup_accumulator = 32'h0000_00a5;
    expected_setup_ar0         = 16'h0000;
    expected_retired_ar0       = 16'h0000;
    expected_setup_overflow    = 1'b0;
    bio                        = 1'b1;

    case (control_scenario)
      3'd0: begin
        preload_data               = 16'ha400;
        setup_opcode               = 16'h3800;  // direct LAR AR0,0
        control_opcode             = 16'hf400;  // BANZ
        setup_reads_data           = 1'b1;
        expected_taken             = 1'b0;
        expected_setup_accumulator = 32'h0000_0000;
        expected_setup_ar0         = 16'ha400;
        expected_retired_ar0       = 16'ha5ff;
      end
      3'd1: begin
        preload_data               = 16'hbe01;
        setup_opcode               = 16'h3800;  // direct LAR AR0,0
        control_opcode             = 16'hf400;  // BANZ
        setup_reads_data           = 1'b1;
        expected_setup_accumulator = 32'h0000_0000;
        expected_setup_ar0         = 16'hbe01;
        expected_retired_ar0       = 16'hbe00;
      end
      3'd2: begin
        setup_opcode               = 16'h7b00;  // direct LST 0
        control_opcode             = 16'hf500;  // BV
        setup_reads_data           = 1'b1;
        expected_taken             = 1'b0;
        expected_setup_accumulator = 32'h0000_0000;
      end
      3'd3: begin
        preload_data               = 16'h8000;
        setup_opcode               = 16'h7b00;  // direct LST 0
        control_opcode             = 16'hf500;  // BV
        setup_reads_data           = 1'b1;
        expected_setup_accumulator = 32'h0000_0000;
        expected_setup_overflow    = 1'b1;
      end
      3'd4: begin
        control_opcode = 16'hf600;  // BIOZ, inactive high
        expected_taken = 1'b0;
      end
      3'd5: begin
        control_opcode = 16'hf600;  // BIOZ, active low
        bio            = 1'b0;
      end
      3'd6: begin
        control_opcode = 16'hf800;  // CALL
      end
      default: begin
      end
    endcase
  end

  assign expected_protected_pc = expected_taken ? 12'h010 : 12'h004;
  assign expected_return_pc = expected_protected_pc + 12'h001;
  assign expected_call_stack_top =
    (control_scenario == 3'd6) ? 12'h004 : 12'h000;

  // EINT retires request-free at cycle count 2. The symbolic value selects
  // the control-opcode interval or the canonical-operand interval.
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
      12'h000: program_data = setup_opcode;
      12'h001: program_data = 16'h7f82;  // EINT
      12'h002: program_data = control_opcode;
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
    .bio_i                         (bio),
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
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
    .overflow_flag_o               (overflow_flag),
    .overflow_mode_o               (overflow_mode),
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
      assert (data_read == ((cycle_count == 32'd0) && setup_reads_data));

      if (data_read) begin
        assert (data_address_valid);
        assert (data_address == 8'h00);
        assert (data_read_data == preload_data);
      end

      case (cycle_count)
        32'd0: begin
          assert (pc == 12'h000);
          assert (accumulator == 32'h0000_0000);
          assert (auxiliary_register_0 == 16'h0000);
          assert (!overflow_flag);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_address == 12'h000);
          assert (program_next_address == 12'h001);
          assert (stack_top == 12'h000);
        end
        32'd1: begin
          assert (pc == 12'h001);
          assert (accumulator == expected_setup_accumulator);
          assert (auxiliary_register_0 == expected_setup_ar0);
          assert (auxiliary_register_1 == 16'h0000);
          assert (overflow_flag == expected_setup_overflow);
          assert (!overflow_mode);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_address == 12'h001);
          assert (program_next_address == 12'h002);
          assert (stack_top == 12'h000);
        end
        32'd2: begin
          assert (pc == 12'h002);
          assert (accumulator == expected_setup_accumulator);
          assert (auxiliary_register_0 == expected_setup_ar0);
          assert (overflow_flag == expected_setup_overflow);
          assert (!interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h003);
          assert (stack_top == 12'h000);
        end
        32'd3: begin
          assert (pc == 12'h003);
          assert (accumulator == expected_setup_accumulator);
          assert (auxiliary_register_0 == expected_setup_ar0);
          assert (overflow_flag == expected_setup_overflow);
          assert (!interrupt_mask);
          assert (interrupt_pending == !arrival_second);
          assert (instruction_valid);
          assert (!retired);
          assert (program_address == 12'h003);
          assert (program_next_address == expected_protected_pc);
          assert (stack_top == 12'h000);
        end
        32'd4: begin
          assert (pc == expected_protected_pc);
          assert (accumulator == expected_setup_accumulator);
          assert (auxiliary_register_0 == expected_retired_ar0);
          assert (!overflow_flag);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
          assert (program_address == expected_protected_pc);
          assert (program_next_address == expected_return_pc);
          assert (stack_top == expected_call_stack_top);
          assert (stack_level_1 == 12'h000);
        end
        32'd5: begin
          assert (pc == expected_return_pc);
          assert (accumulator == 32'h0000_0044);
          assert (auxiliary_register_0 == expected_retired_ar0);
          assert (!overflow_flag);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (!instruction_valid);
          assert (program_address == expected_return_pc);
          assert (program_next_address == 12'h002);
          assert (stack_top == expected_call_stack_top);
          assert (stack_level_1 == 12'h000);
        end
        32'd6: begin
          assert (pc == 12'h002);
          assert (accumulator == 32'h0000_0044);
          assert (auxiliary_register_0 == expected_retired_ar0);
          assert (!overflow_flag);
          assert (stack_top == expected_return_pc);
          assert (stack_level_1 == expected_call_stack_top);
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
        auxiliary_register_0,
        auxiliary_register_1,
        stack_top,
        stack_level_1,
        stack_level_2,
        stack_bottom,
        overflow_flag,
        overflow_mode,
        interrupt_mask,
        interrupt_pending,
        illegal,
        cycle_count
      } == $past({
        pc,
        accumulator,
        auxiliary_register_0,
        auxiliary_register_1,
        stack_top,
        stack_level_1,
        stack_level_2,
        stack_bottom,
        overflow_flag,
        overflow_mode,
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

  // One cover per scenario/arrival tuple makes the complete finite matrix,
  // rather than each selector value in isolation, independently reachable.
  generate
    for (
      genvar scenario_index = 0;
      scenario_index < 7;
      scenario_index = scenario_index + 1
    ) begin : cover_scenario
      for (
        genvar arrival_index = 0;
        arrival_index < 2;
        arrival_index = arrival_index + 1
      ) begin : cover_arrival
        localparam logic [2:0] SCENARIO_VALUE = scenario_index;
        localparam logic ARRIVAL_VALUE = arrival_index;

        always_ff @(posedge clk_i) begin
          cover (
            initialized &&
            (control_scenario == SCENARIO_VALUE) &&
            (arrival_second == ARRIVAL_VALUE) &&
            (cycle_count == 32'd6) &&
            (pc == 12'h002) &&
            (accumulator == 32'h0000_0044) &&
            (auxiliary_register_0 == expected_retired_ar0) &&
            (stack_top == expected_return_pc) &&
            (stack_level_1 == expected_call_stack_top) &&
            interrupt_mask &&
            !interrupt_pending
          );
        end
      end
    end
  endgenerate
endmodule

`default_nettype wire
