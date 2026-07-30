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
  output logic        overflow_mode_o,
  output logic        interrupt_mask_o,
  output logic        retired_o,
  output logic        illegal_o,
  output logic [31:0] cycle_count_o
);
  import tms32010_pkg::*;

  logic                 decoded_valid;
  tms32010_operation_t  decoded_operation;
  logic [7:0]           decoded_immediate;

  tms32010_decode decode (
    .instruction_i (program_data_i),
    .valid_o       (decoded_valid),
    .operation_o   (decoded_operation),
    .immediate_o   (decoded_immediate)
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
      // ACC and OVM have no arbitrary reset value here. In particular, TI
      // documents that reset leaves OVM unchanged.
    end else if (clock_enable_i) begin
      if (decoded_valid) begin
        pc_o          <= pc_o + 12'h001;
        retired_o     <= 1'b1;
        illegal_o     <= 1'b0;
        cycle_count_o <= cycle_count_o + 32'h0000_0001;

        case (decoded_operation)
          OP_LACK: accumulator_o   <= {24'h000000, decoded_immediate};
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
    assert (!(retired_o && illegal_o))
      else $error("instruction cannot retire and trap simultaneously");
  end
endmodule

`default_nettype wire
