`default_nettype none

// Same-clock FPGA storage adaptation for A044427's two HM6116 devices used as
// 512 complete 16-bit words. CRAMEN selects host read/write or DSP read-only
// ownership. Registered reads and ready outputs are FPGA conventions.
module hard_drivin_sound_communication_ram (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        communication_host_enable_i,

  input  logic        host_select_n_i,
  input  logic        host_write_i,
  input  logic        host_commit_i,
  input  logic [8:0]  host_address_i,
  input  logic [15:0] host_write_data_i,
  output logic [15:0] host_read_data_o,
  output logic        host_ready_o,
  output logic        host_access_permitted_o,
  output logic        host_blocked_o,

  input  logic        dsp_read_i,
  input  logic [8:0]  dsp_address_i,
  output logic [15:0] dsp_read_data_o,
  output logic        dsp_ready_o,
  output logic        dsp_access_permitted_o,
  output logic        dsp_blocked_o
);
  logic [15:0] communication_ram [0:511];

  logic        read_response_valid;
  logic        read_response_host;
  logic [15:0] read_response_data;
  logic        host_read_request;
  logic        dsp_read_request;
  logic        host_write_commit;
  logic [8:0]  selected_read_address;

  assign host_access_permitted_o = communication_host_enable_i;
  assign dsp_access_permitted_o  = !communication_host_enable_i;

  assign host_blocked_o =
    !host_select_n_i && !host_access_permitted_o;
  assign dsp_blocked_o = dsp_read_i && !dsp_access_permitted_o;

  assign host_read_request =
    host_access_permitted_o && !host_select_n_i && !host_write_i;
  assign dsp_read_request = dsp_access_permitted_o && dsp_read_i;
  assign selected_read_address =
    host_read_request ? host_address_i : dsp_address_i;

  assign host_read_data_o = read_response_data;
  assign dsp_read_data_o  = read_response_data;
  assign host_ready_o =
    host_access_permitted_o && !host_select_n_i && (
      host_write_i || (read_response_valid && read_response_host)
    );
  assign dsp_ready_o =
    dsp_read_request && read_response_valid && !read_response_host;

  assign host_write_commit =
    host_access_permitted_o &&
    !host_select_n_i &&
    host_write_i &&
    host_commit_i;

  // Neither FPGA initialization nor processor reset clears the memory. The
  // board protocol initializes contents through the host path if required.
  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      read_response_valid <= 1'b0;
      read_response_host  <= 1'b0;
      read_response_data  <= 16'h0000;
    end else begin
      if (read_response_valid) begin
        if (
          (read_response_host && !host_read_request) ||
          (!read_response_host && !dsp_read_request)
        ) begin
          read_response_valid <= 1'b0;
        end
      end else if (host_read_request || dsp_read_request) begin
        read_response_data  <= communication_ram[selected_read_address];
        read_response_host  <= host_read_request;
        read_response_valid <= 1'b1;
      end

      if (host_write_commit) begin
        communication_ram[host_address_i] <= host_write_data_i;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (!initialize_i) begin
      assert (!(host_access_permitted_o && dsp_access_permitted_o));
      assert (!(host_ready_o && dsp_ready_o));
      assert (!host_write_commit || host_access_permitted_o);
      assert (!dsp_ready_o || dsp_access_permitted_o);
    end
  end
endmodule

`default_nettype wire
