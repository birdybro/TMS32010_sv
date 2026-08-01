`default_nettype none

// One-step symbolic proof of the complete twelve-bit upper-Y5 downstream
// decode and masked read-carrier contract.
module hard_drivin_sound_direct_io_formal (
  input logic        host_read_i,
  input logic        host_read_complete_i,
  input logic        host_write_i,
  input logic        host_write_commit_i,
  input logic [11:0] host_word_address_i,
  input logic [15:0] host_write_data_i,
  input logic [15:0] port_0_read_data_i,
  input logic [15:0] port_0_read_driven_mask_i,
  input logic [15:0] port_0_read_valid_mask_i,
  input logic [15:0] port_1_read_data_i,
  input logic [15:0] port_1_read_driven_mask_i,
  input logic [15:0] port_1_read_valid_mask_i,
  input logic [15:0] port_2_read_data_i,
  input logic [15:0] port_2_read_driven_mask_i,
  input logic [15:0] port_2_read_valid_mask_i
);
  logic [1:0]  read_port;
  logic [3:0]  read_target_select;
  logic [3:0]  read_complete_select;
  logic [15:0] read_data;
  logic [15:0] read_driven_mask;
  logic [15:0] read_valid_mask;
  logic        read_alias;
  logic [2:0]  write_port;
  logic [7:0]  write_target_select;
  logic [7:0]  write_commit_select;
  logic [15:0] write_data;
  logic        write_unselected;
  logic        write_commit_unselected;
  logic [15:0] expected_data;
  logic [15:0] expected_driven;
  logic [15:0] expected_valid;

  hard_drivin_sound_direct_io dut (
    .host_read_i                    (host_read_i),
    .host_read_complete_i           (host_read_complete_i),
    .host_write_i                   (host_write_i),
    .host_write_commit_i            (host_write_commit_i),
    .host_word_address_i            (host_word_address_i),
    .host_write_data_i              (host_write_data_i),
    .port_0_read_data_i             (port_0_read_data_i),
    .port_0_read_driven_mask_i      (port_0_read_driven_mask_i),
    .port_0_read_valid_mask_i       (port_0_read_valid_mask_i),
    .port_1_read_data_i             (port_1_read_data_i),
    .port_1_read_driven_mask_i      (port_1_read_driven_mask_i),
    .port_1_read_valid_mask_i       (port_1_read_valid_mask_i),
    .port_2_read_data_i             (port_2_read_data_i),
    .port_2_read_driven_mask_i      (port_2_read_driven_mask_i),
    .port_2_read_valid_mask_i       (port_2_read_valid_mask_i),
    .read_port_o                    (read_port),
    .read_target_select_o           (read_target_select),
    .read_complete_select_o         (read_complete_select),
    .read_data_o                    (read_data),
    .read_driven_mask_o             (read_driven_mask),
    .read_valid_mask_o              (read_valid_mask),
    .read_alias_o                   (read_alias),
    .write_port_o                   (write_port),
    .write_target_select_o          (write_target_select),
    .write_commit_select_o          (write_commit_select),
    .write_data_o                   (write_data),
    .write_unselected_o             (write_unselected),
    .write_commit_unselected_o      (write_commit_unselected)
  );

  always_comb begin
    expected_data = 16'h0000;
    expected_driven = 16'h0000;
    expected_valid = 16'h0000;
    if (host_read_i) begin
      case (host_word_address_i[1:0])
        2'd0: begin
          expected_driven = port_0_read_driven_mask_i;
          expected_valid =
            port_0_read_valid_mask_i & port_0_read_driven_mask_i;
          expected_data = port_0_read_data_i & expected_valid;
        end
        2'd1: begin
          expected_driven = port_1_read_driven_mask_i;
          expected_valid =
            port_1_read_valid_mask_i & port_1_read_driven_mask_i;
          expected_data = port_1_read_data_i & expected_valid;
        end
        2'd2: begin
          expected_driven = port_2_read_driven_mask_i;
          expected_valid =
            port_2_read_valid_mask_i & port_2_read_driven_mask_i;
          expected_data = port_2_read_data_i & expected_valid;
        end
        default: begin
          expected_driven = 16'h0000;
          expected_valid = 16'h0000;
          expected_data = 16'h0000;
        end
      endcase
    end

    assert (read_port == host_word_address_i[1:0]);
    assert (read_target_select ==
            (host_read_i
               ? (4'h1 << host_word_address_i[1:0])
               : 4'h0));
    assert (read_complete_select ==
            (read_target_select & {4{host_read_complete_i}}));
    assert (read_alias ==
            (host_read_i && (host_word_address_i[11:2] != 10'h000)));
    assert (read_data == expected_data);
    assert (read_driven_mask == expected_driven);
    assert (read_valid_mask == expected_valid);

    assert (write_port == host_word_address_i[2:0]);
    assert (write_target_select ==
            ((host_write_i &&
              (host_word_address_i[11:3] == 9'h000))
               ? (8'h01 << host_word_address_i[2:0])
               : 8'h00));
    assert (write_commit_select ==
            (write_target_select & {8{host_write_commit_i}}));
    assert (write_data == host_write_data_i);
    assert (write_unselected ==
            (host_write_i &&
             (host_word_address_i[11:3] != 9'h000)));
    assert (write_commit_unselected ==
            (host_write_i && host_write_commit_i &&
             (host_word_address_i[11:3] != 9'h000)));

    cover (host_read_i && host_read_complete_i &&
           (host_word_address_i == 12'hffc) &&
           (read_complete_select == 4'h1));
    cover (host_read_i && (host_word_address_i == 12'hfff) &&
           (read_target_select == 4'h8) &&
           (read_driven_mask == 16'h0000));
    cover (host_write_i && host_write_commit_i &&
           (host_word_address_i == 12'h007) &&
           (write_commit_select == 8'h80));
    cover (host_write_i && host_write_commit_i &&
           (host_word_address_i == 12'h008) &&
           write_commit_unselected);
  end
endmodule

`default_nettype wire
