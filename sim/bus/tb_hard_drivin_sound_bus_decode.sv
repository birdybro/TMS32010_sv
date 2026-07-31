`default_nettype none

module tb_hard_drivin_sound_bus_decode;
  logic        dsp_reset_n;
  logic        host_program_select_n;
  logic [11:0] tms_address;
  logic        tms_men_n;
  logic        tms_den_n;
  logic        tms_we_n;

  logic        dsp_path_enable;
  logic        host_path_enable;
  logic        ownership_conflict;
  logic        port_region;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic        dsp_program_read;
  logic        dsp_program_write;
  logic        dsp_program_ram_select_n;

  hard_drivin_sound_bus_decode dut (
    .dsp_reset_n_i                 (dsp_reset_n),
    .host_program_select_n_i       (host_program_select_n),
    .tms_address_i                 (tms_address),
    .tms_men_n_i                   (tms_men_n),
    .tms_den_n_i                   (tms_den_n),
    .tms_we_n_i                    (tms_we_n),
    .dsp_path_enable_o             (dsp_path_enable),
    .host_path_enable_o            (host_path_enable),
    .ownership_conflict_o          (ownership_conflict),
    .port_region_o                 (port_region),
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .dsp_program_read_o            (dsp_program_read),
    .dsp_program_write_o           (dsp_program_write),
    .dsp_program_ram_select_n_o    (dsp_program_ram_select_n)
  );

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $error("FAIL %s", message);
      $fatal(1);
    end
  endtask

  task automatic set_idle;
    tms_men_n = 1'b1;
    tms_den_n = 1'b1;
    tms_we_n = 1'b1;
  endtask

  initial begin
    dsp_reset_n = 1'b0;
    host_program_select_n = 1'b1;
    tms_address = 12'd0;
    set_idle();
    #1;

    require(!dsp_path_enable && !host_path_enable && !ownership_conflict,
            "reset and idle host disable both paths");

    dsp_reset_n = 1'b1;
    #1;
    require(dsp_path_enable && !host_path_enable && !ownership_conflict,
            "released DSP owns path without host selection");

    dsp_reset_n = 1'b0;
    host_program_select_n = 1'b0;
    #1;
    require(!dsp_path_enable && host_path_enable && !ownership_conflict,
            "asserted reset permits host ownership");

    dsp_reset_n = 1'b1;
    #1;
    require(dsp_path_enable && host_path_enable && ownership_conflict,
            "running DSP plus host select exposes electrical conflict");

    host_program_select_n = 1'b1;
    for (int unsigned address = 0; address < 4096; address++) begin
      tms_address = address[11:0];
      set_idle();
      #1;
      require(port_region == (address < 8),
              "PORT covers exactly addresses zero through seven");
      require(io_port == address[2:0], "I/O decoder uses address low bits");
      require(!io_read && !io_write && !dsp_program_read &&
              !dsp_program_write && dsp_program_ram_select_n,
              "idle strobes select no target");

      tms_men_n = 1'b0;
      #1;
      require(dsp_program_read && !dsp_program_ram_select_n,
              "MEN selects program RAM at every address");
      require(!io_read && !io_write && !dsp_program_write,
              "MEN never selects an I/O transfer");

      set_idle();
      tms_den_n = 1'b0;
      #1;
      require(io_read == (address < 8),
              "DEN reads only the low-eight port region");
      require(dsp_program_ram_select_n && !dsp_program_read &&
              !dsp_program_write && !io_write,
              "DEN does not select program RAM");

      set_idle();
      tms_we_n = 1'b0;
      #1;
      require(io_write == (address < 8),
              "WE writes low-eight addresses through the port decoder");
      require(dsp_program_write == (address >= 8),
              "WE writes program RAM only above the port region");
      require(dsp_program_ram_select_n == (address < 8),
              "low-address WE is diverted from program RAM");
      require(!io_read && !dsp_program_read,
              "WE selects neither read path");
    end

    $display("PASS tb_hard_drivin_sound_bus_decode");
    $finish;
  end
endmodule

`default_nettype wire
