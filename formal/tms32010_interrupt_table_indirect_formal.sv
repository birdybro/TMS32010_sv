`default_nettype none

// FORMAL-001 bounded actual-core harness for request arrival during all three
// represented cycles of indirect TBLR and TBLW across documented controls.
//
// The mutable word and RAM preload are logical verification fixtures. This
// does not establish package-pin subphases, electrical timing, or peripherals.
module tms32010_interrupt_table_indirect_formal (
  input logic clk_i,
  input logic clock_enable_i
);
  (* anyconst *) logic       select_write;
  (* anyconst *) logic       select_arp;
  (* anyconst *) logic [1:0] update_mode;
  (* anyconst *) logic       change_arp;
  (* anyconst *) logic [1:0] arrival_interval;

  logic [2:0]  initialize_count = 3'd0;
  logic        past_valid = 1'b0;
  logic        initialize;
  logic        initialized;
  logic        int_n;
  logic        transfer_seen = 1'b0;
  logic [1:0]  transfer_count = 2'd0;
  logic [15:0] mutable_program_word = 16'h7f80;
  logic        write_seen = 1'b0;
  logic [1:0]  write_count = 2'd0;
  logic [7:0]  preload_address;
  logic [15:0] preload_data;
  logic [6:0]  indirect_control;
  logic [15:0] table_opcode;
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
  logic [15:0] program_write_data;
  logic        io_read;
  logic        io_write;
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
    assume (arrival_interval <= 2'd2);
  end

  // Four fixture writes establish two complete AR words and two distinct
  // potential TBLW sources before architectural execution begins.
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

  // Bits 6/2/1 remain zero. Exactly one of bits 5/4 may request the
  // documented post-increment/decrement, while bit 3 either preserves ARP or
  // allows bit 0 to select the other AR after instruction completion.
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
    table_opcode = select_write ? 16'h7d80 : 16'h6780;
    table_opcode[6:0] = indirect_control;
  end

  assign expected_data_address = select_arp ? 8'h04 : 8'h03;
  assign expected_source_data = select_arp ? 16'h5678 : 16'h1234;
  assign expected_accumulator = select_write
    ? {16'h0000, expected_source_data}
    : 32'hffff_b33c;
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

  // EINT retires request-free at cycle count 4. The symbolic interval selects
  // the opcode, discarded-prefetch, or ACC-addressed transfer interval.
  assign int_n =
    !(
      initialized &&
      (
        ((arrival_interval == 2'd0) && (cycle_count == 32'd5)) ||
        ((arrival_interval == 2'd1) && (cycle_count == 32'd6)) ||
        ((arrival_interval == 2'd2) && (cycle_count == 32'd7))
      )
    );

  always_comb begin
    case (program_address)
      12'h000: program_data = 16'h3800;  // direct LAR AR0,0
      12'h001: program_data = 16'h3901;  // direct LAR AR1,1
      12'h002: program_data = 16'h6880 | {15'h0000, select_arp};
      12'h003: program_data = 16'h7e20;  // LACK program address 0x020
      12'h004: program_data = 16'h7f82;  // EINT
      12'h005: program_data = table_opcode;
      12'h006: program_data = select_arp ? 16'h2004 : 16'h2003;
      12'h007: program_data = 16'h7f89;  // nonretiring dummy-fetched ZAC
      12'h020: program_data = select_write
        ? mutable_program_word
        : 16'hb33c;
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
      mutable_program_word <= 16'h7f80;
      write_seen <= 1'b0;
      write_count <= 2'd0;
      transfer_seen <= 1'b0;
      transfer_count <= 2'd0;
    end else begin
      // The vector fixture naturally loops through the setup program after
      // the target entry. Scope the mutable-memory observer to the first
      // qualified table sequence; all target assertions complete by count 10.
      if (
        clock_enable_i &&
        (cycle_count <= 32'd10) &&
        program_write
      ) begin
        assert (select_write);
        assert (program_address == 12'h020);
        assert (program_write_data == expected_source_data);
        mutable_program_word <= program_write_data;
        write_seen <= 1'b1;
        write_count <= write_count + 2'd1;
      end

      if (
        clock_enable_i &&
        (cycle_count <= 32'd10) &&
        (program_address == 12'h020) &&
        (
          (select_write && program_write) ||
          (!select_write && program_read)
        )
      ) begin
        transfer_seen <= 1'b1;
        transfer_count <= transfer_count + 2'd1;
      end
    end

    if (initialized) begin
      assert (!illegal);
      assert (!(program_read && program_write));
      assert (!(io_read || io_write));

      if (cycle_count <= 32'd10) begin
        assert (program_write == (select_write && (cycle_count == 32'd7)));
        assert (transfer_count <= 2'd1);
        assert (write_count <= 2'd1);
        if (transfer_seen) begin
          assert (transfer_count == 2'd1);
        end else begin
          assert (transfer_count == 2'd0);
        end
        if (write_seen) begin
          assert (select_write);
          assert (mutable_program_word == expected_source_data);
          assert (write_count == 2'd1);
        end else begin
          assert (mutable_program_word == 16'h7f80);
          assert (write_count == 2'd0);
        end
      end

      case (cycle_count)
        32'd0: begin
          assert (pc == 12'h000);
          assert (accumulator == 32'h0000_0000);
          assert (auxiliary_register_0 == 16'h0000);
          assert (auxiliary_register_1 == 16'h0000);
          assert (!auxiliary_register_pointer);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h000);
          assert (program_next_address == 12'h001);
          assert (data_read && !data_write);
          assert (data_address_valid && (data_address == 8'h00));
          assert (data_read_data == 16'ha003);
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
          assert (data_read && !data_write);
          assert (data_address_valid && (data_address == 8'h01));
          assert (data_read_data == 16'h5e04);
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
          assert (!(data_read || data_write));
        end
        32'd3: begin
          assert (pc == 12'h003);
          assert (accumulator == 32'h0000_0000);
          assert (auxiliary_register_pointer == select_arp);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h003);
          assert (program_next_address == 12'h004);
          assert (!(data_read || data_write));
        end
        32'd4: begin
          assert (pc == 12'h004);
          assert (accumulator == 32'h0000_0020);
          assert (auxiliary_register_0 == 16'ha003);
          assert (auxiliary_register_1 == 16'h5e04);
          assert (auxiliary_register_pointer == select_arp);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h004);
          assert (program_next_address == 12'h005);
          assert (!(data_read || data_write));
        end
        32'd5: begin
          assert (pc == 12'h005);
          assert (accumulator == 32'h0000_0020);
          assert (auxiliary_register_0 == 16'ha003);
          assert (auxiliary_register_1 == 16'h5e04);
          assert (auxiliary_register_pointer == select_arp);
          assert (!interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read);
          assert (program_address == 12'h005);
          assert (program_next_address == 12'h006);
          assert (!(data_read || data_write));
          assert (!transfer_seen);
        end
        32'd6: begin
          // Cycle 1 reads and discards PC+1. No transfer or indirect-address
          // effect may appear at this boundary.
          assert (pc == 12'h006);
          assert (accumulator == 32'h0000_0020);
          assert (auxiliary_register_0 == 16'ha003);
          assert (auxiliary_register_1 == 16'h5e04);
          assert (auxiliary_register_pointer == select_arp);
          assert (!interrupt_mask);
          assert (interrupt_pending == (arrival_interval == 2'd0));
          assert (instruction_valid);
          assert (!retired);
          assert (program_read);
          assert (program_address == 12'h006);
          assert (program_next_address == 12'h006);
          assert (!(data_read || data_write));
          assert (!transfer_seen);
          assert (stack_top == 12'h000);
        end
        32'd7: begin
          // Cycle 2 uses ACC for program space and the old ARP-selected RAM
          // address. AR and ARP remain unchanged through the transfer.
          assert (pc == 12'h006);
          assert (accumulator == 32'h0000_0020);
          assert (auxiliary_register_0 == 16'ha003);
          assert (auxiliary_register_1 == 16'h5e04);
          assert (auxiliary_register_pointer == select_arp);
          assert (!interrupt_mask);
          assert (interrupt_pending == (arrival_interval <= 2'd1));
          assert (instruction_valid);
          assert (!retired);
          assert (program_address == 12'h020);
          assert (program_next_address == 12'h006);
          assert (data_address_valid);
          assert (data_address == expected_data_address);
          assert (!transfer_seen);
          assert (stack_top == 12'h000);
          if (select_write) begin
            assert (!program_read);
            assert (program_write);
            assert (program_write_data == expected_source_data);
            assert (data_read && !data_write);
            assert (data_read_data == expected_source_data);
            assert (!write_seen);
          end else begin
            assert (program_read);
            assert (!program_write);
            assert (!data_read && data_write);
            assert (data_write_address_valid);
            assert (data_write_address == expected_data_address);
            assert (data_write_data == 16'hb33c);
          end
        end
        32'd8: begin
          // Cycle 3 repeats PC+1 and retires the table instruction. Only now
          // may the selected AR and optional next ARP become visible.
          assert (pc == 12'h006);
          assert (accumulator == 32'h0000_0020);
          assert (auxiliary_register_0 == expected_ar0);
          assert (auxiliary_register_1 == expected_ar1);
          assert (auxiliary_register_pointer == expected_final_arp);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (instruction_valid);
          assert (program_read && !program_write);
          assert (program_address == 12'h006);
          assert (program_next_address == 12'h007);
          assert (data_read && !data_write);
          assert (data_address_valid);
          assert (data_address == expected_data_address);
          assert (data_read_data == (select_write ? expected_source_data : 16'hb33c));
          assert (transfer_seen);
          assert (transfer_count == 2'd1);
          assert (write_seen == select_write);
          assert (write_count == (select_write ? 2'd1 : 2'd0));
          assert (stack_top == 12'h000);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
        end
        32'd9: begin
          // The protected direct LAC has consumed the completed transfer;
          // entry owns a nonretiring return-PC dummy fetch.
          assert (pc == 12'h007);
          assert (accumulator == expected_accumulator);
          assert (auxiliary_register_0 == expected_ar0);
          assert (auxiliary_register_1 == expected_ar1);
          assert (auxiliary_register_pointer == expected_final_arp);
          assert (!interrupt_mask);
          assert (interrupt_pending);
          assert (!instruction_valid);
          assert (program_read && !program_write);
          assert (program_address == 12'h007);
          assert (program_next_address == 12'h002);
          assert (!(data_read || data_write));
          assert (stack_top == 12'h000);
          assert (transfer_count == 2'd1);
        end
        32'd10: begin
          assert (pc == 12'h002);
          assert (accumulator == expected_accumulator);
          assert (auxiliary_register_0 == expected_ar0);
          assert (auxiliary_register_1 == expected_ar1);
          assert (auxiliary_register_pointer == expected_final_arp);
          assert (stack_top == 12'h007);
          assert (stack_level_1 == 12'h000);
          assert (stack_level_2 == 12'h000);
          assert (stack_bottom == 12'h000);
          assert (interrupt_mask);
          assert (!interrupt_pending);
          assert (instruction_valid);
          assert (program_read && !program_write);
          assert (program_address == 12'h002);
          assert (program_next_address == 12'h003);
          assert (!(data_read || data_write));
          assert (transfer_count == 2'd1);
          assert (write_count == (select_write ? 2'd1 : 2'd0));
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
        mutable_program_word,
        write_seen,
        write_count,
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
        mutable_program_word,
        write_seen,
        write_count,
        transfer_seen,
        transfer_count
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
        program_write_data,
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

  // One cover per complete selector tuple prevents isolated values from
  // masquerading as Cartesian-product coverage.
  generate
    for (genvar direction_index = 0; direction_index < 2;
         direction_index = direction_index + 1) begin : cover_direction
      for (genvar arp_index = 0; arp_index < 2;
           arp_index = arp_index + 1) begin : cover_arp
        for (genvar update_index = 0; update_index < 3;
             update_index = update_index + 1) begin : cover_update
          for (genvar change_index = 0; change_index < 2;
               change_index = change_index + 1) begin : cover_change
            for (genvar arrival_index = 0; arrival_index < 3;
                 arrival_index = arrival_index + 1) begin : cover_arrival
              localparam logic DIRECTION_VALUE = direction_index;
              localparam logic ARP_VALUE = arp_index;
              localparam logic [1:0] UPDATE_VALUE = update_index;
              localparam logic CHANGE_VALUE = change_index;
              localparam logic [1:0] ARRIVAL_VALUE = arrival_index;

              always_ff @(posedge clk_i) begin
                cover (
                  initialized &&
                  (select_write == DIRECTION_VALUE) &&
                  (select_arp == ARP_VALUE) &&
                  (update_mode == UPDATE_VALUE) &&
                  (change_arp == CHANGE_VALUE) &&
                  (arrival_interval == ARRIVAL_VALUE) &&
                  (cycle_count == 32'd10) &&
                  (pc == 12'h002) &&
                  (accumulator == expected_accumulator) &&
                  (auxiliary_register_0 == expected_ar0) &&
                  (auxiliary_register_1 == expected_ar1) &&
                  (auxiliary_register_pointer == expected_final_arp) &&
                  (stack_top == 12'h007) &&
                  (transfer_count == 2'd1) &&
                  (write_count == (select_write ? 2'd1 : 2'd0)) &&
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
