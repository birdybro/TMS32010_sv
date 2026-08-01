`default_nettype none

module tb_hard_drivin_sound_direct_io;
  logic        host_read;
  logic        host_read_complete;
  logic        host_write;
  logic        host_write_commit;
  logic [11:0] host_word_address;
  logic [15:0] host_write_data;
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

  hard_drivin_sound_direct_io dut (
    .host_read_i                    (host_read),
    .host_read_complete_i           (host_read_complete),
    .host_write_i                   (host_write),
    .host_write_commit_i            (host_write_commit),
    .host_word_address_i            (host_word_address),
    .host_write_data_i              (host_write_data),
    .port_0_read_data_i             (16'ha55a),
    .port_0_read_driven_mask_i      (16'hffff),
    .port_0_read_valid_mask_i       (16'hffff),
    .port_1_read_data_i             (16'hc33c),
    .port_1_read_driven_mask_i      (16'hffff),
    .port_1_read_valid_mask_i       (16'h0ff0),
    .port_2_read_data_i             (16'hffff),
    .port_2_read_driven_mask_i      (16'h8000),
    .port_2_read_valid_mask_i       (16'hc000),
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

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $error("FAIL %s address=%03h", message, host_word_address);
      $fatal(1);
    end
  endtask

  initial begin
    host_read = 1'b0;
    host_read_complete = 1'b0;
    host_write = 1'b0;
    host_write_commit = 1'b0;
    host_word_address = 12'h000;
    host_write_data = 16'h69c3;
    #1;
    require(read_target_select == 4'h0 && read_complete_select == 4'h0 &&
            read_data == 16'h0000 && read_driven_mask == 16'h0000 &&
            read_valid_mask == 16'h0000 && !read_alias,
            "inactive read path");
    require(write_target_select == 8'h00 &&
            write_commit_select == 8'h00 && !write_unselected &&
            !write_commit_unselected && write_data == 16'h69c3,
            "inactive write path and raw data carrier");

    // Exhaust all twelve RA bits. Reads select only RA1:RA0 and therefore
    // alias every four words through the complete upper-Y5 window.
    host_read = 1'b1;
    host_read_complete = 1'b1;
    for (int unsigned address_value = 0;
         address_value < 4096; address_value++) begin
      logic [15:0] expected_data;
      logic [15:0] expected_driven;
      logic [15:0] expected_valid;
      host_word_address = address_value[11:0];
      #1;
      expected_data = 16'h0000;
      expected_driven = 16'h0000;
      expected_valid = 16'h0000;
      case (address_value[1:0])
        2'd0: begin
          expected_data = 16'ha55a;
          expected_driven = 16'hffff;
          expected_valid = 16'hffff;
        end
        2'd1: begin
          expected_data = 16'h0330;
          expected_driven = 16'hffff;
          expected_valid = 16'h0ff0;
        end
        2'd2: begin
          expected_data = 16'h8000;
          expected_driven = 16'h8000;
          expected_valid = 16'h8000;
        end
        default: begin
          expected_data = 16'h0000;
          expected_driven = 16'h0000;
          expected_valid = 16'h0000;
        end
      endcase
      require(read_port == address_value[1:0], "read port projection");
      require(read_target_select == (4'h1 << address_value[1:0]),
              "LS139 read target");
      require(read_complete_select == read_target_select,
              "read completion target");
      require(read_data == expected_data &&
              read_driven_mask == expected_driven &&
              read_valid_mask == expected_valid,
              "masked read carrier");
      require(read_alias == (address_value[11:2] != 0),
              "modulo-four read alias reporting");
    end

    host_read = 1'b0;
    host_read_complete = 1'b0;
    host_write = 1'b1;
    host_write_commit = 1'b1;
    for (int unsigned address_value = 0;
         address_value < 4096; address_value++) begin
      logic canonical;
      host_word_address = address_value[11:0];
      #1;
      canonical = address_value < 8;
      require(write_port == address_value[2:0], "write port projection");
      require(write_target_select ==
                (canonical ? (8'h01 << address_value[2:0]) : 8'h00),
              "LS138 canonical write target");
      require(write_commit_select == write_target_select,
              "write completion target");
      require(write_unselected == !canonical &&
              write_commit_unselected == !canonical,
              "noncanonical writes have no target");
    end

    // A strobe level without its edge selects the target but emits no commit.
    host_word_address = 12'h006;
    host_write_commit = 1'b0;
    #1;
    require(write_target_select == 8'h40 &&
            write_commit_select == 8'h00,
            "write level and commit remain distinct");

    $display("PASS tb_hard_drivin_sound_direct_io");
    $finish;
  end
endmodule

`default_nettype wire
