`default_nettype none

// Storage-free transcription of the A044427 Rev-A upper-Y5 direct-TMS-I/O
// decode.  Reads and writes are intentionally asymmetric: LS139 95K decodes
// only RA1:RA0 for reads, while LS138 100K requires RA11:RA3 all low before
// decoding RA2:RA0 for writes.  This module composes only explicitly driven
// and valid read bits; policy for undriven/open host-bus lanes is external.
module hard_drivin_sound_direct_io (
  input  logic        host_read_i,
  input  logic        host_read_complete_i,
  input  logic        host_write_i,
  input  logic        host_write_commit_i,
  input  logic [11:0] host_word_address_i,
  input  logic [15:0] host_write_data_i,

  input  logic [15:0] port_0_read_data_i,
  input  logic [15:0] port_0_read_driven_mask_i,
  input  logic [15:0] port_0_read_valid_mask_i,
  input  logic [15:0] port_1_read_data_i,
  input  logic [15:0] port_1_read_driven_mask_i,
  input  logic [15:0] port_1_read_valid_mask_i,
  input  logic [15:0] port_2_read_data_i,
  input  logic [15:0] port_2_read_driven_mask_i,
  input  logic [15:0] port_2_read_valid_mask_i,

  output logic [1:0]  read_port_o,
  output logic [3:0]  read_target_select_o,
  output logic [3:0]  read_complete_select_o,
  output logic [15:0] read_data_o,
  output logic [15:0] read_driven_mask_o,
  output logic [15:0] read_valid_mask_o,
  output logic        read_alias_o,

  output logic [2:0]  write_port_o,
  output logic [7:0]  write_target_select_o,
  output logic [7:0]  write_commit_select_o,
  output logic [15:0] write_data_o,
  output logic        write_unselected_o,
  output logic        write_commit_unselected_o
);
  logic [15:0] selected_read_data;
  logic [15:0] selected_read_driven_mask;
  logic [15:0] selected_read_valid_mask;
  logic        write_address_selected;

  assign read_port_o = host_word_address_i[1:0];
  assign write_port_o = host_word_address_i[2:0];
  assign write_data_o = host_write_data_i;
  assign read_target_select_o =
    host_read_i ? (4'b0001 << host_word_address_i[1:0]) : 4'b0000;
  assign read_complete_select_o =
    read_target_select_o & {4{host_read_complete_i}};
  assign read_alias_o =
    host_read_i && (host_word_address_i[11:2] != 10'h000);
  assign write_address_selected =
    host_word_address_i[11:3] == 9'h000;
  assign write_target_select_o =
    (host_write_i && write_address_selected)
      ? (8'h01 << host_word_address_i[2:0])
      : 8'h00;
  assign write_commit_select_o =
    write_target_select_o & {8{host_write_commit_i}};
  assign write_unselected_o = host_write_i && !write_address_selected;
  assign write_commit_unselected_o =
    host_write_i && host_write_commit_i && !write_address_selected;

  always_comb begin
    selected_read_data           = 16'h0000;
    selected_read_driven_mask    = 16'h0000;
    selected_read_valid_mask     = 16'h0000;

    case (host_word_address_i[1:0])
      2'd0: begin
        selected_read_data        = port_0_read_data_i;
        selected_read_driven_mask = port_0_read_driven_mask_i;
        selected_read_valid_mask  = port_0_read_valid_mask_i;
      end
      2'd1: begin
        selected_read_data        = port_1_read_data_i;
        selected_read_driven_mask = port_1_read_driven_mask_i;
        selected_read_valid_mask  = port_1_read_valid_mask_i;
      end
      2'd2: begin
        selected_read_data        = port_2_read_data_i;
        selected_read_driven_mask = port_2_read_driven_mask_i;
        selected_read_valid_mask  = port_2_read_valid_mask_i;
      end
      default: begin
        // LS139 95K Y3 has no drawn data-source enable on Rev-A sheet 5.
        selected_read_data        = 16'h0000;
        selected_read_driven_mask = 16'h0000;
        selected_read_valid_mask  = 16'h0000;
      end
    endcase

    read_driven_mask_o =
      host_read_i ? selected_read_driven_mask : 16'h0000;
    read_valid_mask_o =
      host_read_i
        ? (selected_read_valid_mask & selected_read_driven_mask)
        : 16'h0000;
    read_data_o =
      host_read_i
        ? (selected_read_data & selected_read_valid_mask &
           selected_read_driven_mask)
        : 16'h0000;
    assert ($onehot0(read_target_select_o));
    assert ($onehot0(read_complete_select_o));
    assert ($onehot0(write_target_select_o));
    assert ($onehot0(write_commit_select_o));
    assert ((read_valid_mask_o & ~read_driven_mask_o) == 16'h0000);
    assert ((read_data_o & ~read_valid_mask_o) == 16'h0000);
    assert (!write_commit_unselected_o || write_unselected_o);
  end
endmodule

`default_nettype wire
