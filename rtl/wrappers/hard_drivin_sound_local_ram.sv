`default_nettype none

// Same-clock FPGA storage boundary for A044427's two 6264 byte-wide SRAMs.
// The data arrays are intentionally never reset. A sequential metadata scrub
// makes unwritten FPGA contents explicitly invalid without requiring a reset
// on either inferred data memory or silently assigning physical power-up data.
module hard_drivin_sound_local_ram (
  input  logic        clk_i,
  input  logic        initialize_i,

  input  logic        read_request_i,
  input  logic [12:0] word_address_i,
  output logic [15:0] read_data_o,
  output logic [15:0] read_valid_mask_o,

  input  logic        upper_write_commit_i,
  input  logic        lower_write_commit_i,
  input  logic [15:0] write_data_i,
  output logic        upper_write_accepted_o,
  output logic        lower_write_accepted_o,
  output logic        write_blocked_o,

  output logic        storage_ready_o,
  output logic        validity_scrub_active_o,
  output logic [12:0] validity_scrub_address_o
);
  logic [7:0] upper_ram [0:8191];
  logic [7:0] lower_ram [0:8191];
  logic [1:0] lane_valid [0:8191];

  logic [12:0] validity_scrub_address_q;
  logic        validity_scrub_active_q;
  logic [1:0]  selected_lane_valid;

  assign validity_scrub_active_o = validity_scrub_active_q;
  assign validity_scrub_address_o = validity_scrub_address_q;
  assign storage_ready_o = !initialize_i && !validity_scrub_active_q;

  assign upper_write_accepted_o =
    storage_ready_o && upper_write_commit_i;
  assign lower_write_accepted_o =
    storage_ready_o && lower_write_commit_i;
  assign write_blocked_o =
    !storage_ready_o &&
    (upper_write_commit_i || lower_write_commit_i);

  assign selected_lane_valid = lane_valid[word_address_i];

  // The physical pair drives both lanes during a selected read. This module
  // reports only data known to the FPGA abstraction; the bridge supplies the
  // independent physical driven mask.
  always_comb begin
    read_data_o = 16'h0000;
    read_valid_mask_o = 16'h0000;

    if (storage_ready_o && read_request_i) begin
      read_valid_mask_o = {
        {8{selected_lane_valid[1]}},
        {8{selected_lane_valid[0]}}
      };
      read_data_o = {
        upper_ram[word_address_i] & {8{selected_lane_valid[1]}},
        lower_ram[word_address_i] & {8{selected_lane_valid[0]}}
      };
    end
  end

  // initialize_i resets only the metadata-scrub controller. The following
  // 8192 clocks clear one validity word per clock. Writes are rejected during
  // that interval so a later scrub location cannot silently erase a newly
  // accepted lane. The two byte memories themselves are never cleared.
  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      validity_scrub_active_q  <= 1'b1;
      validity_scrub_address_q <= 13'h0000;
    end else if (validity_scrub_active_q) begin
      lane_valid[validity_scrub_address_q] <= 2'b00;
      if (validity_scrub_address_q == 13'h1fff) begin
        validity_scrub_active_q <= 1'b0;
      end else begin
        validity_scrub_address_q <= validity_scrub_address_q + 13'h0001;
      end
    end else begin
      if (upper_write_commit_i) begin
        upper_ram[word_address_i] <= write_data_i[15:8];
        lane_valid[word_address_i][1] <= 1'b1;
      end
      if (lower_write_commit_i) begin
        lower_ram[word_address_i] <= write_data_i[7:0];
        lane_valid[word_address_i][0] <= 1'b1;
      end
    end
  end

  always_comb begin
    assert ((read_valid_mask_o == 16'h0000) ||
            (read_valid_mask_o == 16'hff00) ||
            (read_valid_mask_o == 16'h00ff) ||
            (read_valid_mask_o == 16'hffff));
    assert ((read_data_o & ~read_valid_mask_o) == 16'h0000);
    assert (!upper_write_accepted_o || upper_write_commit_i);
    assert (!lower_write_accepted_o || lower_write_commit_i);
    assert (!write_blocked_o || !storage_ready_o);
    assert (!storage_ready_o || !validity_scrub_active_o);
    assert (!(read_request_i &&
              (upper_write_commit_i || lower_write_commit_i)));
    if (!read_request_i || !storage_ready_o) begin
      assert (read_data_o == 16'h0000);
      assert (read_valid_mask_o == 16'h0000);
    end
  end
endmodule

`default_nettype wire
