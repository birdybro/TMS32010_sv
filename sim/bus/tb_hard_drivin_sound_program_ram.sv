`default_nettype none

module tb_hard_drivin_sound_program_ram;
  logic        clk;
  logic        initialize;
  logic        dsp_reset_n;
  logic        host_program_select_n;
  logic        host_write;
  logic        host_commit;
  logic [11:0] host_address;
  logic [15:0] host_write_data;
  logic [15:0] host_read_data;
  logic        host_ready;
  logic        host_access_permitted;
  logic [11:0] tms_address;
  logic        tms_men_n;
  logic        tms_den_n;
  logic        tms_we_n;
  logic        tms_commit;
  logic [15:0] tms_write_data;
  logic [15:0] tms_read_data;
  logic        tms_program_ready;
  logic        tms_access_permitted;
  logic        ownership_conflict;
  logic        port_region;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic        tms_program_read;
  logic        tms_program_write;
  logic        tms_program_ram_select_n;

  hard_drivin_sound_program_ram dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .dsp_reset_n_i                 (dsp_reset_n),
    .host_program_select_n_i       (host_program_select_n),
    .host_write_i                  (host_write),
    .host_commit_i                 (host_commit),
    .host_address_i                (host_address),
    .host_write_data_i             (host_write_data),
    .host_read_data_o              (host_read_data),
    .host_ready_o                  (host_ready),
    .host_access_permitted_o       (host_access_permitted),
    .tms_address_i                 (tms_address),
    .tms_men_n_i                   (tms_men_n),
    .tms_den_n_i                   (tms_den_n),
    .tms_we_n_i                    (tms_we_n),
    .tms_commit_i                  (tms_commit),
    .tms_write_data_i              (tms_write_data),
    .tms_read_data_o               (tms_read_data),
    .tms_program_ready_o           (tms_program_ready),
    .tms_access_permitted_o        (tms_access_permitted),
    .ownership_conflict_o          (ownership_conflict),
    .port_region_o                 (port_region),
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .tms_program_read_o            (tms_program_read),
    .tms_program_write_o           (tms_program_write),
    .tms_program_ram_select_n_o    (tms_program_ram_select_n)
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

  function automatic logic [15:0] test_word(input logic [11:0] address);
    test_word = {address[7:0], address[11:8], 4'ha} ^ 16'h5a35;
  endfunction

  task automatic set_tms_idle;
    tms_men_n = 1'b1;
    tms_den_n = 1'b1;
    tms_we_n  = 1'b1;
    tms_commit = 1'b0;
  endtask

  task automatic tms_read_and_require(
    input logic [11:0] address,
    input logic [15:0] expected,
    input string message
  );
    tms_address = address;
    tms_men_n = 1'b0;
    #1;
    require(tms_program_read && !io_read,
            "MEN request is decoded only as a program read");
    require(!tms_program_ready, "synchronous read is not ready before edge");
    tick();
    require(tms_program_ready, "synchronous TMS read produces ready");
    require(tms_read_data == expected, message);
    tms_men_n = 1'b1;
    tick();
    require(!tms_program_ready, "ready clears after TMS request release");
  endtask

  initial begin
    initialize = 1'b1;
    dsp_reset_n = 1'b0;
    host_program_select_n = 1'b1;
    host_write = 1'b0;
    host_commit = 1'b0;
    host_address = 12'h000;
    host_write_data = 16'h0000;
    tms_address = 12'h000;
    tms_write_data = 16'h0000;
    set_tms_idle();
    tick();
    initialize = 1'b0;
    tick();

    require(!host_access_permitted && !tms_access_permitted,
            "reset with no host selection grants no owner");

    // Load every word through the legal host path while the DSP is in reset.
    host_program_select_n = 1'b0;
    host_write = 1'b1;
    #1;
    require(host_access_permitted && host_ready && !ownership_conflict,
            "host owns RAM only while DSP reset is asserted");
    host_commit = 1'b1;
    for (int unsigned address = 0; address < 4096; address++) begin
      host_address = address[11:0];
      host_write_data = test_word(address[11:0]);
      tick();
    end
    host_commit = 1'b0;

    // Registered host readback uses the same complete 16-bit word path.
    host_write = 1'b0;
    host_address = 12'h5a7;
    #1;
    require(!host_ready, "host read waits for the synchronous RAM edge");
    tick();
    require(host_ready && host_read_data == test_word(12'h5a7),
            "host reads the loaded word");
    host_program_select_n = 1'b1;
    tick();
    require(!host_ready, "host ready clears when /320RAM is released");

    // FPGA initialization resets adapter state but must not erase program RAM.
    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    tick();

    // Complete the safe handoff before releasing the DSP reset.
    require(!ownership_conflict && !host_access_permitted,
            "host buffers are disabled before reset release");
    dsp_reset_n = 1'b1;
    tick();
    require(tms_access_permitted && !host_access_permitted,
            "released DSP owns program RAM");

    for (int unsigned address = 0; address < 4096; address++) begin
      tms_read_and_require(
        address[11:0],
        test_word(address[11:0]),
        "DSP reads every host-loaded program word"
      );
    end

    // Board-native WE at addresses 0..7 is an I/O write, even for TBLW.
    tms_address = 12'h003;
    tms_write_data = 16'hdead;
    tms_we_n = 1'b0;
    tms_commit = 1'b1;
    #1;
    require(port_region && io_write && io_port == 3'd3 && !tms_program_write,
            "low-address WE selects output port rather than RAM");
    require(!tms_program_ready && tms_program_ram_select_n,
            "RAM callback does not acknowledge the aliased I/O target");
    tick();
    set_tms_idle();
    tick();
    tms_read_and_require(12'h003, test_word(12'h003),
                         "low-address WE does not modify program RAM");

    // The first non-port address is a real program write and commits once at
    // the caller-supplied native boundary.
    tms_address = 12'h008;
    tms_write_data = 16'hbeef;
    tms_we_n = 1'b0;
    tms_commit = 1'b1;
    #1;
    require(tms_program_write && tms_program_ready && !io_write,
            "address eight WE selects writable program RAM");
    tick();
    set_tms_idle();
    tick();
    tms_read_and_require(12'h008, 16'hbeef,
                         "accepted TMS program write is retained");

    // Invalid overlap reports contention and grants neither digital writer.
    host_program_select_n = 1'b0;
    host_write = 1'b1;
    host_address = 12'h123;
    host_write_data = 16'h1111;
    host_commit = 1'b1;
    tms_address = 12'h123;
    tms_write_data = 16'h2222;
    tms_we_n = 1'b0;
    tms_commit = 1'b1;
    #1;
    require(ownership_conflict, "simultaneous host and running DSP is invalid");
    require(!host_access_permitted && !tms_access_permitted,
            "invalid overlap grants no implementation priority");
    require(!host_ready && !tms_program_ready,
            "invalid overlap acknowledges neither requester");
    tick();

    host_program_select_n = 1'b1;
    host_commit = 1'b0;
    set_tms_idle();
    tick();
    tms_read_and_require(12'h123, test_word(12'h123),
                         "conflicting write attempts leave RAM unchanged");

    $display("PASS tb_hard_drivin_sound_program_ram");
    $finish;
  end
endmodule

`default_nettype wire
