`default_nettype none

// Original-part 144 x 16-bit internal data RAM. The selectable read latency is
// an implementation boundary for the standalone and phase-aware slices; it
// does not represent an external TMS32010 bus or an electrical timing claim.
module tms32010_internal_ram #(
  // The phase-aware wrapper may capture the internal operand ahead of its
  // architectural execution boundary so FPGA block RAM can be inferred.
  // The standalone core keeps the combinational-read default.
  parameter bit REGISTERED_READ = 1'b0
) (
  input  logic        clk_i,
  // Registered mode advances its read-side capture only on this enable.
  // Writes retain their existing independent architectural/debug controls.
  // The async generate branch deliberately elaborates without a consumer.
  /* verilator lint_off UNUSEDSIGNAL */
  input  logic        read_enable_i,
  /* verilator lint_on UNUSEDSIGNAL */
  input  logic [7:0]  read_address_i,
  output logic [15:0] read_data_o,
  output logic        read_address_valid_o,
  input  logic        write_i,
  input  logic [7:0]  write_address_i,
  output logic        write_address_valid_o,
  input  logic [15:0] write_data_i,

  // Explicit, nonarchitectural preload/debug port. Physical reset never
  // initializes this memory, and normal CPU execution must not use this port.
  input  logic        debug_write_i,
  input  logic [7:0]  debug_address_i,
  input  logic [15:0] debug_data_i
);
  logic [15:0] memory [0:143];

  assign read_address_valid_o  = read_address_i < 8'd144;
  assign write_address_valid_o = write_address_i < 8'd144;

  generate
    if (REGISTERED_READ) begin : registered_read
      logic        captured_read_valid;
      logic [15:0] captured_read_data;
      logic        captured_forward_valid;
      logic [15:0] captured_forward_data;
      logic [7:0]  qualified_read_address;

      assign read_data_o =
        captured_read_valid
          ? (
            captured_forward_valid
              ? captured_forward_data
              : captured_read_data
          )
          : 16'h0000;
      assign qualified_read_address =
        read_address_valid_o ? read_address_i : 8'h00;

      // Keep the write and synchronous read in the same clocked process.
      // This is the portable old-data read-during-write template recognized
      // by both open-source and FPGA-vendor memory inference flows.
      always_ff @(posedge clk_i) begin
        if (debug_write_i && (debug_address_i < 8'd144)) begin
          memory[debug_address_i] <= debug_data_i;
        end else if (write_i && write_address_valid_o) begin
          memory[write_address_i] <= write_data_i;
        end
        if (read_enable_i) begin
          captured_read_valid <= read_address_valid_o;
          captured_read_data  <= memory[qualified_read_address];
          captured_forward_valid <=
            (
              debug_write_i &&
              (debug_address_i < 8'd144) &&
              (debug_address_i == qualified_read_address)
            ) || (
              write_i &&
              write_address_valid_o &&
              (write_address_i == qualified_read_address)
            );
          if (
            debug_write_i &&
            (debug_address_i < 8'd144) &&
            (debug_address_i == qualified_read_address)
          ) begin
            captured_forward_data <= debug_data_i;
          end else begin
            // The inferred memory itself may return old data. This registered
            // bypass makes a just-committed word available to the next execute
            // owner during its phase-zero setup interval.
            captured_forward_data <= write_data_i;
          end
        end
      end
    end else begin : asynchronous_read
      always_comb begin
        read_data_o = 16'h0000;
        if (read_address_valid_o) begin
          read_data_o = memory[read_address_i];
        end
      end

      always_ff @(posedge clk_i) begin
        if (debug_write_i && (debug_address_i < 8'd144)) begin
          memory[debug_address_i] <= debug_data_i;
        end else if (write_i && write_address_valid_o) begin
          memory[write_address_i] <= write_data_i;
        end
      end
    end
  endgenerate

  always_ff @(posedge clk_i) begin
    assert (!(write_i && !write_address_valid_o));
    assert (!(debug_write_i && (debug_address_i >= 8'd144)));
    assert (!(write_i && debug_write_i));
  end
endmodule

`default_nettype wire
