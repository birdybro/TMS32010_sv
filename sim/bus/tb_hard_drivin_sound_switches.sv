`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_switches;
  logic [3:0]  j3_switch;
  logic [3:0]  j3_switch_valid;
  logic [15:0] host_read_data;
  logic [15:0] host_driven_mask;
  logic [15:0] host_valid_mask;

  hard_drivin_sound_switches dut (
    .j3_switch_i        (j3_switch),
    .j3_switch_valid_i  (j3_switch_valid),
    .host_read_data_o   (host_read_data),
    .host_driven_mask_o (host_driven_mask),
    .host_valid_mask_o  (host_valid_mask)
  );

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  initial begin
    for (int unsigned value = 0; value < 16; value++) begin
      for (int unsigned valid = 0; valid < 16; valid++) begin
        j3_switch = value[3:0];
        j3_switch_valid = valid[3:0];
        #1;

        require(host_driven_mask == 16'hf000,
                "/SWITCHES physically drives only D15:D12");
        require(host_valid_mask == {valid[3:0], 12'h000},
                "each raw connector source controls only its valid lane");
        require(host_read_data == {
                  value[3:0] & valid[3:0], 12'h000
                },
                "carrier clamps invalid sources and undriven lanes to zero");
      end
    end

    j3_switch = 4'b1010;
    j3_switch_valid = 4'b1111;
    #1;
    require(host_read_data == 16'ha000 &&
            host_valid_mask == 16'hf000,
            "J3-11/J3-9/J3-8/J3-7 map in order to D15:D12");

    $display("PASS tb_hard_drivin_sound_switches");
    $finish;
  end
endmodule

`default_nettype wire
