`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_communication_path;
  logic        clk;
  logic        initialize;
  logic        communication_host_enable;
  logic        host_select_n;
  logic        host_write;
  logic        host_commit;
  logic [8:0]  host_address;
  logic [15:0] host_write_data;
  logic [15:0] host_read_data;
  logic        host_ready;
  logic        host_access_permitted;
  logic        host_blocked;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic [15:0] io_write_data;
  logic        io_commit;
  logic [15:0] port_1_read_data;
  logic        port_1_ready;
  logic        port_1_blocked;
  logic        port_1_address_invalid;
  logic [15:0] sound_address;
  logic        sound_address_valid;
  logic [3:0]  sound_rom_block;
  logic        sound_rom_block_valid;

  hard_drivin_sound_communication_path dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .communication_host_enable_i   (communication_host_enable),
    .host_select_n_i               (host_select_n),
    .host_write_i                  (host_write),
    .host_commit_i                 (host_commit),
    .host_address_i                (host_address),
    .host_write_data_i             (host_write_data),
    .host_read_data_o              (host_read_data),
    .host_ready_o                  (host_ready),
    .host_access_permitted_o       (host_access_permitted),
    .host_blocked_o                (host_blocked),
    .io_port_i                     (io_port),
    .io_read_i                     (io_read),
    .io_write_i                    (io_write),
    .io_write_data_i               (io_write_data),
    .io_commit_i                   (io_commit),
    .port_1_read_data_o            (port_1_read_data),
    .port_1_ready_o                (port_1_ready),
    .port_1_blocked_o              (port_1_blocked),
    .port_1_address_invalid_o      (port_1_address_invalid),
    .sound_address_o               (sound_address),
    .sound_address_valid_o         (sound_address_valid),
    .sound_rom_block_o             (sound_rom_block),
    .sound_rom_block_valid_o       (sound_rom_block_valid)
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

  function automatic logic [15:0] test_word(input logic [8:0] address);
    test_word = 16'h8000 | {7'h00, address};
  endfunction

  task automatic host_write_word(
    input logic [8:0] address,
    input logic [15:0] data
  );
    host_select_n  = 1'b0;
    host_write     = 1'b1;
    host_address   = address;
    host_write_data = data;
    host_commit    = 1'b1;
    #1;
    require(host_access_permitted && host_ready && !host_blocked,
            "CRAMEN high accepts a complete host write");
    tick();
    host_commit = 1'b0;
  endtask

  task automatic host_read_word(
    input logic [8:0] address,
    input logic [15:0] expected
  );
    host_select_n = 1'b0;
    host_write    = 1'b0;
    host_address  = address;
    #1;
    require(!host_ready, "host RAM read is synchronous");
    tick();
    require(host_ready && host_read_data == expected,
            "host RAM read returns the addressed complete word");
    host_select_n = 1'b1;
    tick();
  endtask

  task automatic commit_io_write(
    input logic [2:0] port,
    input logic [15:0] data
  );
    io_port       = port;
    io_write      = 1'b1;
    io_write_data = data;
    io_commit     = 1'b1;
    tick();
    io_write  = 1'b0;
    io_commit = 1'b0;
  endtask

  task automatic read_port_1_word(
    input logic [15:0] expected
  );
    io_port = 3'd1;
    io_read = 1'b1;
    #1;
    require(!port_1_ready && !port_1_address_invalid,
            "valid DSP communication read starts synchronously");
    tick();
    require(port_1_ready && port_1_read_data == expected,
            "DSP communication read uses current sound-address low bits");
    io_commit = 1'b1;
    tick();
    io_read   = 1'b0;
    io_commit = 1'b0;
    tick();
  endtask

  initial begin
    initialize = 1'b1;
    communication_host_enable = 1'b0;
    host_select_n = 1'b1;
    host_write = 1'b0;
    host_commit = 1'b0;
    host_address = 9'h000;
    host_write_data = 16'h0000;
    io_port = 3'd0;
    io_read = 1'b0;
    io_write = 1'b0;
    io_write_data = 16'h0000;
    io_commit = 1'b0;
    tick();
    initialize = 1'b0;
    tick();

    require(!sound_address_valid && !sound_rom_block_valid,
            "FPGA initialization does not claim physical counter state");
    require(!host_access_permitted,
            "reset-cleared CRAMEN gives ownership to the DSP side");

    host_select_n = 1'b0;
    host_write = 1'b1;
    host_commit = 1'b1;
    #1;
    require(host_blocked && !host_ready,
            "host communication access is rejected while CRAMEN is low");
    tick();
    host_commit = 1'b0;
    host_select_n = 1'b1;

    communication_host_enable = 1'b1;
    for (int unsigned address = 0; address < 512; address++) begin
      host_write_word(address[8:0], test_word(address[8:0]));
    end
    host_select_n = 1'b1;
    host_read_word(9'h000, test_word(9'h000));
    host_read_word(9'h1ff, test_word(9'h1ff));

    commit_io_write(3'd7, 16'h01fe);
    require(sound_address_valid && sound_address == 16'h01fe,
            "port 7 loads all sixteen sound-address bits");
    io_port = 3'd1;
    io_read = 1'b1;
    #1;
    require(port_1_blocked && !port_1_ready,
            "DSP port 1 cannot see RAM while CRAMEN grants host ownership");
    io_read = 1'b0;

    communication_host_enable = 1'b0;
    host_select_n  = 1'b0;
    host_write     = 1'b1;
    host_address   = 9'h1aa;
    host_write_data = 16'hdead;
    host_commit    = 1'b1;
    #1;
    require(host_blocked && !host_ready,
            "CRAMEN low rejects a host write after RAM has been loaded");
    tick();
    host_select_n = 1'b1;
    host_write = 1'b0;
    host_commit = 1'b0;

    commit_io_write(3'd7, 16'ha1aa);
    read_port_1_word(test_word(9'h1aa));
    require(sound_address == 16'ha1ab,
            "DSP RAM address uses SA8:SA0 while the full counter increments");

    for (int unsigned address = 0; address < 512; address++) begin
      commit_io_write(3'd7, {7'h00, address[8:0]});
      read_port_1_word(test_word(address[8:0]));
      require(sound_address == ({7'h00, address[8:0]} + 16'h0001),
              "accepted port-1 read increments the full sound address once");
    end

    commit_io_write(3'd7, 16'h1234);
    io_port   = 3'd2;
    io_read   = 1'b1;
    io_commit = 1'b1;
    tick();
    io_read   = 1'b0;
    io_commit = 1'b0;
    require(sound_address == 16'h1235,
            "port-2 read also clocks the shared /PDEN counter");

    commit_io_write(3'd7, 16'hffff);
    io_port   = 3'd0;
    io_read   = 1'b1;
    io_commit = 1'b1;
    tick();
    io_read   = 1'b0;
    io_commit = 1'b0;
    require(sound_address == 16'h0000,
            "the four cascaded counters wrap modulo 65536");

    commit_io_write(3'd6, 16'habcd);
    require(sound_rom_block_valid && sound_rom_block == 4'hd,
            "port 6 latches only the low sound-ROM block nibble");
    begin
      logic [15:0] old_address;
      logic [3:0] old_block;
      old_address = sound_address;
      old_block = sound_rom_block;
      commit_io_write(3'd3, 16'h00a5);
      require(sound_address == old_address && sound_rom_block == old_block,
              "separate /CPORT latch has no address-control effect");
    end

    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    tick();
    require(!sound_address_valid && !sound_rom_block_valid,
            "deterministic initialization restores explicit invalid flags");
    communication_host_enable = 1'b1;
    host_read_word(9'h1aa, test_word(9'h1aa));

    commit_io_write(3'd7, 16'h01aa);
    host_select_n = 1'b0;
    host_write = 1'b0;
    host_address = 9'h000;
    tick();
    require(host_ready, "host response is available before ownership change");
    communication_host_enable = 1'b0;
    io_port = 3'd1;
    io_read = 1'b1;
    #1;
    require(!host_ready && host_blocked && !port_1_ready,
            "ownership transition never leaks the previous host response");
    tick();
    require(!port_1_ready,
            "owner-tagged response clears before the DSP request starts");
    tick();
    require(port_1_ready && port_1_read_data == test_word(9'h1aa),
            "DSP receives only its newly captured addressed response");
    io_commit = 1'b1;
    tick();
    io_read = 1'b0;
    io_commit = 1'b0;
    host_select_n = 1'b1;
    tick();

    $display("PASS tb_hard_drivin_sound_communication_path");
    $finish;
  end
endmodule

`default_nettype wire
