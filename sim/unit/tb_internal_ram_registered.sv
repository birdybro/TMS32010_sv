`default_nettype none

module tb_internal_ram_registered;
  logic        clk;
  logic        read_enable;
  logic [7:0]  read_address;
  logic [15:0] read_data;
  logic        read_address_valid;
  logic        write;
  logic [7:0]  write_address;
  logic        write_address_valid;
  logic [15:0] write_data;
  logic        debug_write;
  logic [7:0]  debug_address;
  logic [15:0] debug_data;

  tms32010_internal_ram #(
    .REGISTERED_READ (1'b1)
  ) dut (
    .clk_i                  (clk),
    .read_enable_i          (read_enable),
    .read_address_i         (read_address),
    .read_data_o            (read_data),
    .read_address_valid_o   (read_address_valid),
    .write_i                (write),
    .write_address_i        (write_address),
    .write_address_valid_o  (write_address_valid),
    .write_data_i           (write_data),
    .debug_write_i          (debug_write),
    .debug_address_i        (debug_address),
    .debug_data_i           (debug_data)
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

  initial begin
    read_enable = 1'b1;
    read_address = 8'h05;
    write = 1'b0;
    write_address = 8'h00;
    write_data = 16'h0000;
    debug_write = 1'b1;
    debug_address = 8'h05;
    debug_data = 16'h1234;

    require(read_address_valid, "word 5 is a qualified read address");
    require(write_address_valid, "word 0 is a qualified write address");
    tick();
    debug_write = 1'b0;
    tick();
    require(read_data == 16'h1234,
            "registered read observes a completed debug write");

    read_address = 8'h90;
    #1;
    require(!read_address_valid,
            "invalid-address qualification remains combinational");
    require(read_data == 16'h1234,
            "registered data does not follow an address without a clock");
    tick();
    require(read_data == 16'h0000,
            "invalid registered reads return the portable zero policy");

    debug_write = 1'b1;
    debug_address = 8'h06;
    debug_data = 16'hbeef;
    tick();
    debug_write = 1'b0;
    read_address = 8'h06;
    tick();
    require(read_data == 16'hbeef, "word 6 preload is observable");

    write = 1'b1;
    write_address = 8'h06;
    write_data = 16'hcafe;
    tick();
    write = 1'b0;
    require(read_data == 16'hcafe,
            "same-address CPU write forwards the committed word");
    tick();
    require(read_data == 16'hcafe,
            "the following registered read observes the CPU write");

    read_address = 8'h05;
    #1;
    require(read_data == 16'hcafe,
            "qualified address changes cannot bypass the read register");
    tick();
    require(read_data == 16'h1234,
            "the next FPGA edge captures the newly selected word");

    read_enable = 1'b0;
    read_address = 8'h06;
    tick();
    require(read_data == 16'h1234,
            "disabled read capture holds its complete registered output");
    read_enable = 1'b1;
    tick();
    require(read_data == 16'hcafe,
            "re-enabled read capture advances to the selected word");

    write_address = 8'hff;
    #1;
    require(!write_address_valid,
            "invalid CPU write addresses remain visible without writing");

    $display("PASS tb_internal_ram_registered");
    $finish;
  end
endmodule

`default_nettype wire
