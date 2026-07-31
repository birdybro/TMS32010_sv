`default_nettype none

module tms32010_core (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        reset_i,
  input  logic        clock_enable_i,

  output logic [11:0] program_address_o,
  output logic [11:0] program_next_address_o,
  output logic        program_read_o,
  input  logic [15:0] program_data_i,

  output logic [7:0]  data_address_o,
  output logic        data_read_o,
  output logic        data_write_o,
  output logic        data_address_valid_o,
  output logic [7:0]  data_write_address_o,
  output logic        data_write_address_valid_o,
  output logic [15:0] data_read_data_o,
  output logic [15:0] data_write_data_o,
  input  logic        debug_data_write_i,
  input  logic [7:0]  debug_data_address_i,
  input  logic [15:0] debug_data_i,

  output logic [11:0] pc_o,
  output logic [31:0] accumulator_o,
  output logic [15:0] t_register_o,
  output logic [31:0] product_register_o,
  output logic [15:0] auxiliary_register_0_o,
  output logic [15:0] auxiliary_register_1_o,
  output logic        auxiliary_register_pointer_o,
  output logic        data_page_pointer_o,
  output logic        overflow_flag_o,
  output logic        overflow_mode_o,
  output logic        interrupt_mask_o,
  output logic        instruction_valid_o,
  output logic        retired_o,
  output logic        illegal_o,
  output logic [31:0] cycle_count_o
);
  // Yosys 0.33 cannot import the operation enum package. These encodings are
  // checked against tms32010_pkg through the exhaustive decoder regression.
  localparam logic [5:0] OP_LACK = 6'd0;
  localparam logic [5:0] OP_NOP  = 6'd1;
  localparam logic [5:0] OP_ZAC  = 6'd2;
  localparam logic [5:0] OP_ROVM = 6'd3;
  localparam logic [5:0] OP_SOVM = 6'd4;
  localparam logic [5:0] OP_LARK = 6'd5;
  localparam logic [5:0] OP_LARP = 6'd6;
  localparam logic [5:0] OP_LDPK = 6'd7;
  localparam logic [5:0] OP_LAC  = 6'd8;
  localparam logic [5:0] OP_SACL = 6'd9;
  localparam logic [5:0] OP_SACH = 6'd10;
  localparam logic [5:0] OP_ZALH = 6'd11;
  localparam logic [5:0] OP_ZALS = 6'd12;
  localparam logic [5:0] OP_ADDS = 6'd13;
  localparam logic [5:0] OP_XOR  = 6'd14;
  localparam logic [5:0] OP_AND  = 6'd15;
  localparam logic [5:0] OP_OR   = 6'd16;
  localparam logic [5:0] OP_ADD  = 6'd17;
  localparam logic [5:0] OP_SUB  = 6'd18;
  localparam logic [5:0] OP_SUBS = 6'd19;
  localparam logic [5:0] OP_LAR  = 6'd20;
  localparam logic [5:0] OP_SAR  = 6'd21;
  localparam logic [5:0] OP_MAR  = 6'd22;
  localparam logic [5:0] OP_LDP  = 6'd23;
  localparam logic [5:0] OP_LT   = 6'd24;
  localparam logic [5:0] OP_MPY  = 6'd25;
  localparam logic [5:0] OP_MPYK = 6'd26;
  localparam logic [5:0] OP_PAC  = 6'd27;
  localparam logic [5:0] OP_APAC = 6'd28;
  localparam logic [5:0] OP_SPAC = 6'd29;
  localparam logic [5:0] OP_LTA  = 6'd30;
  localparam logic [5:0] OP_LTD  = 6'd31;
  localparam logic [5:0] OP_DMOV = 6'd32;
  localparam logic [5:0] OP_DINT = 6'd33;
  localparam logic [5:0] OP_EINT = 6'd34;
  localparam logic [5:0] OP_LST  = 6'd35;
  localparam logic [5:0] OP_SUBC = 6'd36;
  localparam logic [5:0] OP_BANZ = 6'd37;
  localparam logic [5:0] OP_B    = 6'd38;

  logic [5:0] decoded_operation;
  logic [7:0] decoded_immediate;
  logic [12:0] decoded_immediate_13;
  logic       decoded_auxiliary_register;
  logic [3:0] decoded_shift;
  logic       decoded_indirect;
  logic [6:0] decoded_addressing_field;
  logic       decoded_valid;
  logic       ram_address_valid;
  logic       ram_write_address_valid;
  logic [15:0] ram_read_data;
  logic [31:0] adds_wrapped_result;
  logic        adds_overflow;
  logic [31:0] shifted_data_operand;
  logic [31:0] add_wrapped_result;
  logic        add_overflow;
  logic [31:0] sub_wrapped_result;
  logic        sub_overflow;
  logic [31:0] subs_wrapped_result;
  logic        subs_overflow;
  logic [31:0] subc_operand;
  logic [31:0] subc_intermediate;
  logic        subc_overflow;
  logic [31:0] subc_result;
  logic [31:0] multiplier_product;
  logic [15:0] multiplier_operand;
  logic [31:0] apac_wrapped_result;
  logic        apac_overflow;
  logic [31:0] spac_wrapped_result;
  logic        spac_overflow;
  logic        branch_operand_pending;
  logic [5:0]  pending_branch_operation;

  tms32010_decode decode (
    .instruction_i (program_data_i),
    .valid_o       (decoded_valid),
    .operation_o   (decoded_operation),
    .immediate_o   (decoded_immediate),
    .immediate_13_o (decoded_immediate_13),
    .auxiliary_register_o (decoded_auxiliary_register),
    .shift_o       (decoded_shift),
    .indirect_o    (decoded_indirect),
    .addressing_field_o (decoded_addressing_field)
  );

  always_comb begin
    data_address_o = 8'h00;
    if (
      !branch_operand_pending &&
      decoded_valid &&
      (
        (decoded_operation == OP_LAC) ||
        (decoded_operation == OP_SACL) ||
        (decoded_operation == OP_SACH) ||
        (decoded_operation == OP_ZALH) ||
        (decoded_operation == OP_ZALS) ||
        (decoded_operation == OP_ADDS) ||
        (decoded_operation == OP_XOR) ||
        (decoded_operation == OP_AND) ||
        (decoded_operation == OP_OR) ||
        (decoded_operation == OP_ADD) ||
        (decoded_operation == OP_SUB) ||
        (decoded_operation == OP_SUBS) ||
        (decoded_operation == OP_SUBC) ||
        (decoded_operation == OP_LAR) ||
        (decoded_operation == OP_SAR) ||
        (decoded_operation == OP_LDP) ||
        (decoded_operation == OP_DMOV) ||
        (decoded_operation == OP_LT) ||
        (decoded_operation == OP_LTD) ||
        (decoded_operation == OP_LTA) ||
        (decoded_operation == OP_MPY) ||
        (decoded_operation == OP_LST)
      )
    ) begin
      if (decoded_indirect) begin
        data_address_o =
          auxiliary_register_pointer_o
            ? auxiliary_register_1_o[7:0]
            : auxiliary_register_0_o[7:0];
      end else begin
        data_address_o = {data_page_pointer_o, decoded_addressing_field};
      end
    end
  end

  tms32010_internal_ram data_ram (
    .clk_i                  (clk_i),
    .read_address_i         (data_address_o),
    .read_data_o            (ram_read_data),
    .read_address_valid_o   (ram_address_valid),
    .write_i                (
      data_write_o && clock_enable_i && instruction_valid_o
    ),
    .write_address_i        (data_write_address_o),
    .write_address_valid_o  (ram_write_address_valid),
    .write_data_i           (data_write_data_o),
    .debug_write_i          (debug_data_write_i),
    .debug_address_i        (debug_data_address_i),
    .debug_data_i           (debug_data_i)
  );

  tms32010_multiplier multiplier (
    .multiplicand_i (t_register_o),
    .multiplier_i   (multiplier_operand),
    .product_o      (multiplier_product)
  );

  assign multiplier_operand =
    (decoded_operation == OP_MPYK)
      ? {{3{decoded_immediate_13[12]}}, decoded_immediate_13}
      : ram_read_data;

  assign program_address_o = pc_o;
  always_comb begin
    program_next_address_o = pc_o;
    if (branch_operand_pending) begin
      if (program_data_i[15:12] == 4'h0) begin
        case (pending_branch_operation)
          OP_B: program_next_address_o = program_data_i[11:0];
          OP_BANZ: begin
            if (
              auxiliary_register_pointer_o
                ? (auxiliary_register_1_o[8:0] != 9'h000)
                : (auxiliary_register_0_o[8:0] != 9'h000)
            ) begin
              program_next_address_o = program_data_i[11:0];
            end else begin
              program_next_address_o = pc_o + 12'h001;
            end
          end
          default: begin
          end
        endcase
      end
    end else if (instruction_valid_o) begin
      program_next_address_o = pc_o + 12'h001;
    end
  end
  assign program_read_o    = ~reset_i && ~initialize_i;
  assign data_read_o =
    ~reset_i &&
    ~initialize_i &&
    ~branch_operand_pending &&
    decoded_valid &&
    (
      (decoded_operation == OP_LAC) ||
      (decoded_operation == OP_ZALH) ||
      (decoded_operation == OP_ZALS) ||
      (decoded_operation == OP_ADDS) ||
      (decoded_operation == OP_XOR) ||
      (decoded_operation == OP_AND) ||
      (decoded_operation == OP_OR) ||
      (decoded_operation == OP_ADD) ||
      (decoded_operation == OP_SUB) ||
      (decoded_operation == OP_SUBS) ||
      (decoded_operation == OP_SUBC) ||
      (decoded_operation == OP_LAR) ||
      (decoded_operation == OP_LDP) ||
      (decoded_operation == OP_DMOV) ||
      (decoded_operation == OP_LT) ||
      (decoded_operation == OP_LTD) ||
      (decoded_operation == OP_LTA) ||
      (decoded_operation == OP_MPY) ||
      (decoded_operation == OP_LST)
    );
  assign data_write_o =
    ~reset_i &&
    ~initialize_i &&
    ~branch_operand_pending &&
    decoded_valid &&
    (
      (decoded_operation == OP_SACL) ||
      (decoded_operation == OP_SACH) ||
      (decoded_operation == OP_SAR) ||
      (decoded_operation == OP_DMOV) ||
      (decoded_operation == OP_LTD)
    );
  assign data_address_valid_o =
    (data_read_o || data_write_o) && ram_address_valid;
  always_comb begin
    data_write_address_o = data_address_o;
    if (
      (decoded_operation == OP_DMOV) ||
      (decoded_operation == OP_LTD)
    ) begin
      data_write_address_o = data_address_o + 8'd1;
    end
  end
  assign data_write_address_valid_o =
    data_write_o && ram_write_address_valid;
  assign data_read_data_o     = ram_read_data;
  always_comb begin
    data_write_data_o = accumulator_o[15:0];
    if (
      (decoded_operation == OP_DMOV) ||
      (decoded_operation == OP_LTD)
    ) begin
      data_write_data_o = ram_read_data;
    end else if (decoded_operation == OP_SAR) begin
      data_write_data_o =
        decoded_auxiliary_register
          ? auxiliary_register_1_o
          : auxiliary_register_0_o;
      if (
        decoded_indirect &&
        (decoded_auxiliary_register == auxiliary_register_pointer_o)
      ) begin
        if (decoded_addressing_field[5]) begin
          data_write_data_o = {
            data_write_data_o[15:9],
            data_write_data_o[8:0] + 9'd1
          };
        end else if (decoded_addressing_field[4]) begin
          data_write_data_o = {
            data_write_data_o[15:9],
            data_write_data_o[8:0] - 9'd1
          };
        end
      end
    end else if (decoded_operation == OP_SACH) begin
      case (decoded_shift)
        4'd1: data_write_data_o = {
          accumulator_o[30:16],
          accumulator_o[15]
        };
        4'd4: data_write_data_o = {
          accumulator_o[27:16],
          accumulator_o[15:12]
        };
        default: data_write_data_o = accumulator_o[31:16];
      endcase
    end
  end
  always_comb begin
    if (branch_operand_pending) begin
      instruction_valid_o =
        (program_data_i[15:12] == 4'h0) &&
        (
          (pending_branch_operation == OP_B) ||
          (pending_branch_operation == OP_BANZ)
        );
    end else begin
      instruction_valid_o =
        decoded_valid &&
        (
          (
            (decoded_operation != OP_LAC) &&
            (decoded_operation != OP_SACL) &&
            (decoded_operation != OP_SACH) &&
            (decoded_operation != OP_ZALH) &&
            (decoded_operation != OP_ZALS) &&
            (decoded_operation != OP_ADDS) &&
            (decoded_operation != OP_XOR) &&
            (decoded_operation != OP_AND) &&
            (decoded_operation != OP_OR) &&
            (decoded_operation != OP_ADD) &&
            (decoded_operation != OP_SUB) &&
            (decoded_operation != OP_SUBS) &&
            (decoded_operation != OP_SUBC) &&
            (decoded_operation != OP_LAR) &&
            (decoded_operation != OP_SAR) &&
            (decoded_operation != OP_LDP) &&
            (decoded_operation != OP_DMOV) &&
            (decoded_operation != OP_LT) &&
            (decoded_operation != OP_LTD) &&
            (decoded_operation != OP_LTA) &&
            (decoded_operation != OP_MPY) &&
            (decoded_operation != OP_LST)
          ) ||
          (
            ram_address_valid &&
            (
              (
                (decoded_operation != OP_DMOV) &&
                (decoded_operation != OP_LTD)
              ) ||
              ram_write_address_valid
            )
          )
        );
    end
  end
  assign adds_wrapped_result =
    accumulator_o + {16'h0000, ram_read_data};
  assign adds_overflow =
    ~accumulator_o[31] && adds_wrapped_result[31];
  assign shifted_data_operand =
    {{16{ram_read_data[15]}}, ram_read_data} << decoded_shift;
  assign add_wrapped_result = accumulator_o + shifted_data_operand;
  assign add_overflow =
    ~(accumulator_o[31] ^ shifted_data_operand[31]) &&
    (accumulator_o[31] ^ add_wrapped_result[31]);
  assign sub_wrapped_result = accumulator_o - shifted_data_operand;
  assign sub_overflow =
    (accumulator_o[31] ^ shifted_data_operand[31]) &&
    (accumulator_o[31] ^ sub_wrapped_result[31]);
  assign subs_wrapped_result =
    accumulator_o - {16'h0000, ram_read_data};
  assign subs_overflow =
    accumulator_o[31] && ~subs_wrapped_result[31];
  assign subc_operand =
    {16'h0000, ram_read_data} << 5'd15;
  assign subc_intermediate = accumulator_o - subc_operand;
  assign subc_overflow =
    (accumulator_o[31] ^ subc_operand[31]) &&
    (accumulator_o[31] ^ subc_intermediate[31]);
  assign subc_result =
    subc_intermediate[31]
      ? (accumulator_o << 1)
      : ((subc_intermediate << 1) | 32'h0000_0001);
  assign apac_wrapped_result = accumulator_o + product_register_o;
  assign apac_overflow =
    ~(accumulator_o[31] ^ product_register_o[31]) &&
    (accumulator_o[31] ^ apac_wrapped_result[31]);
  assign spac_wrapped_result = accumulator_o - product_register_o;
  assign spac_overflow =
    (accumulator_o[31] ^ product_register_o[31]) &&
    (accumulator_o[31] ^ spac_wrapped_result[31]);

  always_ff @(posedge clk_i) begin
    retired_o <= 1'b0;

    if (initialize_i) begin
      pc_o                         <= 12'h000;
      accumulator_o                <= 32'h0000_0000;
      t_register_o                 <= 16'h0000;
      product_register_o           <= 32'h0000_0000;
      auxiliary_register_0_o       <= 16'h0000;
      auxiliary_register_1_o       <= 16'h0000;
      auxiliary_register_pointer_o <= 1'b0;
      data_page_pointer_o          <= 1'b0;
      overflow_flag_o              <= 1'b0;
      overflow_mode_o              <= 1'b0;
      interrupt_mask_o             <= 1'b1;
      illegal_o                    <= 1'b0;
      cycle_count_o                <= 32'h0000_0000;
      branch_operand_pending       <= 1'b0;
      pending_branch_operation     <= OP_B;
    end else if (reset_i) begin
      pc_o             <= 12'h000;
      interrupt_mask_o <= 1'b1;
      illegal_o        <= 1'b0;
      cycle_count_o    <= 32'h0000_0000;
      branch_operand_pending   <= 1'b0;
      pending_branch_operation <= OP_B;
      // ACC, T, P, AR0, AR1, ARP, DP, and OV receive no arbitrary reset value.
      // TI explicitly documents that reset leaves OVM unchanged. Retention of
      // the other unlisted state is an implementation policy under OQ-012.
    end else if (clock_enable_i) begin
      if (branch_operand_pending) begin
        if (instruction_valid_o) begin
          case (pending_branch_operation)
            OP_B: pc_o <= program_data_i[11:0];
            OP_BANZ: begin
              if (auxiliary_register_pointer_o) begin
                auxiliary_register_1_o <= {
                  auxiliary_register_1_o[15:9],
                  auxiliary_register_1_o[8:0] - 9'd1
                };
                pc_o <=
                  (auxiliary_register_1_o[8:0] != 9'h000)
                    ? program_data_i[11:0]
                    : pc_o + 12'h001;
              end else begin
                auxiliary_register_0_o <= {
                  auxiliary_register_0_o[15:9],
                  auxiliary_register_0_o[8:0] - 9'd1
                };
                pc_o <=
                  (auxiliary_register_0_o[8:0] != 9'h000)
                    ? program_data_i[11:0]
                    : pc_o + 12'h001;
              end
            end
            default: begin
            end
          endcase
          branch_operand_pending <= 1'b0;
          retired_o              <= 1'b1;
          illegal_o              <= 1'b0;
          cycle_count_o          <= cycle_count_o + 32'h0000_0001;
        end else begin
          illegal_o <= 1'b1;
        end
      end else if (instruction_valid_o) begin
        pc_o          <= pc_o + 12'h001;
        illegal_o     <= 1'b0;
        cycle_count_o <= cycle_count_o + 32'h0000_0001;
        if (
          (decoded_operation == OP_B) ||
          (decoded_operation == OP_BANZ)
        ) begin
          branch_operand_pending   <= 1'b1;
          pending_branch_operation <= decoded_operation;
        end else begin
          retired_o <= 1'b1;
        end

        case (decoded_operation)
          OP_LACK: accumulator_o   <= {24'h000000, decoded_immediate};
          OP_LAC: begin
            accumulator_o <=
              {{16{ram_read_data[15]}}, ram_read_data} << decoded_shift;
          end
          OP_LAR: begin
            if (decoded_auxiliary_register) begin
              auxiliary_register_1_o <= ram_read_data;
            end else begin
              auxiliary_register_0_o <= ram_read_data;
            end
          end
          OP_LDP: data_page_pointer_o <= ram_read_data[0];
          OP_LT: t_register_o <= ram_read_data;
          OP_DMOV: begin
          end
          OP_LTD: begin
            t_register_o <= ram_read_data;
            if (apac_overflow) begin
              overflow_flag_o <= 1'b1;
              if (overflow_mode_o) begin
                accumulator_o <=
                  accumulator_o[31] ? 32'h8000_0000 : 32'h7fff_ffff;
              end else begin
                accumulator_o <= apac_wrapped_result;
              end
            end else begin
              accumulator_o <= apac_wrapped_result;
            end
          end
          OP_LTA: begin
            t_register_o <= ram_read_data;
            if (apac_overflow) begin
              overflow_flag_o <= 1'b1;
              if (overflow_mode_o) begin
                accumulator_o <=
                  accumulator_o[31] ? 32'h8000_0000 : 32'h7fff_ffff;
              end else begin
                accumulator_o <= apac_wrapped_result;
              end
            end else begin
              accumulator_o <= apac_wrapped_result;
            end
          end
          OP_MPY: product_register_o <= multiplier_product;
          OP_MPYK: product_register_o <= multiplier_product;
          OP_PAC: accumulator_o <= product_register_o;
          OP_APAC: begin
            if (apac_overflow) begin
              overflow_flag_o <= 1'b1;
              if (overflow_mode_o) begin
                accumulator_o <=
                  accumulator_o[31] ? 32'h8000_0000 : 32'h7fff_ffff;
              end else begin
                accumulator_o <= apac_wrapped_result;
              end
            end else begin
              accumulator_o <= apac_wrapped_result;
            end
          end
          OP_SPAC: begin
            if (spac_overflow) begin
              overflow_flag_o <= 1'b1;
              if (overflow_mode_o) begin
                accumulator_o <=
                  accumulator_o[31] ? 32'h8000_0000 : 32'h7fff_ffff;
              end else begin
                accumulator_o <= spac_wrapped_result;
              end
            end else begin
              accumulator_o <= spac_wrapped_result;
            end
          end
          OP_SAR: begin
          end
          OP_SACL: begin
          end
          OP_SACH: begin
          end
          OP_ZALH: accumulator_o <= {ram_read_data, 16'h0000};
          OP_ZALS: accumulator_o <= {16'h0000, ram_read_data};
          OP_ADDS: begin
            if (adds_overflow) begin
              overflow_flag_o <= 1'b1;
              accumulator_o <=
                overflow_mode_o ? 32'h7fff_ffff : adds_wrapped_result;
            end else begin
              accumulator_o <= adds_wrapped_result;
            end
          end
          OP_XOR: accumulator_o <= {
            accumulator_o[31:16],
            accumulator_o[15:0] ^ ram_read_data
          };
          OP_AND: accumulator_o <= {
            16'h0000,
            accumulator_o[15:0] & ram_read_data
          };
          OP_OR: accumulator_o <= {
            accumulator_o[31:16],
            accumulator_o[15:0] | ram_read_data
          };
          OP_ADD: begin
            if (add_overflow) begin
              overflow_flag_o <= 1'b1;
              if (overflow_mode_o) begin
                accumulator_o <=
                  accumulator_o[31] ? 32'h8000_0000 : 32'h7fff_ffff;
              end else begin
                accumulator_o <= add_wrapped_result;
              end
            end else begin
              accumulator_o <= add_wrapped_result;
            end
          end
          OP_SUB: begin
            if (sub_overflow) begin
              overflow_flag_o <= 1'b1;
              if (overflow_mode_o) begin
                accumulator_o <=
                  accumulator_o[31] ? 32'h8000_0000 : 32'h7fff_ffff;
              end else begin
                accumulator_o <= sub_wrapped_result;
              end
            end else begin
              accumulator_o <= sub_wrapped_result;
            end
          end
          OP_SUBS: begin
            if (subs_overflow) begin
              overflow_flag_o <= 1'b1;
              accumulator_o <=
                overflow_mode_o ? 32'h8000_0000 : subs_wrapped_result;
            end else begin
              accumulator_o <= subs_wrapped_result;
            end
          end
          OP_SUBC: begin
            accumulator_o <= subc_result;
            if (subc_overflow) begin
              overflow_flag_o <= 1'b1;
            end
          end
          OP_LARK: begin
            if (decoded_auxiliary_register) begin
              auxiliary_register_1_o <= {8'h00, decoded_immediate};
            end else begin
              auxiliary_register_0_o <= {8'h00, decoded_immediate};
            end
          end
          OP_LARP: auxiliary_register_pointer_o <= decoded_immediate[0];
          OP_LDPK: data_page_pointer_o          <= decoded_immediate[0];
          OP_MAR: begin
          end
          OP_NOP:  begin
          end
          OP_DINT: interrupt_mask_o <= 1'b1;
          OP_EINT: interrupt_mask_o <= 1'b0;
          OP_LST: begin
            overflow_flag_o              <= ram_read_data[15];
            overflow_mode_o              <= ram_read_data[14];
            auxiliary_register_pointer_o <= ram_read_data[8];
            data_page_pointer_o          <= ram_read_data[0];
          end
          OP_ZAC:  accumulator_o   <= 32'h0000_0000;
          OP_ROVM: overflow_mode_o <= 1'b0;
          OP_SOVM: overflow_mode_o <= 1'b1;
          OP_BANZ: begin
          end
          OP_B: begin
          end
          default: begin
            // All enum values are covered above.
          end
        endcase

        if (
          ((decoded_operation == OP_LAC) ||
           (decoded_operation == OP_SACL) ||
           (decoded_operation == OP_SACH) ||
           (decoded_operation == OP_ZALH) ||
           (decoded_operation == OP_ZALS) ||
           (decoded_operation == OP_ADDS) ||
           (decoded_operation == OP_XOR) ||
           (decoded_operation == OP_AND) ||
           (decoded_operation == OP_OR) ||
           (decoded_operation == OP_ADD) ||
           (decoded_operation == OP_SUB) ||
           (decoded_operation == OP_SUBS) ||
           (decoded_operation == OP_SUBC) ||
           (decoded_operation == OP_LAR) ||
           (decoded_operation == OP_SAR) ||
           (decoded_operation == OP_MAR) ||
           (decoded_operation == OP_LDP) ||
           (decoded_operation == OP_DMOV) ||
           (decoded_operation == OP_LT) ||
           (decoded_operation == OP_LTD) ||
           (decoded_operation == OP_LTA) ||
           (decoded_operation == OP_MPY) ||
           (decoded_operation == OP_LST)) &&
          decoded_indirect
        ) begin
          if (
            decoded_addressing_field[5] &&
            !(
              (decoded_operation == OP_LAR) &&
              (decoded_auxiliary_register == auxiliary_register_pointer_o)
            )
          ) begin
            if (auxiliary_register_pointer_o) begin
              auxiliary_register_1_o <= {
                auxiliary_register_1_o[15:9],
                auxiliary_register_1_o[8:0] + 9'd1
              };
            end else begin
              auxiliary_register_0_o <= {
                auxiliary_register_0_o[15:9],
                auxiliary_register_0_o[8:0] + 9'd1
              };
            end
          end else if (
            decoded_addressing_field[4] &&
            !(
              (decoded_operation == OP_LAR) &&
              (decoded_auxiliary_register == auxiliary_register_pointer_o)
            )
          ) begin
            if (auxiliary_register_pointer_o) begin
              auxiliary_register_1_o <= {
                auxiliary_register_1_o[15:9],
                auxiliary_register_1_o[8:0] - 9'd1
              };
            end else begin
              auxiliary_register_0_o <= {
                auxiliary_register_0_o[15:9],
                auxiliary_register_0_o[8:0] - 9'd1
              };
            end
          end
          if (
            !decoded_addressing_field[3] &&
            (decoded_operation != OP_LST)
          ) begin
            auxiliary_register_pointer_o <= decoded_addressing_field[0];
          end
        end
      end else begin
        illegal_o <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    assert (!(retired_o && illegal_o));
    if (!reset_i && !initialize_i) begin
      assert (!(debug_data_write_i && clock_enable_i));
      if (branch_operand_pending) begin
        assert (!(data_read_o || data_write_o || data_address_valid_o));
      end
      if ((data_read_o || data_write_o) && !data_address_valid_o) begin
        assert (!instruction_valid_o);
      end
      if (data_write_o && !data_write_address_valid_o) begin
        assert (!instruction_valid_o);
      end
    end
  end
endmodule

`default_nettype wire
