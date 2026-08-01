`default_nettype none

// Bounded same-clock composition proof for an original-MC68000 byte write to
// A044427's four unqualified program-RAM slices. This proves the FPGA adapter
// contract, not asynchronous SRAM or raw host-bus electrical timing.
module hard_drivin_sound_program_byte_formal (
  input logic         clk_i,
  input logic [11:0]  address_i,
  input logic [15:0]  bus_data_i,
  input logic         upper_byte_i
);
  logic        initialized = 1'b0;
  logic [2:0]  step_q = 3'd0;
  logic [11:0] address_q = 12'h000;
  logic [15:0] bus_data_q = 16'h0000;
  logic        upper_byte_q = 1'b0;
  logic [15:0] captured_word;
  logic        transfer_valid;
  logic        byte_transfer;
  logic [15:0] host_read_data;
  logic        host_ready;
  logic        host_access_permitted;
  logic        ownership_conflict;
  logic [15:0] expected_word;

  assign expected_word = upper_byte_q
    ? {2{bus_data_q[15:8]}}
    : {2{bus_data_q[7:0]}};

  always_ff @(posedge clk_i) begin
    initialized <= 1'b1;
    if (!initialized) begin
      step_q <= 3'd0;
      address_q <= address_i;
      bus_data_q <= bus_data_i;
      upper_byte_q <= upper_byte_i;
    end else if (step_q != 3'd5) begin
      step_q <= step_q + 1'b1;
    end
  end

  hard_drivin_mc68000_write_word write_word (
    .bus_data_i                  (bus_data_q),
    .upper_data_strobe_n_i       (!upper_byte_q),
    .lower_data_strobe_n_i       (upper_byte_q),
    .captured_word_o             (captured_word),
    .transfer_valid_o            (transfer_valid),
    .byte_transfer_o             (byte_transfer)
  );

  hard_drivin_sound_program_ram program_ram (
    .clk_i                         (clk_i),
    .initialize_i                  (!initialized),
    .dsp_reset_n_i                 (1'b0),
    .host_program_select_n_i       (
      !((step_q == 3'd1) || (step_q == 3'd3) || (step_q == 3'd4))
    ),
    .host_write_i                  (step_q == 3'd1),
    .host_commit_i                 (step_q == 3'd1),
    .host_address_i                (address_q),
    .host_write_data_i             (captured_word),
    .host_read_data_o              (host_read_data),
    .host_ready_o                  (host_ready),
    .host_access_permitted_o       (host_access_permitted),
    .tms_address_i                 (12'h000),
    .tms_men_n_i                   (1'b1),
    .tms_den_n_i                   (1'b1),
    .tms_we_n_i                    (1'b1),
    .tms_commit_i                  (1'b0),
    .tms_write_data_i              (16'h0000),
    .tms_read_data_o               (),
    .tms_program_ready_o           (),
    .tms_access_permitted_o        (),
    .ownership_conflict_o          (ownership_conflict),
    .port_region_o                 (),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .tms_program_read_o            (),
    .tms_program_write_o           (),
    .tms_program_ram_select_n_o    ()
  );

  always_ff @(posedge clk_i) begin
    if (initialized) begin
      assert (transfer_valid && byte_transfer);
      assert (captured_word == expected_word);
      assert (!ownership_conflict);
      if ((step_q == 3'd1) || (step_q == 3'd3) || (step_q == 3'd4)) begin
        assert (host_access_permitted);
      end
      if (step_q == 3'd1) begin
        assert (host_ready);
      end
      if (step_q == 3'd3) begin
        assert (!host_ready);
      end
      if (step_q == 3'd4) begin
        assert (host_ready);
        assert (host_read_data == expected_word);
      end
      cover ((step_q == 3'd4) && upper_byte_q && host_ready &&
             (host_read_data == expected_word));
      cover ((step_q == 3'd4) && !upper_byte_q && host_ready &&
             (host_read_data == expected_word));
    end
  end
endmodule

`default_nettype wire
