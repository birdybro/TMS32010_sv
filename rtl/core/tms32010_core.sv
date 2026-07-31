`default_nettype none

module tms32010_core (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        reset_i,
  input  logic        clock_enable_i,
  input  logic        bio_i,
  input  logic        int_i,

  output logic [11:0] program_address_o,
  output logic [11:0] program_next_address_o,
  output logic        program_read_o,
  output logic        program_write_o,
  output logic [15:0] program_write_data_o,
  input  logic [15:0] program_data_i,

  output logic [2:0]  io_port_o,
  output logic        io_read_o,
  output logic        io_write_o,
  output logic [15:0] io_write_data_o,
  input  logic [15:0] io_read_data_i,

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
  output logic [11:0] stack_top_o,
  output logic [11:0] stack_level_1_o,
  output logic [11:0] stack_level_2_o,
  output logic [11:0] stack_bottom_o,
  output logic        overflow_flag_o,
  output logic        overflow_mode_o,
  output logic        interrupt_mask_o,
  output logic        interrupt_pending_o,
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
  localparam logic [5:0] OP_BGEZ = 6'd39;
  localparam logic [5:0] OP_BGZ  = 6'd40;
  localparam logic [5:0] OP_BLEZ = 6'd41;
  localparam logic [5:0] OP_BLZ  = 6'd42;
  localparam logic [5:0] OP_BNZ  = 6'd43;
  localparam logic [5:0] OP_BZ   = 6'd44;
  localparam logic [5:0] OP_BV   = 6'd45;
  localparam logic [5:0] OP_BIOZ = 6'd46;
  localparam logic [5:0] OP_CALL = 6'd47;
  localparam logic [5:0] OP_IN   = 6'd48;
  localparam logic [5:0] OP_OUT  = 6'd49;
  localparam logic [5:0] OP_TBLR = 6'd50;
  localparam logic [5:0] OP_TBLW = 6'd51;

  function automatic logic is_two_word_control_flow(input logic [5:0] operation);
    case (operation)
      OP_B,
      OP_BANZ,
      OP_BV,
      OP_BIOZ,
      OP_CALL,
      OP_BGEZ,
      OP_BGZ,
      OP_BLEZ,
      OP_BLZ,
      OP_BNZ,
      OP_BZ: is_two_word_control_flow = 1'b1;
      default: is_two_word_control_flow = 1'b0;
    endcase
  endfunction

  function automatic logic accumulator_branch_taken(
    input logic [5:0]  operation,
    input logic [31:0] accumulator
  );
    case (operation)
      OP_BGEZ: accumulator_branch_taken = ~accumulator[31];
      OP_BGZ:  accumulator_branch_taken =
        ~accumulator[31] && (accumulator != 32'h0000_0000);
      OP_BLEZ: accumulator_branch_taken =
        accumulator[31] || (accumulator == 32'h0000_0000);
      OP_BLZ: accumulator_branch_taken = accumulator[31];
      OP_BNZ: accumulator_branch_taken =
        accumulator != 32'h0000_0000;
      OP_BZ: accumulator_branch_taken =
        accumulator == 32'h0000_0000;
      default: accumulator_branch_taken = 1'b0;
    endcase
  endfunction

  function automatic logic extends_interrupt_deferral(
    input logic [5:0] operation
  );
    case (operation)
      OP_MPY,
      OP_MPYK: extends_interrupt_deferral = 1'b1;
      default: extends_interrupt_deferral = 1'b0;
    endcase
  endfunction

  logic [5:0] decoded_operation;
  logic [7:0] decoded_immediate;
  logic [12:0] decoded_immediate_13;
  logic       decoded_auxiliary_register;
  logic [3:0] decoded_shift;
  logic [2:0] decoded_port;
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
  logic        control_operand_pending;
  logic [5:0]  pending_control_operation;
  logic        io_pending;
  logic [5:0]  pending_io_operation;
  logic [2:0]  pending_io_port;
  logic [7:0]  pending_io_data_address;
  logic        pending_io_indirect;
  logic        pending_io_selected_arp;
  logic        pending_io_increment;
  logic        pending_io_decrement;
  logic        pending_io_preserve_arp;
  logic        pending_io_next_arp;
  logic        table_pending;
  logic        table_transfer_phase;
  logic [5:0]  pending_table_operation;
  logic [11:0] pending_table_program_address;
  logic [7:0]  pending_table_data_address;
  logic        pending_table_indirect;
  logic        pending_table_selected_arp;
  logic        pending_table_increment;
  logic        pending_table_decrement;
  logic        pending_table_preserve_arp;
  logic        pending_table_next_arp;
  logic        interrupt_delay_one;
  logic        interrupt_entry_pending;
  logic        retirement_boundary;
  logic [5:0]  retiring_operation;
  logic        retiring_interrupt_mask;

  tms32010_decode decode (
    .instruction_i (program_data_i),
    .valid_o       (decoded_valid),
    .operation_o   (decoded_operation),
    .immediate_o   (decoded_immediate),
    .immediate_13_o (decoded_immediate_13),
    .auxiliary_register_o (decoded_auxiliary_register),
    .shift_o       (decoded_shift),
    .port_o        (decoded_port),
    .indirect_o    (decoded_indirect),
    .addressing_field_o (decoded_addressing_field)
  );

  always_comb begin
    data_address_o = 8'h00;
    if (interrupt_entry_pending) begin
      data_address_o = 8'h00;
    end else if (table_pending) begin
      data_address_o = pending_table_data_address;
    end else if (io_pending) begin
      data_address_o = pending_io_data_address;
    end else if (
      !control_operand_pending &&
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
        (decoded_operation == OP_LST) ||
        (decoded_operation == OP_IN) ||
        (decoded_operation == OP_OUT) ||
        (decoded_operation == OP_TBLR) ||
        (decoded_operation == OP_TBLW)
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

  assign program_address_o =
    table_pending && table_transfer_phase && !interrupt_entry_pending
      ? pending_table_program_address
      : pc_o;
  always_comb begin
    program_next_address_o = pc_o;
    if (interrupt_entry_pending) begin
      program_next_address_o = 12'h002;
    end else if (control_operand_pending) begin
      if (program_data_i[15:12] == 4'h0) begin
        case (pending_control_operation)
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
          OP_BV: begin
            program_next_address_o = overflow_flag_o
              ? program_data_i[11:0]
              : pc_o + 12'h001;
          end
          OP_BIOZ: begin
            program_next_address_o = !bio_i
              ? program_data_i[11:0]
              : pc_o + 12'h001;
          end
          OP_CALL: begin
            program_next_address_o = program_data_i[11:0];
          end
          OP_BGEZ,
          OP_BGZ,
          OP_BLEZ,
          OP_BLZ,
          OP_BNZ,
          OP_BZ: begin
            program_next_address_o =
              accumulator_branch_taken(
                pending_control_operation,
                accumulator_o
              )
                ? program_data_i[11:0]
                : pc_o + 12'h001;
          end
          default: begin
          end
        endcase
      end
    end else if (io_pending || table_pending) begin
      // The program prefetch address already points at PC while the physical
      // address pins may carry an I/O port or table address.
    end else if (instruction_valid_o) begin
      program_next_address_o = pc_o + 12'h001;
    end
  end
  assign program_read_o =
    ~reset_i &&
    ~initialize_i &&
    ~io_pending &&
    !(
      table_pending &&
      table_transfer_phase &&
      (pending_table_operation == OP_TBLW)
    );
  assign program_write_o =
    ~reset_i &&
    ~initialize_i &&
    ~interrupt_entry_pending &&
    table_pending &&
    table_transfer_phase &&
    (pending_table_operation == OP_TBLW);
  assign program_write_data_o = ram_read_data;
  assign io_port_o = pending_io_port;
  assign io_read_o =
    ~reset_i &&
    ~initialize_i &&
    ~interrupt_entry_pending &&
    io_pending &&
    (pending_io_operation == OP_IN);
  assign io_write_o =
    ~reset_i &&
    ~initialize_i &&
    ~interrupt_entry_pending &&
    io_pending &&
    (pending_io_operation == OP_OUT);
  assign io_write_data_o = ram_read_data;
  assign data_read_o =
    ~reset_i &&
    ~initialize_i &&
    ~interrupt_entry_pending &&
    (
      (
        io_pending &&
        (pending_io_operation == OP_OUT)
      ) ||
      (
        table_pending &&
        table_transfer_phase &&
        (pending_table_operation == OP_TBLW)
      ) ||
      (
        ~table_pending &&
        ~io_pending &&
        ~control_operand_pending &&
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
        )
      )
    );
  assign data_write_o =
    ~reset_i &&
    ~initialize_i &&
    ~interrupt_entry_pending &&
    (
      (
        io_pending &&
        (pending_io_operation == OP_IN)
      ) ||
      (
        table_pending &&
        table_transfer_phase &&
        (pending_table_operation == OP_TBLR)
      ) ||
      (
        ~table_pending &&
        ~io_pending &&
        ~control_operand_pending &&
        decoded_valid &&
        (
          (decoded_operation == OP_SACL) ||
          (decoded_operation == OP_SACH) ||
          (decoded_operation == OP_SAR) ||
          (decoded_operation == OP_DMOV) ||
          (decoded_operation == OP_LTD)
        )
      )
    );
  assign data_address_valid_o =
    (data_read_o || data_write_o) && ram_address_valid;
  always_comb begin
    data_write_address_o = data_address_o;
    if (
      !io_pending &&
      !table_pending &&
      (
        (decoded_operation == OP_DMOV) ||
        (decoded_operation == OP_LTD)
      )
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
      table_pending &&
      table_transfer_phase &&
      (pending_table_operation == OP_TBLR)
    ) begin
      data_write_data_o = program_data_i;
    end else if (io_pending) begin
      data_write_data_o = io_read_data_i;
    end else if (
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
    if (interrupt_entry_pending) begin
      instruction_valid_o = 1'b0;
    end else if (control_operand_pending) begin
      instruction_valid_o =
        (program_data_i[15:12] == 4'h0) &&
        is_two_word_control_flow(pending_control_operation);
    end else if (table_pending) begin
      instruction_valid_o =
        !table_transfer_phase ||
        (
          ram_address_valid &&
          (
            (pending_table_operation == OP_TBLR) ||
            (pending_table_operation == OP_TBLW)
          )
        );
    end else if (io_pending) begin
      instruction_valid_o =
        ram_address_valid &&
        (
          (pending_io_operation == OP_IN) ||
          (pending_io_operation == OP_OUT)
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
            (decoded_operation != OP_LST) &&
            (decoded_operation != OP_IN) &&
            (decoded_operation != OP_OUT) &&
            (decoded_operation != OP_TBLR) &&
            (decoded_operation != OP_TBLW)
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

  always_comb begin
    retirement_boundary = 1'b0;
    retiring_operation = decoded_operation;
    if (!interrupt_entry_pending) begin
      if (control_operand_pending) begin
        retiring_operation = pending_control_operation;
        retirement_boundary = instruction_valid_o;
      end else if (table_pending) begin
        retiring_operation = pending_table_operation;
        retirement_boundary =
          table_transfer_phase && instruction_valid_o;
      end else if (io_pending) begin
        retiring_operation = pending_io_operation;
        retirement_boundary = instruction_valid_o;
      end else if (
        instruction_valid_o &&
        !is_two_word_control_flow(decoded_operation) &&
        (decoded_operation != OP_IN) &&
        (decoded_operation != OP_OUT) &&
        (decoded_operation != OP_TBLR) &&
        (decoded_operation != OP_TBLW)
      ) begin
        retirement_boundary = 1'b1;
      end
    end

    retiring_interrupt_mask = interrupt_mask_o;
    if (retirement_boundary) begin
      case (retiring_operation)
        OP_DINT: retiring_interrupt_mask = 1'b1;
        OP_EINT: retiring_interrupt_mask = 1'b0;
        default: begin
        end
      endcase
    end
  end

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
      stack_top_o                   <= 12'h000;
      stack_level_1_o               <= 12'h000;
      stack_level_2_o               <= 12'h000;
      stack_bottom_o                <= 12'h000;
      overflow_flag_o              <= 1'b0;
      overflow_mode_o              <= 1'b0;
      interrupt_mask_o             <= 1'b1;
      interrupt_pending_o          <= 1'b0;
      interrupt_delay_one          <= 1'b0;
      interrupt_entry_pending      <= 1'b0;
      illegal_o                    <= 1'b0;
      cycle_count_o                <= 32'h0000_0000;
      control_operand_pending       <= 1'b0;
      pending_control_operation     <= OP_B;
      io_pending                    <= 1'b0;
      pending_io_operation          <= OP_IN;
      pending_io_port               <= 3'h0;
      pending_io_data_address       <= 8'h00;
      pending_io_indirect           <= 1'b0;
      pending_io_selected_arp       <= 1'b0;
      pending_io_increment          <= 1'b0;
      pending_io_decrement          <= 1'b0;
      pending_io_preserve_arp       <= 1'b1;
      pending_io_next_arp           <= 1'b0;
      table_pending                 <= 1'b0;
      table_transfer_phase          <= 1'b0;
      pending_table_operation       <= OP_TBLR;
      pending_table_program_address <= 12'h000;
      pending_table_data_address    <= 8'h00;
      pending_table_indirect        <= 1'b0;
      pending_table_selected_arp    <= 1'b0;
      pending_table_increment       <= 1'b0;
      pending_table_decrement       <= 1'b0;
      pending_table_preserve_arp    <= 1'b1;
      pending_table_next_arp        <= 1'b0;
    end else if (reset_i) begin
      pc_o             <= 12'h000;
      interrupt_mask_o <= 1'b1;
      interrupt_pending_o     <= 1'b0;
      interrupt_delay_one     <= 1'b0;
      interrupt_entry_pending <= 1'b0;
      illegal_o        <= 1'b0;
      cycle_count_o    <= 32'h0000_0000;
      control_operand_pending   <= 1'b0;
      pending_control_operation <= OP_B;
      io_pending                  <= 1'b0;
      pending_io_operation        <= OP_IN;
      pending_io_port             <= 3'h0;
      pending_io_data_address     <= 8'h00;
      pending_io_indirect         <= 1'b0;
      pending_io_selected_arp     <= 1'b0;
      pending_io_increment        <= 1'b0;
      pending_io_decrement        <= 1'b0;
      pending_io_preserve_arp     <= 1'b1;
      pending_io_next_arp         <= 1'b0;
      table_pending                 <= 1'b0;
      table_transfer_phase          <= 1'b0;
      pending_table_operation       <= OP_TBLR;
      pending_table_program_address <= 12'h000;
      pending_table_data_address    <= 8'h00;
      pending_table_indirect        <= 1'b0;
      pending_table_selected_arp    <= 1'b0;
      pending_table_increment       <= 1'b0;
      pending_table_decrement       <= 1'b0;
      pending_table_preserve_arp    <= 1'b1;
      pending_table_next_arp        <= 1'b0;
      // ACC, T, P, AR0, AR1, ARP, DP, stack, and OV receive no arbitrary
      // reset value.
      // TI explicitly documents that reset leaves OVM unchanged. Retention of
      // the other unlisted state is an implementation policy under OQ-012.
    end else if (clock_enable_i) begin
      if (interrupt_entry_pending) begin
        stack_top_o              <= pc_o;
        stack_level_1_o          <= stack_top_o;
        stack_level_2_o          <= stack_level_1_o;
        stack_bottom_o           <= stack_level_2_o;
        pc_o                     <= 12'h002;
        interrupt_mask_o         <= 1'b1;
        interrupt_pending_o      <= 1'b0;
        interrupt_delay_one      <= 1'b0;
        interrupt_entry_pending  <= 1'b0;
        illegal_o                <= 1'b0;
        cycle_count_o            <= cycle_count_o + 32'h0000_0001;
      end else if (control_operand_pending) begin
        if (instruction_valid_o) begin
          case (pending_control_operation)
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
            OP_BV: begin
              pc_o <= overflow_flag_o
                ? program_data_i[11:0]
                : pc_o + 12'h001;
              if (overflow_flag_o) begin
                overflow_flag_o <= 1'b0;
              end
            end
            OP_BIOZ: begin
              pc_o <= !bio_i
                ? program_data_i[11:0]
                : pc_o + 12'h001;
            end
            OP_CALL: begin
              pc_o            <= program_data_i[11:0];
              stack_top_o     <= pc_o + 12'h001;
              stack_level_1_o <= stack_top_o;
              stack_level_2_o <= stack_level_1_o;
              stack_bottom_o  <= stack_level_2_o;
            end
            OP_BGEZ,
            OP_BGZ,
            OP_BLEZ,
            OP_BLZ,
            OP_BNZ,
            OP_BZ: begin
              pc_o <=
                accumulator_branch_taken(
                  pending_control_operation,
                  accumulator_o
                )
                  ? program_data_i[11:0]
                  : pc_o + 12'h001;
            end
            default: begin
            end
          endcase
          control_operand_pending <= 1'b0;
          retired_o              <= 1'b1;
          illegal_o              <= 1'b0;
          cycle_count_o          <= cycle_count_o + 32'h0000_0001;
        end else begin
          illegal_o <= 1'b1;
        end
      end else if (table_pending) begin
        if (instruction_valid_o) begin
          if (!table_transfer_phase) begin
            table_transfer_phase <= 1'b1;
            illegal_o            <= 1'b0;
            cycle_count_o        <= cycle_count_o + 32'h0000_0001;
          end else begin
            if (pending_table_indirect) begin
              if (pending_table_increment) begin
                if (pending_table_selected_arp) begin
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
              end else if (pending_table_decrement) begin
                if (pending_table_selected_arp) begin
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
              if (!pending_table_preserve_arp) begin
                auxiliary_register_pointer_o <= pending_table_next_arp;
              end
            end
            // TI's documented temporary push/pop discards the old bottom
            // entry and duplicates the old level-2 entry into that position.
            stack_bottom_o       <= stack_level_2_o;
            table_pending        <= 1'b0;
            table_transfer_phase <= 1'b0;
            retired_o            <= 1'b1;
            illegal_o            <= 1'b0;
            cycle_count_o        <= cycle_count_o + 32'h0000_0001;
          end
        end else begin
          illegal_o <= 1'b1;
        end
      end else if (io_pending) begin
        if (instruction_valid_o) begin
          if (pending_io_indirect) begin
            if (pending_io_increment) begin
              if (pending_io_selected_arp) begin
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
            end else if (pending_io_decrement) begin
              if (pending_io_selected_arp) begin
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
            if (!pending_io_preserve_arp) begin
              auxiliary_register_pointer_o <=
                pending_io_next_arp;
            end
          end
          io_pending   <= 1'b0;
          retired_o    <= 1'b1;
          illegal_o    <= 1'b0;
          cycle_count_o <= cycle_count_o + 32'h0000_0001;
        end else begin
          illegal_o <= 1'b1;
        end
      end else if (instruction_valid_o) begin
        pc_o          <= pc_o + 12'h001;
        illegal_o     <= 1'b0;
        cycle_count_o <= cycle_count_o + 32'h0000_0001;
        if (is_two_word_control_flow(decoded_operation)) begin
          control_operand_pending   <= 1'b1;
          pending_control_operation <= decoded_operation;
        end else if (
          (decoded_operation == OP_IN) ||
          (decoded_operation == OP_OUT)
        ) begin
          io_pending                  <= 1'b1;
          pending_io_operation        <= decoded_operation;
          pending_io_port             <= decoded_port;
          pending_io_data_address     <= data_address_o;
          pending_io_indirect         <= decoded_indirect;
          pending_io_selected_arp     <= auxiliary_register_pointer_o;
          pending_io_increment        <= decoded_addressing_field[5];
          pending_io_decrement        <= decoded_addressing_field[4];
          pending_io_preserve_arp     <= decoded_addressing_field[3];
          pending_io_next_arp         <= decoded_addressing_field[0];
        end else if (
          (decoded_operation == OP_TBLR) ||
          (decoded_operation == OP_TBLW)
        ) begin
          table_pending                 <= 1'b1;
          table_transfer_phase          <= 1'b0;
          pending_table_operation       <= decoded_operation;
          pending_table_program_address <= accumulator_o[11:0];
          pending_table_data_address    <= data_address_o;
          pending_table_indirect        <= decoded_indirect;
          pending_table_selected_arp    <= auxiliary_register_pointer_o;
          pending_table_increment       <= decoded_addressing_field[5];
          pending_table_decrement       <= decoded_addressing_field[4];
          pending_table_preserve_arp    <= decoded_addressing_field[3];
          pending_table_next_arp        <= decoded_addressing_field[0];
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
          OP_BV: begin
          end
          OP_BIOZ: begin
          end
          OP_CALL: begin
          end
          OP_IN: begin
          end
          OP_OUT: begin
          end
          OP_TBLR: begin
          end
          OP_TBLW: begin
          end
          OP_BGEZ: begin
          end
          OP_BGZ: begin
          end
          OP_BLEZ: begin
          end
          OP_BLZ: begin
          end
          OP_BNZ: begin
          end
          OP_BZ: begin
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

      if (!interrupt_entry_pending) begin
        if (!int_i) begin
          interrupt_pending_o <= 1'b1;
        end
        if (retirement_boundary) begin
          if (interrupt_delay_one) begin
            if (retiring_interrupt_mask) begin
              // DINT in the protected slot cancels entry without clearing
              // the internally latched request.
              interrupt_delay_one <= 1'b0;
            end else if (extends_interrupt_deferral(retiring_operation)) begin
              interrupt_delay_one <= 1'b1;
            end else begin
              interrupt_delay_one     <= 1'b0;
              interrupt_entry_pending <= 1'b1;
            end
          end else if (
            (interrupt_pending_o || !int_i) &&
            !retiring_interrupt_mask
          ) begin
            // The already-pipelined instruction following the detected
            // request must retire before the dummy return-address fetch.
            interrupt_delay_one <= 1'b1;
          end
        end
      end
    end
  end

  always_ff @(posedge clk_i) begin
    assert (!(retired_o && illegal_o));
    if (!reset_i && !initialize_i) begin
      assert (!(debug_data_write_i && clock_enable_i));
      if (control_operand_pending) begin
        assert (!(
          data_read_o ||
          data_write_o ||
          data_address_valid_o ||
          io_read_o ||
          io_write_o
        ));
      end
      if (io_pending) begin
        assert (!program_read_o);
        assert (!program_write_o);
        assert (io_read_o != io_write_o);
      end
      if (table_pending) begin
        assert (!(io_read_o || io_write_o));
        assert (!(program_read_o && program_write_o));
        if (!table_transfer_phase) begin
          assert (program_read_o && !program_write_o);
        end
      end
      if (interrupt_entry_pending) begin
        assert (program_read_o && !program_write_o);
        assert (!instruction_valid_o);
        assert (!(data_read_o || data_write_o || io_read_o || io_write_o));
        assert (program_address_o == pc_o);
        assert (program_next_address_o == 12'h002);
      end
      assert (!(io_read_o && io_write_o));
      assert (!(program_read_o && program_write_o));
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
