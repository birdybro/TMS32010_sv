`default_nettype none

// ADR-0004 proof for the phase-staged internal-RAM mode. A symbolic fixed
// address covers all 144 words while the contents remain unconstrained.
module tms32010_internal_ram_registered_formal (
  input logic        clk_i,
  input logic        read_enable_i,
  input logic [7:0]  write_address_i,
  input logic        write_i,
  input logic [15:0] write_data_i,
  input logic [7:0]  debug_address_i,
  input logic        debug_write_i,
  input logic [15:0] debug_data_i
);
  (* anyconst *) logic [7:0] watched_address;

  logic [15:0] read_data;
  logic        read_address_valid;
  logic        write_address_valid;
  logic        past_valid = 1'b0;
  logic        settled_valid = 1'b0;
  logic        prior_read_enabled = 1'b0;

  tms32010_internal_ram #(
    .REGISTERED_READ (1'b1)
  ) dut (
    .clk_i                  (clk_i),
    .read_enable_i          (read_enable_i),
    .read_address_i         (watched_address),
    .read_data_o            (read_data),
    .read_address_valid_o   (read_address_valid),
    .write_i                (write_i),
    .write_address_i        (write_address_i),
    .write_address_valid_o  (write_address_valid),
    .write_data_i           (write_data_i),
    .debug_write_i          (debug_write_i),
    .debug_address_i        (debug_address_i),
    .debug_data_i           (debug_data_i)
  );

  always_comb begin
    assume (watched_address < 8'd144);
    assume (!write_i || (write_address_i < 8'd144));
    assume (!debug_write_i || (debug_address_i < 8'd144));
    assume (!(write_i && debug_write_i));

    assert (read_address_valid);
    assert (write_address_valid == (write_address_i < 8'd144));
  end

  always_ff @(posedge clk_i) begin
    past_valid    <= 1'b1;
    settled_valid <= past_valid;
    prior_read_enabled <= read_enable_i;

    if (past_valid) begin
      if (!$past(read_enable_i)) begin
        assert (read_data == $past(read_data));
      end else if (
        $past(debug_write_i) &&
        ($past(debug_address_i) == watched_address)
      ) begin
        assert (read_data == $past(debug_data_i));
      end else if (
        $past(write_i) &&
        ($past(write_address_i) == watched_address)
      ) begin
        assert (read_data == $past(write_data_i));
      end else if (
        settled_valid &&
        $past(prior_read_enabled)
      ) begin
        assert (read_data == $past(read_data));
      end
    end

    cover (
      past_valid &&
      $past(read_enable_i) &&
      (watched_address == 8'h00) &&
      $past(write_i) &&
      ($past(write_address_i) == watched_address) &&
      (read_data == $past(write_data_i))
    );
    cover (
      past_valid &&
      $past(read_enable_i) &&
      (watched_address == 8'h8f) &&
      $past(debug_write_i) &&
      ($past(debug_address_i) == watched_address) &&
      (read_data == $past(debug_data_i))
    );
    cover (
      settled_valid &&
      !$past(read_enable_i) &&
      !$past(write_i) &&
      !$past(debug_write_i) &&
      (read_data == $past(read_data))
    );
  end
endmodule

`default_nettype wire
