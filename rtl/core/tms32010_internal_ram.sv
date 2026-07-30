`default_nettype none

// Original-part 144 x 16-bit internal data RAM. The asynchronous read is an
// implementation boundary for the current one-cycle execution slice; it does
// not represent an external TMS32010 bus or an electrical timing claim.
module tms32010_internal_ram (
  input  logic        clk_i,
  input  logic [7:0]  address_i,
  output logic [15:0] read_data_o,
  output logic        address_valid_o,

  // Explicit, nonarchitectural preload/debug port. Physical reset never
  // initializes this memory, and normal CPU execution must not use this port.
  input  logic        debug_write_i,
  input  logic [7:0]  debug_address_i,
  input  logic [15:0] debug_data_i
);
  logic [15:0] memory [0:143];

  always_comb begin
    address_valid_o = address_i < 8'd144;
    read_data_o     = 16'h0000;
    if (address_valid_o) begin
      read_data_o = memory[address_i];
    end
  end

  always_ff @(posedge clk_i) begin
    if (debug_write_i && (debug_address_i < 8'd144)) begin
      memory[debug_address_i] <= debug_data_i;
    end
    assert (!(debug_write_i && (debug_address_i >= 8'd144)));
  end
endmodule

`default_nettype wire
