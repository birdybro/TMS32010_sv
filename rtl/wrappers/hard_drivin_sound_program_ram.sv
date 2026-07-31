`default_nettype none

// Same-clock FPGA storage adapter for the A044427 Rev-A 4K-by-16 program
// RAM. The physical board uses asynchronous SRAM; registered reads and ready
// outputs are an FPGA integration convention. Ownership and target selection
// remain the separately qualified board logic.
module hard_drivin_sound_program_ram (
  input  logic        clk_i,
  input  logic        initialize_i,

  input  logic        dsp_reset_n_i,
  input  logic        host_program_select_n_i,
  input  logic        host_write_i,
  input  logic        host_commit_i,
  input  logic [11:0] host_address_i,
  input  logic [15:0] host_write_data_i,
  output logic [15:0] host_read_data_o,
  output logic        host_ready_o,
  output logic        host_access_permitted_o,

  input  logic [11:0] tms_address_i,
  input  logic        tms_men_n_i,
  input  logic        tms_den_n_i,
  input  logic        tms_we_n_i,
  input  logic        tms_commit_i,
  input  logic [15:0] tms_write_data_i,
  output logic [15:0] tms_read_data_o,
  output logic        tms_program_ready_o,
  output logic        tms_access_permitted_o,

  output logic        ownership_conflict_o,
  output logic        port_region_o,
  output logic [2:0]  io_port_o,
  output logic        io_read_o,
  output logic        io_write_o,
  output logic        tms_program_read_o,
  output logic        tms_program_write_o,
  output logic        tms_program_ram_select_n_o
);
  logic [15:0] program_ram [0:4095];

  logic        dsp_path_enable;
  logic        host_path_enable;
  logic        read_response_valid;
  logic        read_response_host;
  logic [15:0] read_response_data;
  logic        host_read_request;
  logic        tms_read_request;
  logic        host_write_commit;
  logic        tms_write_commit;
  logic [11:0] selected_read_address;

  hard_drivin_sound_bus_decode decode (
    .dsp_reset_n_i                 (dsp_reset_n_i),
    .host_program_select_n_i       (host_program_select_n_i),
    .tms_address_i                 (tms_address_i),
    .tms_men_n_i                   (tms_men_n_i),
    .tms_den_n_i                   (tms_den_n_i),
    .tms_we_n_i                    (tms_we_n_i),
    .dsp_path_enable_o             (dsp_path_enable),
    .host_path_enable_o            (host_path_enable),
    .ownership_conflict_o          (ownership_conflict_o),
    .port_region_o                 (port_region_o),
    .io_port_o                     (io_port_o),
    .io_read_o                     (io_read_o),
    .io_write_o                    (io_write_o),
    .dsp_program_read_o            (tms_program_read_o),
    .dsp_program_write_o           (tms_program_write_o),
    .dsp_program_ram_select_n_o    (tms_program_ram_select_n_o)
  );

  // Only one of these permits may be true. The invalid overlap state disables
  // both storage paths and remains externally visible as a protocol error.
  assign tms_access_permitted_o =
    dsp_path_enable && !host_path_enable;
  assign host_access_permitted_o =
    host_path_enable && !dsp_path_enable;

  assign host_read_request =
    host_access_permitted_o && !host_write_i;
  assign tms_read_request =
    tms_access_permitted_o && tms_program_read_o;
  assign selected_read_address =
    host_read_request ? host_address_i : tms_address_i;

  assign host_read_data_o = read_response_data;
  assign tms_read_data_o = read_response_data;
  assign host_ready_o =
    host_access_permitted_o && (
      host_write_i || (read_response_valid && read_response_host)
    );
  assign tms_program_ready_o =
    tms_access_permitted_o && (
      tms_program_write_o ||
      (tms_program_read_o && read_response_valid && !read_response_host)
    );

  assign host_write_commit =
    host_access_permitted_o && host_write_i && host_commit_i;
  assign tms_write_commit =
    tms_access_permitted_o && tms_program_write_o && tms_commit_i;

  // The RAM contents are intentionally not reset. The physical board requires
  // the host to load program RAM while the DSP is held in reset. initialize_i
  // resets only this adapter's synchronous read-response state.
  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      read_response_valid <= 1'b0;
      read_response_host  <= 1'b0;
      read_response_data  <= 16'h0000;
    end else begin
      if (read_response_valid) begin
        if (
          (read_response_host && !host_read_request) ||
          (!read_response_host && !tms_read_request)
        ) begin
          read_response_valid <= 1'b0;
        end
      end else if (host_read_request || tms_read_request) begin
        read_response_data  <= program_ram[selected_read_address];
        read_response_host  <= host_read_request;
        read_response_valid <= 1'b1;
      end

      if (host_write_commit) begin
        program_ram[host_address_i] <= host_write_data_i;
      end else if (tms_write_commit) begin
        program_ram[tms_address_i] <= tms_write_data_i;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (!initialize_i) begin
      assert (!(host_access_permitted_o && tms_access_permitted_o));
      assert (!(host_write_commit && tms_write_commit));
      assert (!ownership_conflict_o || (
        !host_access_permitted_o && !tms_access_permitted_o
      ));
      assert (!tms_program_write_o || !port_region_o);
      assert (!io_write_o || port_region_o);
    end
  end
endmodule

`default_nettype wire
