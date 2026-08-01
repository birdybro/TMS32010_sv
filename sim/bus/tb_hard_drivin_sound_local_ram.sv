`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_local_ram;
  logic        clk;
  logic        initialize;
  logic        read_request;
  logic [12:0] word_address;
  logic [15:0] read_data;
  logic [15:0] read_valid_mask;
  logic        upper_write_commit;
  logic        lower_write_commit;
  logic [15:0] write_data;
  logic        upper_write_accepted;
  logic        lower_write_accepted;
  logic        write_blocked;
  logic        storage_ready;
  logic        validity_scrub_active;
  logic [12:0] validity_scrub_address;

  hard_drivin_sound_local_ram dut (
    .clk_i                       (clk),
    .initialize_i                (initialize),
    .read_request_i              (read_request),
    .word_address_i              (word_address),
    .read_data_o                 (read_data),
    .read_valid_mask_o           (read_valid_mask),
    .upper_write_commit_i        (upper_write_commit),
    .lower_write_commit_i        (lower_write_commit),
    .write_data_i                (write_data),
    .upper_write_accepted_o      (upper_write_accepted),
    .lower_write_accepted_o      (lower_write_accepted),
    .write_blocked_o             (write_blocked),
    .storage_ready_o             (storage_ready),
    .validity_scrub_active_o     (validity_scrub_active),
    .validity_scrub_address_o    (validity_scrub_address)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    @(posedge clk);
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  function automatic logic [15:0] pattern(input logic [12:0] address);
    pattern = {
      address[7:0] ^ 8'ha5,
      address[12:5] ^ 8'h3c
    };
  endfunction

  task automatic complete_scrub;
    require(validity_scrub_active && !storage_ready,
            "metadata scrub starts after FPGA initialization");
    require(validity_scrub_address == 13'h0000,
            "metadata scrub starts at word zero");
    for (int unsigned address = 0; address < 8191; address++) begin
      tick();
      require(validity_scrub_active && !storage_ready,
              "storage stays unavailable until the final scrub word");
      require(validity_scrub_address ==
              (address[12:0] + 13'h0001),
              "metadata scrub advances exactly one word per clock");
    end
    tick();
    require(!validity_scrub_active && storage_ready,
            "storage becomes ready after exactly 8192 scrub clocks");
  endtask

  task automatic write_lanes(
    input logic [12:0] address,
    input logic [15:0] data,
    input logic upper,
    input logic lower
  );
    word_address = address;
    write_data = data;
    upper_write_commit = upper;
    lower_write_commit = lower;
    #1;
    require(upper_write_accepted == upper &&
            lower_write_accepted == lower && !write_blocked,
            "ready storage accepts exactly the requested byte lanes");
    tick();
    upper_write_commit = 1'b0;
    lower_write_commit = 1'b0;
  endtask

  task automatic check_read(
    input logic [12:0] address,
    input logic [15:0] expected_data,
    input logic [15:0] expected_valid
  );
    word_address = address;
    read_request = 1'b1;
    #1;
    require(read_data == expected_data &&
            read_valid_mask == expected_valid,
            "asynchronous local-SRAM read preserves byte validity");
    read_request = 1'b0;
    #1;
    require(read_data == 16'h0000 && read_valid_mask == 16'h0000,
            "inactive local-SRAM read exposes no qualified carrier");
  endtask

  initial begin
    initialize = 1'b1;
    read_request = 1'b0;
    word_address = 13'h0000;
    upper_write_commit = 1'b0;
    lower_write_commit = 1'b0;
    write_data = 16'h0000;
    tick();

    initialize = 1'b0;
    word_address = 13'h0123;
    write_data = 16'hdead;
    upper_write_commit = 1'b1;
    #1;
    require(write_blocked && !upper_write_accepted &&
            !lower_write_accepted,
            "write callbacks are explicitly rejected during metadata scrub");
    upper_write_commit = 1'b0;
    #1;
    complete_scrub();

    for (int unsigned address = 0; address < 8192; address++) begin
      check_read(address[12:0], 16'h0000, 16'h0000);
    end

    write_lanes(13'h0000, 16'ha55a, 1'b1, 1'b0);
    check_read(13'h0000, 16'ha500, 16'hff00);
    write_lanes(13'h0001, 16'h3cc3, 1'b0, 1'b1);
    check_read(13'h0001, 16'h00c3, 16'h00ff);
    write_lanes(13'h1fff, 16'h5aa5, 1'b1, 1'b1);
    check_read(13'h1fff, 16'h5aa5, 16'hffff);
    check_read(13'h0123, 16'h0000, 16'h0000);

    for (int unsigned address = 0; address < 8192; address++) begin
      write_lanes(address[12:0], pattern(address[12:0]), 1'b1, 1'b1);
    end
    for (int unsigned address = 0; address < 8192; address++) begin
      check_read(address[12:0], pattern(address[12:0]), 16'hffff);
    end

    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    read_request = 1'b1;
    word_address = 13'h1fff;
    #1;
    require(read_data == 16'h0000 && read_valid_mask == 16'h0000,
            "a new validity scrub hides retained physical data immediately");
    read_request = 1'b0;
    complete_scrub();
    for (int unsigned address = 0; address < 8192; address++) begin
      check_read(address[12:0], 16'h0000, 16'h0000);
    end

    $display("PASS tb_hard_drivin_sound_local_ram");
    $finish;
  end
endmodule

`default_nettype wire
