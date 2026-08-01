`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_mc68000_write_word;
  logic [15:0] bus_data;
  logic        upper_data_strobe_n;
  logic        lower_data_strobe_n;
  logic [15:0] captured_word;
  logic        transfer_valid;
  logic        byte_transfer;

  hard_drivin_mc68000_write_word dut (
    .bus_data_i                  (bus_data),
    .upper_data_strobe_n_i       (upper_data_strobe_n),
    .lower_data_strobe_n_i       (lower_data_strobe_n),
    .captured_word_o             (captured_word),
    .transfer_valid_o            (transfer_valid),
    .byte_transfer_o             (byte_transfer)
  );

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  initial begin
    for (int unsigned word = 0; word < 65536; word++) begin
      bus_data = word[15:0];

      upper_data_strobe_n = 1'b0;
      lower_data_strobe_n = 1'b0;
      #1;
      require(transfer_valid && !byte_transfer &&
              captured_word == word[15:0],
              "word write preserves all sixteen bus bits");

      upper_data_strobe_n = 1'b0;
      lower_data_strobe_n = 1'b1;
      #1;
      require(transfer_valid && byte_transfer &&
              captured_word == {2{word[15:8]}},
              "upper-byte write duplicates D15:D8 into both latch bytes");

      upper_data_strobe_n = 1'b1;
      lower_data_strobe_n = 1'b0;
      #1;
      require(transfer_valid && byte_transfer &&
              captured_word == {2{word[7:0]}},
              "lower-byte write duplicates D7:D0 into both latch bytes");
    end

    upper_data_strobe_n = 1'b1;
    lower_data_strobe_n = 1'b1;
    bus_data = 16'hffff;
    #1;
    require(!transfer_valid && !byte_transfer && captured_word == 16'h0000,
            "no asserted data strobe is not a write transfer");

    $display("PASS tb_hard_drivin_mc68000_write_word");
    $finish;
  end
endmodule

`default_nettype wire
