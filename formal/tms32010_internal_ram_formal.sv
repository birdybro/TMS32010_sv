`default_nettype none

// RTL-001/BUS-002 proof for the portable 144-word internal-RAM block.
// The watched address is symbolic, so one proof covers every qualified word.
// Initial contents remain arbitrary, matching the absence of a RAM reset.
module tms32010_internal_ram_formal (
  input logic        clk_i,
  input logic [7:0]  read_address_i,
  input logic [7:0]  write_address_i,
  input logic        write_i,
  input logic [15:0] write_data_i,
  input logic [7:0]  debug_address_i,
  input logic        debug_write_i,
  input logic [15:0] debug_data_i
);
  (* anyconst *) logic [7:0] watched_address;

  logic [15:0] watched_read_data;
  logic        watched_read_valid;
  logic        watched_write_valid;
  logic [15:0] arbitrary_read_data;
  logic        arbitrary_read_valid;
  logic        arbitrary_write_valid;
  logic        past_valid = 1'b0;

  // Storage instance: arbitrary legal CPU and debug writes exercise one
  // symbolic physical word while every other word is observationally hidden.
  tms32010_internal_ram storage_dut (
    .clk_i                  (clk_i),
    .read_enable_i          (1'b1),
    .read_address_i         (watched_address),
    .read_data_o            (watched_read_data),
    .read_address_valid_o   (watched_read_valid),
    .write_i                (write_i),
    .write_address_i        (write_address_i),
    .write_address_valid_o  (watched_write_valid),
    .write_data_i           (write_data_i),
    .debug_write_i          (debug_write_i),
    .debug_address_i        (debug_address_i),
    .debug_data_i           (debug_data_i)
  );

  // Validity instance: inactive write controls let both address fields range
  // over all 256 values without violating the block's active-write contract.
  tms32010_internal_ram validity_dut (
    .clk_i                  (clk_i),
    .read_enable_i          (1'b1),
    .read_address_i         (read_address_i),
    .read_data_o            (arbitrary_read_data),
    .read_address_valid_o   (arbitrary_read_valid),
    .write_i                (1'b0),
    .write_address_i        (write_address_i),
    .write_address_valid_o  (arbitrary_write_valid),
    .write_data_i           (16'h0000),
    .debug_write_i          (1'b0),
    .debug_address_i        (debug_address_i),
    .debug_data_i           (16'h0000)
  );

  always_comb begin
    // These are the architectural-core/debug-port interface preconditions,
    // not assumptions about the contents of RAM.
    assume (watched_address < 8'd144);
    assume (!write_i || (write_address_i < 8'd144));
    assume (!debug_write_i || (debug_address_i < 8'd144));
    assume (!(write_i && debug_write_i));

    assert (watched_read_valid);
    assert (watched_write_valid == (write_address_i < 8'd144));
    assert (arbitrary_read_valid == (read_address_i < 8'd144));
    assert (arbitrary_write_valid == (write_address_i < 8'd144));

    if (!arbitrary_read_valid) begin
      assert (arbitrary_read_data == 16'h0000);
    end
  end

  always_ff @(posedge clk_i) begin
    past_valid <= 1'b1;

    if (past_valid) begin
      if ($past(debug_write_i) &&
          ($past(debug_address_i) == watched_address)) begin
        assert (watched_read_data == $past(debug_data_i));
      end else if ($past(write_i) &&
                   ($past(write_address_i) == watched_address)) begin
        assert (watched_read_data == $past(write_data_i));
      end else begin
        assert (watched_read_data == $past(watched_read_data));
      end
    end

    // Covers independently demonstrate each qualified boundary and the
    // invalid-address observation policy without assigning silicon behavior.
    cover (
      past_valid &&
      (watched_address == 8'h00) &&
      $past(write_i) &&
      ($past(write_address_i) == watched_address) &&
      (watched_read_data == $past(write_data_i))
    );
    cover (
      past_valid &&
      (watched_address == 8'h8f) &&
      $past(debug_write_i) &&
      ($past(debug_address_i) == watched_address) &&
      (watched_read_data == $past(debug_data_i))
    );
    cover (
      past_valid &&
      $past(write_i) &&
      ($past(write_address_i) != watched_address) &&
      (watched_read_data == $past(watched_read_data))
    );
    cover (
      (read_address_i == 8'h90) &&
      !arbitrary_read_valid &&
      (arbitrary_read_data == 16'h0000)
    );
    cover (
      (read_address_i == 8'hff) &&
      !arbitrary_read_valid &&
      (arbitrary_read_data == 16'h0000)
    );
  end
endmodule

`default_nettype wire
