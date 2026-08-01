`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_rom_path;
  logic [2:0]  io_port;
  logic        io_read;
  logic [15:0] sound_address;
  logic        sound_address_valid;
  logic [3:0]  sound_rom_block;
  logic        sound_rom_block_valid;
  logic [11:0] sound_rom_present;
  logic        sound_rom_request;
  logic [3:0]  sound_rom_request_block;
  logic [15:0] sound_rom_request_address;
  logic [7:0]  sound_rom_byte;
  logic        sound_rom_byte_ready;
  logic [15:0] port_0_read_data;
  logic        port_0_ready;
  logic        sound_rom_selection_invalid;

  hard_drivin_sound_rom_path dut (
    .io_port_i                     (io_port),
    .io_read_i                     (io_read),
    .sound_address_i               (sound_address),
    .sound_address_valid_i         (sound_address_valid),
    .sound_rom_block_i             (sound_rom_block),
    .sound_rom_block_valid_i       (sound_rom_block_valid),
    .sound_rom_present_i           (sound_rom_present),
    .sound_rom_request_o           (sound_rom_request),
    .sound_rom_request_block_o     (sound_rom_request_block),
    .sound_rom_request_address_o   (sound_rom_request_address),
    .sound_rom_byte_i              (sound_rom_byte),
    .sound_rom_byte_ready_i        (sound_rom_byte_ready),
    .port_0_read_data_o            (port_0_read_data),
    .port_0_ready_o                (port_0_ready),
    .sound_rom_selection_invalid_o (sound_rom_selection_invalid)
  );

  task automatic settle;
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  function automatic logic [15:0] physical_word(input logic [7:0] value);
    physical_word = {value[7], value, 7'b0000000};
  endfunction

  initial begin
    io_port = 3'd0;
    io_read = 1'b0;
    sound_address = 16'h0000;
    sound_address_valid = 1'b0;
    sound_rom_block = 4'h0;
    sound_rom_block_valid = 1'b0;
    sound_rom_present = 12'h000;
    sound_rom_byte = 8'h00;
    sound_rom_byte_ready = 1'b0;
    settle();

    require(!sound_rom_request && !port_0_ready &&
            !sound_rom_selection_invalid,
            "an inactive port produces no callback or invalid report");

    io_read = 1'b1;
    settle();
    require(sound_rom_selection_invalid && !sound_rom_request,
            "uncleared physical address and block state cannot be read");

    sound_address_valid = 1'b1;
    settle();
    require(sound_rom_selection_invalid && !sound_rom_request,
            "an uncleared block latch remains invalid");

    sound_rom_block_valid = 1'b1;
    sound_rom_byte_ready = 1'b1;
    sound_rom_present = 12'hfff;
    for (int unsigned block = 0; block < 16; block++) begin
      sound_rom_block = block[3:0];
      sound_address = {12'h5a5, block[3:0]};
      settle();
      if (block < 12) begin
        require(sound_rom_request && port_0_ready &&
                !sound_rom_selection_invalid,
                "each of the twelve decoded positions can be declared present");
        require(sound_rom_request_block == block[3:0] &&
                sound_rom_request_address == sound_address,
                "callback exposes the exact selected block and address");
      end else begin
        require(!sound_rom_request && !port_0_ready &&
                sound_rom_selection_invalid,
                "blocks 12 through 15 have no drawn ROM select");
      end
    end

    for (int unsigned block = 0; block < 12; block++) begin
      sound_rom_block = block[3:0];
      sound_rom_present = 12'h000;
      settle();
      require(sound_rom_selection_invalid && !sound_rom_request,
              "a decoded but absent position is never acknowledged");
      sound_rom_present = 12'h001 << block;
      settle();
      require(sound_rom_request && port_0_ready,
              "an explicitly present position is acknowledged");
    end

    sound_rom_block = 4'd3;
    sound_rom_present = 12'h008;
    for (int unsigned address = 0; address < 65536; address++) begin
      sound_address = address[15:0];
      settle();
      require(sound_rom_request_address == address[15:0],
              "every pre-increment sixteen-bit address passes unchanged");
    end

    sound_address = 16'h3457;
    for (int unsigned value = 0; value < 256; value++) begin
      sound_rom_byte = value[7:0];
      settle();
      require(port_0_read_data == physical_word(value[7:0]),
              "every byte duplicates its sign bit and shifts left seven");
    end
    sound_rom_byte = 8'hd5;
    settle();
    require(port_0_read_data == 16'hea80,
            "negative sample differs from MAME's unsigned 0x6a80 shift");

    sound_rom_byte_ready = 1'b0;
    settle();
    require(sound_rom_request && !port_0_ready &&
            !sound_rom_selection_invalid,
            "a present callback may hold the processor until data is ready");

    sound_rom_byte_ready = 1'b1;
    for (int unsigned port = 1; port < 8; port++) begin
      io_port = port[2:0];
      settle();
      require(!sound_rom_request && !port_0_ready &&
              !sound_rom_selection_invalid,
              "only a port-zero input read selects the sample ROM");
    end

    io_port = 3'd0;
    io_read = 1'b0;
    settle();
    require(!sound_rom_request && !port_0_ready &&
            !sound_rom_selection_invalid,
            "port-zero output writes do not request sample data");

    $display("PASS tb_hard_drivin_sound_rom_path");
    $finish;
  end
endmodule

`default_nettype wire
