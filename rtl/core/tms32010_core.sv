`default_nettype none

module tms32010_core (
  input  logic        clk_i,
  input  logic        reset_i,
  input  logic        clock_enable_i,

  output logic [11:0] program_address_o,
  output logic        program_read_o,
  input  logic [15:0] program_data_i,

  output logic [11:0] pc_o,
  output logic [31:0] accumulator_o,
  output logic [15:0] auxiliary_register_0_o,
  output logic [15:0] auxiliary_register_1_o,
  output logic        auxiliary_register_pointer_o,
  output logic        data_page_pointer_o,
  output logic        overflow_mode_o,
  output logic        interrupt_mask_o,
  output logic        instruction_valid_o,
  output logic        retired_o,
  output logic        illegal_o,
  output logic [31:0] cycle_count_o
);
  // Yosys 0.33 cannot import the operation enum package. These encodings are
  // checked against tms32010_pkg through the exhaustive decoder regression.
  localparam logic [3:0] OP_LACK = 4'd0;
  localparam logic [3:0] OP_NOP  = 4'd1;
  localparam logic [3:0] OP_ZAC  = 4'd2;
  localparam logic [3:0] OP_ROVM = 4'd3;
  localparam logic [3:0] OP_SOVM = 4'd4;
  localparam logic [3:0] OP_LARK = 4'd5;
  localparam logic [3:0] OP_LARP = 4'd6;
  localparam logic [3:0] OP_LDPK = 4'd7;

  logic [3:0] decoded_operation;
  logic [7:0] decoded_immediate;
  logic       decoded_auxiliary_register;

  tms32010_decode decode (
    .instruction_i (program_data_i),
    .valid_o       (instruction_valid_o),
    .operation_o   (decoded_operation),
    .immediate_o   (decoded_immediate),
    .auxiliary_register_o (decoded_auxiliary_register)
  );

  assign program_address_o = pc_o;
  assign program_read_o    = ~reset_i;

  always_ff @(posedge clk_i) begin
    retired_o <= 1'b0;

    if (reset_i) begin
      pc_o             <= 12'h000;
      interrupt_mask_o <= 1'b1;
      illegal_o        <= 1'b0;
      cycle_count_o    <= 32'h0000_0000;
      // ACC, AR0, AR1, ARP, DP, and OVM have no arbitrary reset value here.
      // In particular, TI documents that reset leaves OVM unchanged.
    end else if (clock_enable_i) begin
      if (instruction_valid_o) begin
        pc_o          <= pc_o + 12'h001;
        retired_o     <= 1'b1;
        illegal_o     <= 1'b0;
        cycle_count_o <= cycle_count_o + 32'h0000_0001;

        case (decoded_operation)
          OP_LACK: accumulator_o   <= {24'h000000, decoded_immediate};
          OP_LARK: begin
            if (decoded_auxiliary_register) begin
              auxiliary_register_1_o <= {8'h00, decoded_immediate};
            end else begin
              auxiliary_register_0_o <= {8'h00, decoded_immediate};
            end
          end
          OP_LARP: auxiliary_register_pointer_o <= decoded_immediate[0];
          OP_LDPK: data_page_pointer_o          <= decoded_immediate[0];
          OP_NOP:  begin
          end
          OP_ZAC:  accumulator_o   <= 32'h0000_0000;
          OP_ROVM: overflow_mode_o <= 1'b0;
          OP_SOVM: overflow_mode_o <= 1'b1;
          default: begin
            // All enum values are covered above.
          end
        endcase
      end else begin
        illegal_o <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    assert (!(retired_o && illegal_o));
  end
endmodule

`default_nettype wire
