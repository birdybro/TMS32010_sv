`default_nettype none

// FORMAL-001 bounded actual-core harness for both request-arrival intervals
// of indirect IN and OUT across the documented auxiliary-address controls.
//
// This proves logical core sequencing with a fixed callback and RAM fixture.
// It does not establish peripheral, package-pin, or electrical behavior.
module tms32010_interrupt_io_indirect_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  (* anyconst *) logic       select_out;
  (* anyconst *) logic       select_arp;
  (* anyconst *) logic [1:0] update_mode;
  (* anyconst *) logic       change_arp;
  (* anyconst *) logic       arrival_second;

  logic [2:0]  initialize_count = 3'd0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic        initialized;
  logic        int_n;
  logic        transfer_seen = 1'b0;
  logic [1:0]  transfer_count = 2'd0;
  logic [7:0]  preload_address;
  logic [15:0] preload_data;
  logic [6:0]  indirect_control;
  logic [15:0] io_opcode;
  logic [15:0] program_data;
  logic [7:0]  expected_data_address;
  logic [15:0] expected_source_data;
  logic [31:0] expected_accumulator;
  logic [15:0] expected_ar0;
  logic [15:0] expected_ar1;
  logic        expected_final_arp;
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
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
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

  assign initialize = initialize_count != 3'd4;
  assign initialized = !initialize;

  always_comb begin
    assume (update_mode <= 2'd2);
  end

  // Four fixture writes establish both auxiliary-register load words and the
  // two possible OUT source words before architectural execution begins.
  always_comb begin
    case (initialize_count)
      3'd0: begin
        preload_address = 8'h00;
        preload_data = 16'ha003;
      end
      3'd1: begin
        preload_address = 8'h01;
        preload_data = 16'h5e04;
      end
      3'd2: begin
        preload_address = 8'h03;
        preload_data = 16'h1234;
      end
      default: begin
        preload_address = 8'h04;
        preload_data = 16'h5678;
      end
    endcase
  end

  // TI's legal common indirect controls are: bit 7 indirect, bits 6/2/1
  // clear, one of bits 5/4 for increment/decrement, bit 3 set to preserve
  // ARP, or bit 3 clear with bit 0 selecting the replacement ARP.
  always_comb begin
    indirect_control = 7'h08;
    case (update_mode)
      2'd1: indirect_control[5] = 1'b1;
      2'd2: indirect_control[4] = 1'b1;
      default: begin
      end
    endcase
    if (change_arp) begin
      indirect_control[3] = 1'b0;
      indirect_control[0] = !select_arp;
    end
  end

  always_comb begin
    io_opcode = select_out ? 16'h4f80 : 16'h4280;
    io_opcode[6:0] = indirect_control;
  end

  assign expected_data_address = select_arp ? 8'h04 : 8'h03;
  assign expected_source_data = select_arp ? 16'h5678 : 16'h1234;
  assign expected_accumulator = select_out
    ? {16'h0000, expected_source_data}
    : 32'hffff_cafe;
  assign expected_final_arp = change_arp ? !select_arp : select_arp;

  always_comb begin
    expected_ar0 = 16'ha003;
    expected_ar1 = 16'h5e04;
    if (!select_arp) begin
      case (update_mode)
        2'd1: expected_ar0 = 16'ha004;
        2'd2: expected_ar0 = 16'ha002;
        default: begin
        end
      endcase
    end else begin
      case (update_mode)
        2'd1: expected_ar1 = 16'h5e05;
        2'd2: expected_ar1 = 16'h5e03;
        default: begin
        end
      endcase
    end
  end

  // EINT retires request-free at cycle count 3. The symbolic value selects
  // the I/O opcode or external-transfer interval.
  assign int_n =
    !(
      initialized &&
      (
        ((!arrival_second) && (cycle_count == 32'd4)) ||
        (arrival_second && (cycle_count == 32'd5))
      )
    );

  always_comb begin
    case (program_address)
      12'h000: program_data = 16'h3800;  // direct LAR AR0,0
      12'h001: program_data = 16'h3901;  // direct LAR AR1,1
      12'h002: program_data = 16'h6880 | {15'h0000, select_arp};
      12'h003: program_data = 16'h7f82;  // EINT
      12'h004: program_data = io_opcode;
      12'h005: program_data = select_arp ? 16'h2004 : 16'h2003;
      12'h006: program_data = 16'h7f89;  // nonretiring dummy-fetched ZAC
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
    .debug_data_address_i          (preload_address),
    .debug_data_i                  (preload_data),
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
    .instruction_valid_o           (instruction_valid),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
  );

  always_ff @(posedge clk_i) begin
    if (initialize_count != 3'd4) begin
      initialize_count <= initialize_count + 3'd1;
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
      if (cycle_count <= 32'd8) begin
        assert (transfer_count <= 2'd1);
        if (transfer_seen) begin
          assert (transfer_count == 2'd1);
        end else begin
          assert (transfer_count == 2'd0);
        end
      end

      case (cycle_count)
        32'd0: begin
          assert (pc == 12'h000);
          assert (auxiliary_register_0 == 16'h0000);
          assert (auxiliary_register_1 == 16'h0000);
          assert (!auxiliary_register_pointer);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h000);
          assert (program_next_address == 12'h001);
          assert (data_read);
          assert (!data_write);
          assert (data_address_valid);
          assert (data_address == 8'h00);
          assert (data_read_data == 16'ha003);
          assert (!(io_read || io_write));
        end
        32'd1: begin
          assert (pc == 12'h001);
          assert (auxiliary_register_0 == 16'ha003);
          assert (auxiliary_register_1 == 16'h0000);
          assert (!auxiliary_register_pointer);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h001);
          assert (program_next_address == 12'h002);
          assert (data_read);
          assert (!data_write);
          assert (data_address_valid);
          assert (data_address == 8'h01);
          assert (data_read_data == 16'h5e04);
          assert (!(io_read || io_write));
        end
        32'd2: begin
          assert (pc == 12'h002);
          assert (auxiliary_register_0 == 16'ha003);
          assert (auxiliary_register_1 == 16'h5e04);
          assert (!auxiliary_register_pointer);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h003);
          assert (!(io_read || io_write || data_read || data_write));
        end
        32'd3: begin
          assert (pc == 12'h003);
          assert (auxiliary_register_0 == 16'ha003);
          assert (auxiliary_register_1 == 16'h5e04);
          assert (auxiliary_register_pointer == select_arp);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h003);
          assert (program_next_address == 12'h004);
          assert (!(io_read || io_write || data_read || data_write));
        end
        32'd4: begin
          assert (pc == 12'h004);
          assert (auxiliary_register_0 == 16'ha003);
          assert (auxiliary_register_1 == 16'h5e04);
          assert (auxiliary_register_pointer == select_arp);
          assert (!interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h004);
          assert (program_next_address == 12'h005);
          assert (!(io_read || io_write || data_read || data_write));
          assert (!transfer_seen);
        end
        32'd5: begin
          // The old ARP-selected address owns the transfer. The encoded AR
          // and ARP changes cannot become visible before this interval ends.
          assert (pc == 12'h005);
          assert (auxiliary_register_0 == 16'ha003);
          assert (auxiliary_register_1 == 16'h5e04);
          assert (auxiliary_register_pointer == select_arp);
          assert (!interrupt_mask);
          assert (interrupt_pending == !arrival_second);
          assert (instruction_valid);
          assert (!program_read);
          assert (program_address == 12'h005);
          assert (program_next_address == 12'h005);
          assert (data_address_valid);
          assert (data_address == expected_data_address);
          assert (!transfer_seen);
          assert (!retired);
          if (select_out) begin
            assert (!io_read);
            assert (io_write);
            assert (io_port == 3'd7);
            assert (io_write_data == expected_source_data);
            assert (data_read);
            assert (!data_write);
            assert (data_read_data == expected_source_data);
          end else begin
            assert (io_read);
            assert (!io_write);
            assert (io_port == 3'd2);
            assert (!data_read);
            assert (data_write);
            assert (data_write_address_valid);
            assert (data_write_address == expected_data_address);
            assert (data_write_data == 16'hcafe);
          end
          assert (stack_top == 12'h000);
        end
        32'd6: begin
          // The protected LAC observes the completed transfer and the
          // auxiliary-address update is now architecturally visible.
          assert (pc == 12'h005);
          assert (auxiliary_register_0 == expected_ar0);
          assert (auxiliary_register_1 == expected_ar1);
          assert (auxiliary_register_pointer == expected_final_arp);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h005);
          assert (program_next_address == 12'h006);
          assert (!(io_read || io_write));
          assert (data_read);
          assert (!data_write);
          assert (data_address_valid);
          assert (data_address == expected_data_address);
          assert (data_read_data == (select_out ? expected_source_data : 16'hcafe));
          assert (transfer_seen);
          assert (transfer_count == 2'd1);
          assert (stack_top == 12'h000);
        end
        32'd7: begin
          assert (pc == 12'h006);
          assert (accumulator == expected_accumulator);
          assert (auxiliary_register_0 == expected_ar0);
          assert (auxiliary_register_1 == expected_ar1);
          assert (auxiliary_register_pointer == expected_final_arp);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (!instruction_valid);
          assert (program_read);
          assert (program_address == 12'h006);
          assert (program_next_address == 12'h002);
          assert (!(io_read || io_write || data_read || data_write));
          assert (stack_top == 12'h000);
        end
        32'd8: begin
          assert (pc == 12'h002);
          assert (accumulator == expected_accumulator);
          assert (auxiliary_register_0 == expected_ar0);
          assert (auxiliary_register_1 == expected_ar1);
          assert (auxiliary_register_pointer == expected_final_arp);
          assert (stack_top == 12'h006);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h003);
          assert (!(io_read || io_write || data_read || data_write));
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
        transfer_seen,
        transfer_count
      } == $past({
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
  end

  // One cover for each full selector tuple prevents isolated selector values
  // from masquerading as coverage of their Cartesian product.
  generate
    for (genvar direction_index = 0; direction_index < 2;
         direction_index = direction_index + 1) begin : cover_direction
      for (genvar arp_index = 0; arp_index < 2;
           arp_index = arp_index + 1) begin : cover_arp
        for (genvar update_index = 0; update_index < 3;
             update_index = update_index + 1) begin : cover_update
          for (genvar change_index = 0; change_index < 2;
               change_index = change_index + 1) begin : cover_change
            for (genvar arrival_index = 0; arrival_index < 2;
                 arrival_index = arrival_index + 1) begin : cover_arrival
              localparam logic DIRECTION_VALUE = direction_index;
              localparam logic ARP_VALUE = arp_index;
              localparam logic [1:0] UPDATE_VALUE = update_index;
              localparam logic CHANGE_VALUE = change_index;
              localparam logic ARRIVAL_VALUE = arrival_index;

              always_ff @(posedge clk_i) begin
                cover (
                  initialized &&
                  (select_out == DIRECTION_VALUE) &&
                  (select_arp == ARP_VALUE) &&
                  (update_mode == UPDATE_VALUE) &&
                  (change_arp == CHANGE_VALUE) &&
                  (arrival_second == ARRIVAL_VALUE) &&
                  (cycle_count == 32'd8) &&
                  (pc == 12'h002) &&
                  (accumulator == expected_accumulator) &&
                  (auxiliary_register_0 == expected_ar0) &&
                  (auxiliary_register_1 == expected_ar1) &&
                  (auxiliary_register_pointer == expected_final_arp) &&
                  (stack_top == 12'h006) &&
                  (transfer_count == 2'd1) &&
                  interrupt_mask &&
                  !interrupt_pending
                );
              end
            end
          end
        end
      end
    end
  endgenerate
endmodule

`default_nettype wire
