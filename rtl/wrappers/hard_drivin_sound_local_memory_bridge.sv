`default_nettype none

// Storage-free same-clock callback boundary for the A044427 Rev-A local
// MC68000 memory banks. The inputs are the settled outputs of
// hard_drivin_sound_host_timing. ROM and local-RAM data remain external so
// authorized images and an integration-specific SRAM implementation can be
// supplied without assigning an open-bus value here.
module hard_drivin_sound_local_memory_bridge (
  input  logic        host_8mhz_rise_i,
  input  logic        cycle_active_i,
  input  logic        rva_i,
  input  logic        rvas_n_i,
  input  logic        cycle_complete_event_i,
  input  logic [23:1] latched_address_i,
  input  logic        latched_read_not_write_i,
  input  logic        latched_upper_data_strobe_n_i,
  input  logic        latched_lower_data_strobe_n_i,
  input  logic [15:0] host_write_data_i,

  output logic        rom_read_request_o,
  output logic [14:0] rom_word_address_o,
  input  logic [15:0] rom_read_data_i,
  input  logic        rom_read_data_valid_i,

  output logic        local_ram_read_request_o,
  output logic [12:0] local_ram_word_address_o,
  input  logic [15:0] local_ram_read_data_i,
  input  logic [15:0] local_ram_read_valid_mask_i,
  output logic        local_ram_upper_write_commit_o,
  output logic        local_ram_lower_write_commit_o,
  output logic [15:0] local_ram_write_data_o,

  output logic        host_program_select_n_o,
  output logic        host_program_ram_select_n_o,
  output logic        host_program_ram_read_o,
  output logic        host_program_ram_write_o,
  output logic        host_program_ram_write_commit_o,
  output logic [11:0] host_program_word_address_o,
  output logic        host_program_io_read_o,
  output logic        host_program_io_write_o,
  output logic        host_program_io_write_commit_o,

  output logic        host_communication_select_n_o,
  output logic        host_communication_read_o,
  output logic        host_communication_write_o,
  output logic        host_communication_write_commit_o,
  output logic [8:0]  host_communication_word_address_o,

  output logic [15:0] host_read_data_o,
  output logic [15:0] host_read_driven_mask_o,
  output logic [15:0] host_read_valid_mask_o,
  output logic [1:0]  host_read_target_select_o,
  output logic        host_read_response_missing_event_o,

  output logic [7:0]  high_bank_select_n_o,
  output logic        rvf_select_n_o,
  output logic        local_ram_select_n_o
);
  logic        rom_select_n;
  logic        program_bank_select_n;
  logic        communication_bank_select_n;
  logic        host_program_ram_write_n;
  logic        host_program_io_write_enable_n;
  logic        host_program_io_data_enable_n;
  logic        read_output_enable_n;
  logic        read_write_strobe_n;
  logic        upper_write_enable_n;
  logic        lower_write_enable_n;
  logic        rom_read;
  logic        local_ram_read;
  logic        local_ram_upper_write;
  logic        local_ram_lower_write;
  logic [15:0] rom_read_driven_mask;
  logic [15:0] local_ram_read_driven_mask;

  hard_drivin_sound_local_memory_decode decode (
    .address_i                         (latched_address_i),
    .address_strobe_n_i                (!cycle_active_i),
    .rva_i                             (rva_i),
    .rvas_n_i                          (rvas_n_i),
    .read_not_write_i                  (latched_read_not_write_i),
    .upper_data_strobe_n_i             (
      latched_upper_data_strobe_n_i
    ),
    .lower_data_strobe_n_i             (
      latched_lower_data_strobe_n_i
    ),
    .high_bank_select_n_o              (high_bank_select_n_o),
    .rom_select_n_o                    (rom_select_n),
    .rvf_select_n_o                    (rvf_select_n_o),
    .program_bank_select_n_o           (program_bank_select_n),
    .communication_bank_select_n_o     (communication_bank_select_n),
    .local_ram_select_n_o              (local_ram_select_n_o),
    .host_program_select_n_o           (host_program_select_n_o),
    .host_communication_select_n_o     (host_communication_select_n_o),
    .host_program_ram_chip_enable_n_o  (
      host_program_ram_select_n_o
    ),
    .host_program_ram_write_n_o        (host_program_ram_write_n),
    .host_program_io_write_enable_n_o  (
      host_program_io_write_enable_n
    ),
    .host_program_io_data_enable_n_o   (
      host_program_io_data_enable_n
    ),
    .host_program_ram_read_o           (host_program_ram_read_o),
    .host_program_ram_write_o          (host_program_ram_write_o),
    .host_program_io_read_o            (host_program_io_read_o),
    .host_program_io_write_o           (host_program_io_write_o),
    .read_output_enable_n_o            (read_output_enable_n),
    .read_write_strobe_n_o             (read_write_strobe_n),
    .upper_write_enable_n_o            (upper_write_enable_n),
    .lower_write_enable_n_o            (lower_write_enable_n),
    .rom_read_o                        (rom_read),
    .local_ram_read_o                  (local_ram_read),
    .local_ram_upper_write_o           (local_ram_upper_write),
    .local_ram_lower_write_o           (local_ram_lower_write),
    .rom_read_driven_mask_o            (rom_read_driven_mask),
    .local_ram_read_driven_mask_o      (local_ram_read_driven_mask),
    .populated_rom_word_address_o      (rom_word_address_o),
    .host_program_word_address_o       (host_program_word_address_o),
    .local_ram_word_address_o          (local_ram_word_address_o)
  );

  assign rom_read_request_o = rom_read;
  assign local_ram_read_request_o = local_ram_read;
  assign local_ram_write_data_o = host_write_data_i;

  // The asynchronous SRAM write-enable edges occur at the ordinary S7
  // completion boundary. Upper and lower slices remain independent.
  assign local_ram_upper_write_commit_o =
    cycle_complete_event_i && local_ram_upper_write;
  assign local_ram_lower_write_commit_o =
    cycle_complete_event_i && local_ram_lower_write;

  // Program RAM and communication RAM use whole-word physical paths. Their
  // external storage adapters consume a write only at the fixed S7 event.
  assign host_program_ram_write_commit_o =
    cycle_complete_event_i && host_program_ram_write_o;
  assign host_communication_read_o =
    !host_communication_select_n_o && latched_read_not_write_i;
  assign host_communication_write_o =
    !host_communication_select_n_o && !latched_read_not_write_i;
  assign host_communication_write_commit_o =
    cycle_complete_event_i && host_communication_write_o;
  assign host_communication_word_address_o = latched_address_i[9:1];

  // /PWE is an RVA-width pulse rather than an /RVAS-width SRAM write. Its
  // rising edge is the S6 host-clock event that samples an asserted pre-edge
  // write level. This is deliberately separate from the S7 SRAM commits.
  assign host_program_io_write_commit_o =
    host_8mhz_rise_i && host_program_io_write_o;

  // Only the two local storage targets are carried here. Other banks keep
  // their independent adapters. A selected but unavailable source still
  // reports its physically driven lanes while validity stays clear.
  always_comb begin
    host_read_data_o = 16'h0000;
    host_read_driven_mask_o = 16'h0000;
    host_read_valid_mask_o = 16'h0000;
    host_read_target_select_o = 2'b00;

    if (rom_read_request_o) begin
      host_read_data_o =
        rom_read_data_i & {16{rom_read_data_valid_i}};
      host_read_driven_mask_o = rom_read_driven_mask;
      host_read_valid_mask_o = {16{rom_read_data_valid_i}};
      host_read_target_select_o = 2'b01;
    end else if (local_ram_read_request_o) begin
      host_read_data_o =
        local_ram_read_data_i & local_ram_read_valid_mask_i;
      host_read_driven_mask_o = local_ram_read_driven_mask;
      host_read_valid_mask_o = local_ram_read_valid_mask_i;
      host_read_target_select_o = 2'b10;
    end
  end

  assign host_read_response_missing_event_o =
    cycle_complete_event_i &&
    (host_read_target_select_o != 2'b00) &&
    (host_read_valid_mask_o != host_read_driven_mask_o);

  always_comb begin
    assert ($onehot0(host_read_target_select_o));
    assert ((host_read_valid_mask_o & ~host_read_driven_mask_o) == 16'h0000);
    assert ((host_read_data_o & ~host_read_valid_mask_o) == 16'h0000);
    assert (!rom_read_request_o || (host_read_target_select_o == 2'b01));
    assert (!local_ram_read_request_o ||
            (host_read_target_select_o == 2'b10));
    assert (!(rom_read_request_o && local_ram_read_request_o));
    assert (!local_ram_upper_write_commit_o ||
            (cycle_complete_event_i && local_ram_upper_write));
    assert (!local_ram_lower_write_commit_o ||
            (cycle_complete_event_i && local_ram_lower_write));
    assert (!host_program_ram_write_commit_o ||
            (cycle_complete_event_i && host_program_ram_write_o));
    assert (!host_communication_write_commit_o ||
            (cycle_complete_event_i && host_communication_write_o));
    assert (!host_program_io_write_commit_o ||
            (host_8mhz_rise_i && host_program_io_write_o));
    assert (!host_read_response_missing_event_o ||
            cycle_complete_event_i);
    assert (rom_read_request_o ==
            (!rom_select_n && latched_read_not_write_i));
    assert (host_program_select_n_o ==
            (program_bank_select_n || rvas_n_i));
    assert (host_communication_select_n_o ==
            (communication_bank_select_n || rvas_n_i));
    assert (host_program_ram_read_o ==
            (!host_program_ram_select_n_o &&
             latched_read_not_write_i));
    assert (!host_program_ram_write_o ||
            (!host_program_ram_write_n &&
             !latched_read_not_write_i));
    assert (!host_program_io_read_o ||
            !host_program_io_data_enable_n);
    assert (!host_program_io_write_o ||
            !host_program_io_write_enable_n);
    assert (read_output_enable_n == !latched_read_not_write_i);
    assert (read_write_strobe_n ==
            (rvas_n_i || latched_read_not_write_i));
    assert (upper_write_enable_n ==
            (latched_upper_data_strobe_n_i || read_write_strobe_n));
    assert (lower_write_enable_n ==
            (latched_lower_data_strobe_n_i || read_write_strobe_n));
  end
endmodule

`default_nettype wire
