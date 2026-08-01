`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_host_read_mux;
  logic        read_select_valid;
  logic [1:0]  read_quadrant;
  logic [15:0] sound_read_data;
  logic [15:0] sound_read_driven_mask;
  logic [15:0] sound_read_valid_mask;
  logic [15:0] port_320_data;
  logic [15:0] port_320_driven_mask;
  logic [15:0] port_320_valid_mask;
  logic [15:0] switches_data;
  logic [15:0] switches_driven_mask;
  logic [15:0] switches_valid_mask;
  logic [15:0] read_status_data;
  logic [15:0] read_status_driven_mask;
  logic [15:0] read_status_valid_mask;
  logic [15:0] host_read_data;
  logic [15:0] host_driven_mask;
  logic [15:0] host_valid_mask;
  logic [3:0]  target_select;

  hard_drivin_sound_host_read_mux dut (
    .read_select_valid_i       (read_select_valid),
    .read_quadrant_i           (read_quadrant),
    .sound_read_data_i         (sound_read_data),
    .sound_read_driven_mask_i  (sound_read_driven_mask),
    .sound_read_valid_mask_i   (sound_read_valid_mask),
    .port_320_data_i           (port_320_data),
    .port_320_driven_mask_i    (port_320_driven_mask),
    .port_320_valid_mask_i     (port_320_valid_mask),
    .switches_data_i           (switches_data),
    .switches_driven_mask_i    (switches_driven_mask),
    .switches_valid_mask_i     (switches_valid_mask),
    .read_status_data_i        (read_status_data),
    .read_status_driven_mask_i (read_status_driven_mask),
    .read_status_valid_mask_i  (read_status_valid_mask),
    .host_read_data_o          (host_read_data),
    .host_driven_mask_o        (host_driven_mask),
    .host_valid_mask_o         (host_valid_mask),
    .target_select_o           (target_select)
  );

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  task automatic check_selected(
    input logic [1:0]  quadrant,
    input logic [15:0] expected_data,
    input logic [15:0] expected_driven,
    input logic [15:0] expected_valid,
    input logic [3:0]  expected_select,
    input string       message
  );
    read_quadrant = quadrant;
    #1;
    require(host_read_data == expected_data &&
            host_driven_mask == expected_driven &&
            host_valid_mask == expected_valid &&
            target_select == expected_select,
            message);
  endtask

  initial begin
    read_select_valid = 1'b0;
    read_quadrant = 2'b11;
    sound_read_data = 16'h0505;
    sound_read_driven_mask = 16'hffff;
    sound_read_valid_mask = 16'h0f0f;
    port_320_data = 16'h8500;
    port_320_driven_mask = 16'hff00;
    port_320_valid_mask = 16'ha500;
    switches_data = 16'h1000;
    switches_driven_mask = 16'hf000;
    switches_valid_mask = 16'h9000;
    read_status_data = 16'h4000;
    read_status_driven_mask = 16'hf000;
    read_status_valid_mask = 16'h6000;
    #1;
    require(host_read_data == 16'h0000 &&
            host_driven_mask == 16'h0000 &&
            host_valid_mask == 16'h0000 &&
            target_select == 4'b0000,
            "an unqualified selector does not claim any bus target");

    read_select_valid = 1'b1;
    check_selected(2'b00, 16'h0505, 16'hffff, 16'h0f0f, 4'b0001,
                   "quadrant 00 selects complete /SOUNDRD word");
    check_selected(2'b01, 16'h8500, 16'hff00, 16'ha500, 4'b0010,
                   "quadrant 01 selects partial /320PORT byte");
    check_selected(2'b10, 16'h1000, 16'hf000, 16'h9000, 4'b0100,
                   "quadrant 10 selects raw /SWITCHES nibble");
    check_selected(2'b11, 16'h4000, 16'hf000, 16'h6000, 4'b1000,
                   "quadrant 11 selects raw /READSTAT nibble");

    // Exercise every physically driven lane through its qualified target.
    for (int unsigned bit_index = 0; bit_index < 16; bit_index++) begin
      sound_read_valid_mask = 16'h0001 << bit_index;
      sound_read_data = 16'h0001 << bit_index;
      check_selected(2'b00, 16'h0001 << bit_index, 16'hffff,
                     16'h0001 << bit_index, 4'b0001,
                     "every /SOUNDRD lane survives composition");
    end
    for (int unsigned bit_index = 8; bit_index < 16; bit_index++) begin
      port_320_valid_mask = 16'h0001 << bit_index;
      port_320_data = 16'h0001 << bit_index;
      check_selected(2'b01, 16'h0001 << bit_index, 16'hff00,
                     16'h0001 << bit_index, 4'b0010,
                     "every /320PORT lane survives composition");
    end
    for (int unsigned bit_index = 12; bit_index < 16; bit_index++) begin
      switches_valid_mask = 16'h0001 << bit_index;
      switches_data = 16'h0001 << bit_index;
      check_selected(2'b10, 16'h0001 << bit_index, 16'hf000,
                     16'h0001 << bit_index, 4'b0100,
                     "every /SWITCHES lane survives composition");
      read_status_valid_mask = 16'h0001 << bit_index;
      read_status_data = 16'h0001 << bit_index;
      check_selected(2'b11, 16'h0001 << bit_index, 16'hf000,
                     16'h0001 << bit_index, 4'b1000,
                     "every /READSTAT lane survives composition");
    end

    $display("PASS tb_hard_drivin_sound_host_read_mux");
    $finish;
  end
endmodule

`default_nettype wire
