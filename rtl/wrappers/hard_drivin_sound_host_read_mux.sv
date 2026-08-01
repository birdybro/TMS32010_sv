`default_nettype none

// Storage-free composition of A044427 Rev-A LS138 30N's four low host-read
// targets. read_quadrant_i is raw A13:A12 order after an external bridge has
// qualified a read selection. This mapper has no strobe timing or side effects.
module hard_drivin_sound_host_read_mux (
  input  logic        read_select_valid_i,
  input  logic [1:0]  read_quadrant_i,

  input  logic [15:0] sound_read_data_i,
  input  logic [15:0] sound_read_driven_mask_i,
  input  logic [15:0] sound_read_valid_mask_i,
  input  logic [15:0] port_320_data_i,
  input  logic [15:0] port_320_driven_mask_i,
  input  logic [15:0] port_320_valid_mask_i,
  input  logic [15:0] switches_data_i,
  input  logic [15:0] switches_driven_mask_i,
  input  logic [15:0] switches_valid_mask_i,
  input  logic [15:0] read_status_data_i,
  input  logic [15:0] read_status_driven_mask_i,
  input  logic [15:0] read_status_valid_mask_i,

  output logic [15:0] host_read_data_o,
  output logic [15:0] host_driven_mask_o,
  output logic [15:0] host_valid_mask_o,
  output logic [3:0]  target_select_o
);
  always_comb begin
    host_read_data_o = 16'h0000;
    host_driven_mask_o = 16'h0000;
    host_valid_mask_o = 16'h0000;
    target_select_o = 4'b0000;

    if (read_select_valid_i) begin
      target_select_o = 4'b0001 << read_quadrant_i;
      unique case (read_quadrant_i)
        2'b00: begin
          host_read_data_o = sound_read_data_i;
          host_driven_mask_o = sound_read_driven_mask_i;
          host_valid_mask_o = sound_read_valid_mask_i;
        end
        2'b01: begin
          host_read_data_o = port_320_data_i;
          host_driven_mask_o = port_320_driven_mask_i;
          host_valid_mask_o = port_320_valid_mask_i;
        end
        2'b10: begin
          host_read_data_o = switches_data_i;
          host_driven_mask_o = switches_driven_mask_i;
          host_valid_mask_o = switches_valid_mask_i;
        end
        2'b11: begin
          host_read_data_o = read_status_data_i;
          host_driven_mask_o = read_status_driven_mask_i;
          host_valid_mask_o = read_status_valid_mask_i;
        end
        default: begin
          host_read_data_o = 16'h0000;
          host_driven_mask_o = 16'h0000;
          host_valid_mask_o = 16'h0000;
          target_select_o = 4'b0000;
        end
      endcase
    end

    assert (sound_read_driven_mask_i == 16'hffff);
    assert (port_320_driven_mask_i == 16'hff00);
    assert (switches_driven_mask_i == 16'hf000);
    assert (read_status_driven_mask_i == 16'hf000);
    assert ((sound_read_valid_mask_i & ~sound_read_driven_mask_i) == 16'h0000);
    assert ((port_320_valid_mask_i & ~port_320_driven_mask_i) == 16'h0000);
    assert ((switches_valid_mask_i & ~switches_driven_mask_i) == 16'h0000);
    assert ((read_status_valid_mask_i & ~read_status_driven_mask_i) == 16'h0000);
    assert ((host_valid_mask_o & ~host_driven_mask_o) == 16'h0000);
    assert ((host_read_data_o & ~host_valid_mask_o) == 16'h0000);
    assert ($onehot0(target_select_o));
    assert (read_select_valid_i ||
            ((host_read_data_o == 16'h0000) &&
             (host_driven_mask_o == 16'h0000) &&
             (host_valid_mask_o == 16'h0000) &&
             (target_select_o == 4'b0000)));
    assert (!read_select_valid_i ||
            (target_select_o == (4'b0001 << read_quadrant_i)));
  end
endmodule

`default_nettype wire
