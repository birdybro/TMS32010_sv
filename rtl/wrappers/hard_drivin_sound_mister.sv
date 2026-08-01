`default_nettype none

// Same-clock FPGA integration of the generic MiSTer callback wrapper with the
// qualified A044427 Rev-A program/communication RAM ownership, parallel
// sample-ROM callback, raw DAC latch, output-control LS74s, opt-in BIO and
// host-control paths, native target decode, and an opt-in same-clock local-
// 68000 timing bridge. Raw-pin CDC, open-bus completion, mailbox byte writes,
// and remaining peripherals are external.
module hard_drivin_sound_mister (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        clock_enable_i,
  input  logic        dsp_reset_n_i,
  input  logic        bio_i,
  input  logic        use_board_bio_i,
  input  logic        board_reset_n_i,
  input  logic        bio_one_mhz_rise_i,
  input  logic [7:0]  bio_counter_seed_i,
  input  logic        bio_counter_seed_valid_i,
  output logic [7:0]  bio_divider_state_o,
  output logic        bio_divider_phase_valid_o,
  output logic        raw_320bio_n_o,
  output logic        raw_320bio_valid_o,
  output logic        board_bio_n_o,
  output logic        board_bio_valid_o,
  output logic        selected_bio_n_o,
  output logic        selected_bio_valid_o,

  input  logic        use_host_control_i,
  input  logic        host_latch_write_commit_i,
  input  logic [3:0]  host_latch_address_i,
  output logic [7:0]  host_latch_q_o,
  output logic [7:0]  host_latch_valid_o,
  output logic        selected_dsp_reset_n_o,
  output logic        selected_dsp_reset_valid_o,
  output logic        selected_communication_host_enable_o,
  output logic        selected_communication_host_enable_valid_o,

  input  logic        use_host_timing_i,
  input  logic        host_8mhz_rise_i,
  input  logic        host_8mhz_fall_i,
  input  logic        host_address_strobe_assert_i,
  input  logic        host_address_strobe_deassert_i,
  input  logic [2:0]  host_function_code_i,
  input  logic [23:1] host_bus_address_i,
  input  logic        host_read_not_write_i,
  input  logic        host_upper_data_strobe_n_i,
  input  logic        host_lower_data_strobe_n_i,
  input  logic [15:0] host_bus_write_data_i,
  output logic        host_timing_cycle_active_o,
  output logic        host_timing_rva_o,
  output logic        host_timing_vpa_n_o,
  output logic        host_timing_dtack_n_o,
  output logic        host_timing_rvas_n_o,
  output logic        host_timing_rvf_n_o,
  output logic        host_timing_read_write_strobe_n_o,
  output logic        host_timing_upper_write_enable_n_o,
  output logic        host_timing_lower_write_enable_n_o,
  output logic        host_timing_read_select_valid_o,
  output logic        host_timing_write_select_valid_o,
  output logic [23:1] host_timing_latched_address_o,
  output logic        host_timing_latched_read_not_write_o,
  output logic        host_timing_latched_upper_data_strobe_n_o,
  output logic        host_timing_latched_lower_data_strobe_n_o,
  output logic [1:0]  host_timing_select_quadrant_o,
  output logic [7:0]  host_timing_target_select_o,
  output logic        host_timing_cycle_complete_o,
  output logic        host_timing_read_complete_o,
  output logic        host_timing_write_complete_o,
  output logic        host_timing_speech_write_complete_o,
  output logic        host_timing_partial_sound_write_o,
  output logic        host_timing_partial_program_write_o,
  output logic        host_timing_partial_communication_write_o,

  input  logic [15:0] host_local_rom_read_data_i,
  input  logic        host_local_rom_read_data_valid_i,
  output logic        host_local_rom_read_request_o,
  output logic [14:0] host_local_rom_word_address_o,
  input  logic [15:0] host_local_ram_read_data_i,
  input  logic [15:0] host_local_ram_read_valid_mask_i,
  output logic        host_local_ram_read_request_o,
  output logic [12:0] host_local_ram_word_address_o,
  output logic        host_local_ram_upper_write_commit_o,
  output logic        host_local_ram_lower_write_commit_o,
  output logic [15:0] host_local_ram_write_data_o,
  output logic [15:0] host_local_memory_read_data_o,
  output logic [15:0] host_local_memory_read_driven_mask_o,
  output logic [15:0] host_local_memory_read_valid_mask_o,
  output logic [1:0]  host_local_memory_read_target_select_o,
  output logic        host_local_memory_read_missing_o,
  output logic        host_timing_program_io_read_o,
  output logic        host_timing_program_io_write_o,
  output logic        host_timing_program_io_write_commit_o,
  output logic [11:0] host_timing_program_io_word_address_o,

  input  logic        host_program_select_n_i,
  input  logic        host_write_i,
  input  logic        host_commit_i,
  input  logic [11:0] host_address_i,
  input  logic [15:0] host_write_data_i,
  output logic [15:0] host_read_data_o,
  output logic        host_ready_o,
  output logic        host_access_permitted_o,
  output logic        ownership_conflict_o,

  input  logic        communication_host_enable_i,
  input  logic        host_communication_select_n_i,
  input  logic        host_communication_write_i,
  input  logic        host_communication_commit_i,
  input  logic [8:0]  host_communication_address_i,
  input  logic [15:0] host_communication_write_data_i,
  output logic [15:0] host_communication_read_data_o,
  output logic        host_communication_ready_o,
  output logic        host_communication_access_permitted_o,
  output logic        host_communication_blocked_o,
  input  logic        host_irq_clear_commit_i,

  input  logic        main_mailbox_write_commit_i,
  input  logic [15:0] main_mailbox_write_data_i,
  input  logic        sound_cpu_mailbox_read_commit_i,
  output logic [15:0] sound_cpu_mailbox_read_data_o,
  output logic        sound_cpu_mailbox_read_data_valid_o,
  output logic        main_flag_o,
  output logic        main_flag_valid_o,
  output logic        main_flag_conflict_o,
  input  logic        sound_cpu_mailbox_write_commit_i,
  input  logic [15:0] sound_cpu_mailbox_write_data_i,
  input  logic        main_mailbox_read_commit_i,
  output logic [15:0] main_mailbox_read_data_o,
  output logic        main_mailbox_read_data_valid_o,
  output logic        sound_flag_o,
  output logic        sound_flag_valid_o,
  output logic        sound_flag_conflict_o,
  input  logic        sound_test_i,
  input  logic        sound_test_valid_i,
  input  logic        tirdy_n_i,
  input  logic        tirdy_n_valid_i,
  output logic [15:0] sound_cpu_read_status_data_o,
  output logic [15:0] sound_cpu_read_status_driven_mask_o,
  output logic [15:0] sound_cpu_read_status_valid_mask_o,
  input  logic [3:0]  j3_switch_i,
  input  logic [3:0]  j3_switch_valid_i,
  output logic [15:0] sound_cpu_switches_data_o,
  output logic [15:0] sound_cpu_switches_driven_mask_o,
  output logic [15:0] sound_cpu_switches_valid_mask_o,
  input  logic        sound_cpu_low_read_select_valid_i,
  input  logic [1:0]  sound_cpu_low_read_quadrant_i,
  output logic [15:0] sound_cpu_low_read_data_o,
  output logic [15:0] sound_cpu_low_read_driven_mask_o,
  output logic [15:0] sound_cpu_low_read_valid_mask_o,
  output logic [3:0]  sound_cpu_low_read_target_select_o,

  output logic [2:0]  io_port_o,
  output logic        io_read_o,
  output logic        io_write_o,
  output logic [15:0] io_write_data_o,
  output logic        io_commit_o,
  input  logic [15:0] io_read_data_i,
  input  logic        io_ready_i,

  output logic        port_1_blocked_o,
  output logic        port_1_address_invalid_o,
  output logic [15:0] sound_address_o,
  output logic        sound_address_valid_o,
  output logic [3:0]  sound_rom_block_o,
  output logic        sound_rom_block_valid_o,
  input  logic [11:0] sound_rom_present_i,
  output logic        sound_rom_request_o,
  output logic [3:0]  sound_rom_request_block_o,
  output logic [15:0] sound_rom_request_address_o,
  input  logic [7:0]  sound_rom_byte_i,
  input  logic        sound_rom_byte_ready_i,
  output logic        sound_rom_selection_invalid_o,
  output logic [11:0] dac_code_o,
  output logic        dac_code_valid_o,
  output logic        dac_commit_o,
  output logic [7:0]  cport_latch_data_o,
  output logic        cport_latch_data_valid_o,
  output logic        cport_latch_commit_o,
  output logic [15:0] host_320_port_read_data_o,
  output logic [15:0] host_320_port_driven_mask_o,
  output logic [15:0] host_320_port_valid_mask_o,
  output logic        mute_net_o,
  output logic        mute_commit_o,
  output logic        irq_68000_o,

  input  logic        debug_data_write_i,
  input  logic [7:0]  debug_data_address_i,
  input  logic [15:0] debug_data_i,
  output logic [7:0]  debug_data_address_o,
  output logic        debug_data_read_o,
  output logic        debug_data_write_o,
  output logic        debug_data_address_valid_o,
  output logic [7:0]  debug_data_write_address_o,
  output logic [15:0] debug_data_read_data_o,
  output logic [15:0] debug_data_write_data_o,

  output logic        reset_active_o,
  output logic        memory_wait_o,
  output logic        phase_advance_o,
  output logic [1:0]  phase_o,
  output logic        clkout_o,
  output logic [11:0] native_address_o,
  output logic        native_men_n_o,
  output logic        native_den_n_o,
  output logic        native_we_n_o,
  output logic        native_sample_o,
  output logic        native_bus_active_o,
  output logic        tms_access_permitted_o,

  output logic        execute_valid_o,
  output logic [11:0] execute_address_o,
  output logic [15:0] execute_word_o,
  output logic        pipeline_blocked_o,
  output logic [11:0] pc_o,
  output logic [31:0] accumulator_o,
  output logic [15:0] t_register_o,
  output logic [31:0] product_register_o,
  output logic [15:0] auxiliary_register_0_o,
  output logic [15:0] auxiliary_register_1_o,
  output logic        auxiliary_register_pointer_o,
  output logic        data_page_pointer_o,
  output logic [11:0] stack_top_o,
  output logic [11:0] stack_level_1_o,
  output logic [11:0] stack_level_2_o,
  output logic [11:0] stack_bottom_o,
  output logic        overflow_flag_o,
  output logic        overflow_mode_o,
  output logic        interrupt_mask_o,
  output logic        interrupt_pending_o,
  output logic        instruction_valid_o,
  output logic        retired_o,
  output logic        illegal_o,
  output logic [31:0] cycle_count_o
);
  logic        logical_program_read;
  logic        logical_program_write;
  logic [15:0] logical_program_write_data;
  logic        logical_program_ready;
  logic [2:0]  logical_io_port;
  logic        logical_io_read;
  logic        logical_io_write;
  logic [15:0] logical_io_write_data;
  logic        ram_tms_program_read;
  logic        ram_tms_program_write;
  logic        ram_tms_program_ready;
  logic [15:0] ram_tms_read_data;
  logic        ram_tms_commit;
  logic [15:0] native_write_data;
  logic        port_region;
  logic        program_ram_select_n;
  logic [15:0] communication_port_1_read_data;
  logic        communication_port_1_ready;
  logic [15:0] sound_rom_port_0_read_data;
  logic        sound_rom_port_0_ready;
  logic [15:0] selected_io_read_data;
  logic        selected_io_ready;
  logic        bio_clkout_rise;
  logic [15:0] sound_cpu_mailbox_read_driven_mask;
  logic [15:0] sound_cpu_mailbox_read_valid_mask;
  logic        host_timing_cycle_complete_event;
  logic        host_timing_read_complete_event;
  logic        host_timing_write_complete_event;
  logic        host_timing_whole_word_write;
  logic        selected_host_latch_write_commit;
  logic [3:0]  selected_host_latch_address;
  logic        selected_host_irq_clear_commit;
  logic        selected_sound_cpu_mailbox_read_commit;
  logic        selected_sound_cpu_mailbox_write_commit;
  logic [15:0] selected_sound_cpu_mailbox_write_data;
  logic        selected_sound_cpu_low_read_select_valid;
  logic [1:0]  selected_sound_cpu_low_read_quadrant;
  logic        selected_host_program_select_n;
  logic        selected_host_program_write;
  logic        selected_host_program_commit;
  logic [11:0] selected_host_program_address;
  logic [15:0] selected_host_program_write_data;
  logic        selected_host_communication_select_n;
  logic        selected_host_communication_write;
  logic        selected_host_communication_commit;
  logic [8:0]  selected_host_communication_address;
  logic [15:0] selected_host_communication_write_data;
  logic        bridge_host_program_select_n;
  logic        bridge_host_program_ram_select_n;
  logic        bridge_host_program_ram_read;
  logic        bridge_host_program_ram_write;
  logic        bridge_host_program_ram_write_commit;
  logic        bridge_host_communication_select_n;
  logic        bridge_host_communication_read;
  logic        bridge_host_communication_write;
  logic        bridge_host_communication_write_commit;
  logic [8:0]  bridge_host_communication_address;
  logic [7:0]  bridge_high_bank_select_n;
  logic        bridge_rvf_select_n;
  logic        bridge_local_ram_select_n;

  assign selected_bio_n_o = use_board_bio_i ? board_bio_n_o : bio_i;
  assign selected_bio_valid_o = !use_board_bio_i || board_bio_valid_o;
  assign selected_dsp_reset_n_o =
    use_host_control_i ? host_latch_q_o[4] : dsp_reset_n_i;
  assign selected_dsp_reset_valid_o =
    !use_host_control_i || host_latch_valid_o[4];
  assign selected_communication_host_enable_o =
    use_host_control_i
      ? host_latch_q_o[3]
      : communication_host_enable_i;
  assign selected_communication_host_enable_valid_o =
    !use_host_control_i || host_latch_valid_o[3];
  // CLKOUT is low in modeled phases 0/1 and high in phases 2/3, so an
  // enabled phase-1 advance is its rising sampling boundary.
  assign bio_clkout_rise = phase_advance_o && (phase_o == 2'd1);
  assign sound_cpu_mailbox_read_driven_mask = 16'hffff;
  assign sound_cpu_mailbox_read_valid_mask =
    {16{sound_cpu_mailbox_read_data_valid_o}};
  assign host_timing_whole_word_write =
    !host_timing_latched_upper_data_strobe_n_o &&
    !host_timing_latched_lower_data_strobe_n_o;
  assign selected_host_latch_write_commit =
    use_host_timing_i
      ? (host_timing_write_complete_event &&
         (host_timing_select_quadrant_o == 2'b01))
      : host_latch_write_commit_i;
  assign selected_host_latch_address =
    use_host_timing_i
      ? host_timing_latched_address_o[4:1]
      : host_latch_address_i;
  assign selected_host_irq_clear_commit =
    use_host_timing_i
      ? (host_timing_write_complete_event &&
         (host_timing_select_quadrant_o == 2'b11))
      : host_irq_clear_commit_i;
  assign selected_sound_cpu_mailbox_read_commit =
    use_host_timing_i
      ? (host_timing_read_complete_event &&
         (host_timing_select_quadrant_o == 2'b00))
      : sound_cpu_mailbox_read_commit_i;
  assign selected_sound_cpu_mailbox_write_commit =
    use_host_timing_i
      ? (host_timing_write_complete_event &&
         (host_timing_select_quadrant_o == 2'b00) &&
         host_timing_whole_word_write)
      : sound_cpu_mailbox_write_commit_i;
  assign selected_sound_cpu_mailbox_write_data =
    use_host_timing_i
      ? host_bus_write_data_i
      : sound_cpu_mailbox_write_data_i;
  assign selected_sound_cpu_low_read_select_valid =
    use_host_timing_i
      ? host_timing_read_select_valid_o
      : sound_cpu_low_read_select_valid_i;
  assign selected_sound_cpu_low_read_quadrant =
    use_host_timing_i
      ? host_timing_select_quadrant_o
      : sound_cpu_low_read_quadrant_i;
  assign host_timing_speech_write_complete_o =
    use_host_timing_i && host_timing_write_complete_o &&
    (host_timing_select_quadrant_o == 2'b10);
  assign host_timing_partial_sound_write_o =
    use_host_timing_i && host_timing_write_complete_o &&
    (host_timing_select_quadrant_o == 2'b00) &&
    !host_timing_whole_word_write;
  assign host_timing_partial_program_write_o =
    use_host_timing_i && host_timing_cycle_complete_o &&
    !host_timing_latched_read_not_write_o &&
    host_timing_latched_address_o[23] &&
    (host_timing_latched_address_o[16:14] == 3'b101) &&
    !host_timing_latched_address_o[13] &&
    !host_timing_whole_word_write;
  assign host_timing_partial_communication_write_o =
    use_host_timing_i && host_timing_cycle_complete_o &&
    !host_timing_latched_read_not_write_o &&
    host_timing_latched_address_o[23] &&
    (host_timing_latched_address_o[16:14] == 3'b110) &&
    !host_timing_whole_word_write;
  assign selected_host_program_select_n =
    use_host_timing_i
      ? bridge_host_program_ram_select_n
      : host_program_select_n_i;
  assign selected_host_program_write =
    use_host_timing_i
      ? bridge_host_program_ram_write
      : host_write_i;
  assign selected_host_program_commit =
    use_host_timing_i
      ? (bridge_host_program_ram_write_commit &&
         host_timing_whole_word_write)
      : host_commit_i;
  assign selected_host_program_address =
    use_host_timing_i
      ? host_timing_program_io_word_address_o
      : host_address_i;
  assign selected_host_program_write_data =
    use_host_timing_i ? host_bus_write_data_i : host_write_data_i;
  assign selected_host_communication_select_n =
    use_host_timing_i
      ? bridge_host_communication_select_n
      : host_communication_select_n_i;
  assign selected_host_communication_write =
    use_host_timing_i
      ? bridge_host_communication_write
      : host_communication_write_i;
  assign selected_host_communication_commit =
    use_host_timing_i
      ? (bridge_host_communication_write_commit &&
         host_timing_whole_word_write)
      : host_communication_commit_i;
  assign selected_host_communication_address =
    use_host_timing_i
      ? bridge_host_communication_address
      : host_communication_address_i;
  assign selected_host_communication_write_data =
    use_host_timing_i
      ? host_bus_write_data_i
      : host_communication_write_data_i;

  assign native_write_data =
    logical_program_write
      ? logical_program_write_data
      : logical_io_write_data;

  // A logical TBLW is acknowledged by the physical target selected from the
  // shared native address/WE bus. Addresses 0..7 therefore use I/O readiness;
  // all other TBLW addresses use program-RAM readiness.
  always_comb begin
    logical_program_ready = 1'b0;
    if (logical_program_read) begin
      logical_program_ready = ram_tms_program_ready;
    end else if (logical_program_write) begin
      if (ram_tms_program_write) begin
        logical_program_ready = ram_tms_program_ready;
      end else if (io_write_o) begin
        logical_program_ready = selected_io_ready;
      end
    end
  end

  // Port 0 is served by the parallel sample-ROM adapter and port 1 by the
  // internal communication-RAM path. The port-3 LS374 and port-0/4/5 output
  // latches have no wait input; remaining targets stay on the external
  // callback. Physical request/commit signals remain visible for tracing.
  always_comb begin
    selected_io_read_data = io_read_data_i;
    selected_io_ready     = io_ready_i;
    if (io_read_o && (io_port_o == 3'd0)) begin
      selected_io_read_data = sound_rom_port_0_read_data;
      selected_io_ready     = sound_rom_port_0_ready;
    end else if (io_read_o && (io_port_o == 3'd1)) begin
      selected_io_read_data = communication_port_1_read_data;
      selected_io_ready     = communication_port_1_ready;
    end else if (io_write_o && (
      (io_port_o == 3'd0) ||
      (io_port_o == 3'd3) ||
      (io_port_o == 3'd4) ||
      (io_port_o == 3'd5)
    )) begin
      // /DACL and the port-4/5 LS74 paths have no wait inputs. Their internal
      // state/commit outputs replace external callback backpressure.
      selected_io_ready = 1'b1;
    end
  end

  assign io_write_data_o = native_write_data;
  assign io_commit_o =
    phase_advance_o &&
    (phase_o == 2'd3) &&
    selected_io_ready &&
    (io_read_o || io_write_o);
  assign ram_tms_commit =
    phase_advance_o &&
    (phase_o == 2'd3) &&
    ram_tms_program_ready;

  hard_drivin_sound_program_ram program_ram_adapter (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .dsp_reset_n_i                 (selected_dsp_reset_n_o),
    .host_program_select_n_i       (selected_host_program_select_n),
    .host_write_i                  (selected_host_program_write),
    .host_commit_i                 (selected_host_program_commit),
    .host_address_i                (selected_host_program_address),
    .host_write_data_i             (selected_host_program_write_data),
    .host_read_data_o              (host_read_data_o),
    .host_ready_o                  (host_ready_o),
    .host_access_permitted_o       (host_access_permitted_o),
    .tms_address_i                 (native_address_o),
    .tms_men_n_i                   (native_men_n_o),
    .tms_den_n_i                   (native_den_n_o),
    .tms_we_n_i                    (native_we_n_o),
    .tms_commit_i                  (ram_tms_commit),
    .tms_write_data_i              (native_write_data),
    .tms_read_data_o               (ram_tms_read_data),
    .tms_program_ready_o           (ram_tms_program_ready),
    .tms_access_permitted_o        (tms_access_permitted_o),
    .ownership_conflict_o          (ownership_conflict_o),
    .port_region_o                 (port_region),
    .io_port_o                     (io_port_o),
    .io_read_o                     (io_read_o),
    .io_write_o                    (io_write_o),
    .tms_program_read_o            (ram_tms_program_read),
    .tms_program_write_o           (ram_tms_program_write),
    .tms_program_ram_select_n_o    (program_ram_select_n)
  );

  hard_drivin_sound_communication_path communication_path (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .communication_host_enable_i   (selected_communication_host_enable_o),
    .host_select_n_i               (selected_host_communication_select_n),
    .host_write_i                  (selected_host_communication_write),
    .host_commit_i                 (selected_host_communication_commit),
    .host_address_i                (selected_host_communication_address),
    .host_write_data_i             (selected_host_communication_write_data),
    .host_read_data_o              (host_communication_read_data_o),
    .host_ready_o                  (host_communication_ready_o),
    .host_access_permitted_o       (host_communication_access_permitted_o),
    .host_blocked_o                (host_communication_blocked_o),
    .io_port_i                     (io_port_o),
    .io_read_i                     (io_read_o),
    .io_write_i                    (io_write_o),
    .io_write_data_i               (io_write_data_o),
    .io_commit_i                   (io_commit_o),
    .port_1_read_data_o            (communication_port_1_read_data),
    .port_1_ready_o                (communication_port_1_ready),
    .port_1_blocked_o              (port_1_blocked_o),
    .port_1_address_invalid_o      (port_1_address_invalid_o),
    .sound_address_o               (sound_address_o),
    .sound_address_valid_o         (sound_address_valid_o),
    .sound_rom_block_o             (sound_rom_block_o),
    .sound_rom_block_valid_o       (sound_rom_block_valid_o)
  );

  hard_drivin_sound_rom_path sound_rom_path (
    .io_port_i                     (io_port_o),
    .io_read_i                     (io_read_o),
    .sound_address_i               (sound_address_o),
    .sound_address_valid_i         (sound_address_valid_o),
    .sound_rom_block_i             (sound_rom_block_o),
    .sound_rom_block_valid_i       (sound_rom_block_valid_o),
    .sound_rom_present_i           (sound_rom_present_i),
    .sound_rom_request_o           (sound_rom_request_o),
    .sound_rom_request_block_o     (sound_rom_request_block_o),
    .sound_rom_request_address_o   (sound_rom_request_address_o),
    .sound_rom_byte_i              (sound_rom_byte_i),
    .sound_rom_byte_ready_i        (sound_rom_byte_ready_i),
    .port_0_read_data_o            (sound_rom_port_0_read_data),
    .port_0_ready_o                (sound_rom_port_0_ready),
    .sound_rom_selection_invalid_o (sound_rom_selection_invalid_o)
  );

  hard_drivin_sound_dac_latch dac_latch (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .io_port_i                     (io_port_o),
    .io_write_i                    (io_write_o),
    .io_write_data_i               (io_write_data_o),
    .io_commit_i                   (io_commit_o),
    .dac_code_o                    (dac_code_o),
    .dac_code_valid_o              (dac_code_valid_o),
    .dac_commit_o                  (dac_commit_o)
  );

  hard_drivin_sound_320_port_latch cport_latch (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .io_port_i                     (io_port_o),
    .io_write_i                    (io_write_o),
    .io_write_data_i               (io_write_data_o),
    .io_commit_i                   (io_commit_o),
    .latch_data_o                  (cport_latch_data_o),
    .latch_data_valid_o            (cport_latch_data_valid_o),
    .latch_commit_o                (cport_latch_commit_o),
    .host_read_data_o              (host_320_port_read_data_o),
    .host_driven_mask_o            (host_320_port_driven_mask_o),
    .host_valid_mask_o             (host_320_port_valid_mask_o)
  );

  hard_drivin_sound_output_control output_control (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .dsp_reset_n_i                 (selected_dsp_reset_n_o),
    .io_port_i                     (io_port_o),
    .io_write_i                    (io_write_o),
    .io_write_data_i               (io_write_data_o),
    .io_commit_i                   (io_commit_o),
    .host_irq_clear_commit_i       (selected_host_irq_clear_commit),
    .mute_net_o                    (mute_net_o),
    .mute_commit_o                 (mute_commit_o),
    .irq_68000_o                   (irq_68000_o)
  );

  hard_drivin_sound_bio_generator bio_generator (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .board_reset_n_i               (board_reset_n_i),
    .one_mhz_rise_i                (bio_one_mhz_rise_i),
    .clkout_rise_i                 (bio_clkout_rise),
    .counter_seed_i                (bio_counter_seed_i),
    .counter_seed_valid_i          (bio_counter_seed_valid_i),
    .divider_state_o               (bio_divider_state_o),
    .divider_phase_valid_o         (bio_divider_phase_valid_o),
    .raw_320bio_n_o                (raw_320bio_n_o),
    .raw_320bio_valid_o            (raw_320bio_valid_o),
    .bio_n_o                       (board_bio_n_o),
    .bio_valid_o                   (board_bio_valid_o)
  );

  hard_drivin_sound_host_timing host_timing (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .host_8mhz_rise_i              (host_8mhz_rise_i),
    .host_8mhz_fall_i              (host_8mhz_fall_i),
    .address_strobe_assert_i       (host_address_strobe_assert_i),
    .address_strobe_deassert_i     (host_address_strobe_deassert_i),
    .function_code_i               (host_function_code_i),
    .address_i                     (host_bus_address_i),
    .read_not_write_i              (host_read_not_write_i),
    .upper_data_strobe_n_i         (host_upper_data_strobe_n_i),
    .lower_data_strobe_n_i         (host_lower_data_strobe_n_i),
    .cycle_active_o                (host_timing_cycle_active_o),
    .rva_o                         (host_timing_rva_o),
    .vpa_n_o                       (host_timing_vpa_n_o),
    .dtack_n_o                     (host_timing_dtack_n_o),
    .rvas_n_o                      (host_timing_rvas_n_o),
    .rvf_n_o                       (host_timing_rvf_n_o),
    .read_write_strobe_n_o         (host_timing_read_write_strobe_n_o),
    .upper_write_enable_n_o        (host_timing_upper_write_enable_n_o),
    .lower_write_enable_n_o        (host_timing_lower_write_enable_n_o),
    .read_select_valid_o           (host_timing_read_select_valid_o),
    .write_select_valid_o          (host_timing_write_select_valid_o),
    .latched_address_o             (host_timing_latched_address_o),
    .latched_read_not_write_o      (
      host_timing_latched_read_not_write_o
    ),
    .latched_upper_data_strobe_n_o (
      host_timing_latched_upper_data_strobe_n_o
    ),
    .latched_lower_data_strobe_n_o (
      host_timing_latched_lower_data_strobe_n_o
    ),
    .select_quadrant_o             (host_timing_select_quadrant_o),
    .target_select_o               (host_timing_target_select_o),
    .cycle_complete_event_o        (host_timing_cycle_complete_event),
    .read_complete_event_o         (host_timing_read_complete_event),
    .write_complete_event_o        (host_timing_write_complete_event),
    .cycle_complete_o              (host_timing_cycle_complete_o),
    .read_complete_o               (host_timing_read_complete_o),
    .write_complete_o              (host_timing_write_complete_o)
  );

  hard_drivin_sound_local_memory_bridge local_memory_bridge (
    .host_8mhz_rise_i                    (host_8mhz_rise_i),
    .cycle_active_i                      (
      use_host_timing_i && host_timing_cycle_active_o
    ),
    .rva_i                               (host_timing_rva_o),
    .rvas_n_i                            (host_timing_rvas_n_o),
    .cycle_complete_event_i              (
      use_host_timing_i && host_timing_cycle_complete_event
    ),
    .latched_address_i                   (host_timing_latched_address_o),
    .latched_read_not_write_i            (
      host_timing_latched_read_not_write_o
    ),
    .latched_upper_data_strobe_n_i       (
      host_timing_latched_upper_data_strobe_n_o
    ),
    .latched_lower_data_strobe_n_i       (
      host_timing_latched_lower_data_strobe_n_o
    ),
    .host_write_data_i                   (host_bus_write_data_i),
    .rom_read_request_o                  (host_local_rom_read_request_o),
    .rom_word_address_o                  (host_local_rom_word_address_o),
    .rom_read_data_i                     (host_local_rom_read_data_i),
    .rom_read_data_valid_i               (
      host_local_rom_read_data_valid_i
    ),
    .local_ram_read_request_o            (host_local_ram_read_request_o),
    .local_ram_word_address_o            (host_local_ram_word_address_o),
    .local_ram_read_data_i               (host_local_ram_read_data_i),
    .local_ram_read_valid_mask_i         (
      host_local_ram_read_valid_mask_i
    ),
    .local_ram_upper_write_commit_o      (
      host_local_ram_upper_write_commit_o
    ),
    .local_ram_lower_write_commit_o      (
      host_local_ram_lower_write_commit_o
    ),
    .local_ram_write_data_o              (host_local_ram_write_data_o),
    .host_program_select_n_o             (bridge_host_program_select_n),
    .host_program_ram_select_n_o         (
      bridge_host_program_ram_select_n
    ),
    .host_program_ram_read_o             (bridge_host_program_ram_read),
    .host_program_ram_write_o            (bridge_host_program_ram_write),
    .host_program_ram_write_commit_o     (
      bridge_host_program_ram_write_commit
    ),
    .host_program_word_address_o         (
      host_timing_program_io_word_address_o
    ),
    .host_program_io_read_o              (host_timing_program_io_read_o),
    .host_program_io_write_o             (host_timing_program_io_write_o),
    .host_program_io_write_commit_o      (
      host_timing_program_io_write_commit_o
    ),
    .host_communication_select_n_o       (
      bridge_host_communication_select_n
    ),
    .host_communication_read_o           (bridge_host_communication_read),
    .host_communication_write_o          (bridge_host_communication_write),
    .host_communication_write_commit_o   (
      bridge_host_communication_write_commit
    ),
    .host_communication_word_address_o   (
      bridge_host_communication_address
    ),
    .host_read_data_o                    (host_local_memory_read_data_o),
    .host_read_driven_mask_o             (
      host_local_memory_read_driven_mask_o
    ),
    .host_read_valid_mask_o              (
      host_local_memory_read_valid_mask_o
    ),
    .host_read_target_select_o           (
      host_local_memory_read_target_select_o
    ),
    .host_read_response_missing_event_o  (
      host_local_memory_read_missing_o
    ),
    .high_bank_select_n_o                (bridge_high_bank_select_n),
    .rvf_select_n_o                      (bridge_rvf_select_n),
    .local_ram_select_n_o                (bridge_local_ram_select_n)
  );

  hard_drivin_sound_host_control host_control (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .board_reset_n_i               (board_reset_n_i),
    .latch_write_commit_i          (selected_host_latch_write_commit),
    .latch_address_i               (selected_host_latch_address),
    .latch_q_o                     (host_latch_q_o),
    .latch_valid_o                 (host_latch_valid_o)
  );

  hard_drivin_sound_mailboxes mailboxes (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize_i),
    .board_reset_n_i               (board_reset_n_i),
    .main_write_commit_i           (main_mailbox_write_commit_i),
    .main_write_data_i             (main_mailbox_write_data_i),
    .sound_read_commit_i           (selected_sound_cpu_mailbox_read_commit),
    .main_to_sound_data_o          (sound_cpu_mailbox_read_data_o),
    .main_to_sound_data_valid_o    (sound_cpu_mailbox_read_data_valid_o),
    .main_flag_o                   (main_flag_o),
    .main_flag_valid_o             (main_flag_valid_o),
    .main_flag_conflict_o          (main_flag_conflict_o),
    .sound_write_commit_i          (selected_sound_cpu_mailbox_write_commit),
    .sound_write_data_i            (selected_sound_cpu_mailbox_write_data),
    .main_read_commit_i            (main_mailbox_read_commit_i),
    .sound_to_main_data_o          (main_mailbox_read_data_o),
    .sound_to_main_data_valid_o    (main_mailbox_read_data_valid_o),
    .sound_flag_o                  (sound_flag_o),
    .sound_flag_valid_o            (sound_flag_valid_o),
    .sound_flag_conflict_o         (sound_flag_conflict_o)
  );

  hard_drivin_sound_read_status read_status (
    .main_flag_i                   (main_flag_o),
    .main_flag_valid_i             (main_flag_valid_o),
    .sound_flag_i                  (sound_flag_o),
    .sound_flag_valid_i            (sound_flag_valid_o),
    .sound_test_i                  (sound_test_i),
    .sound_test_valid_i            (sound_test_valid_i),
    .tirdy_n_i                     (tirdy_n_i),
    .tirdy_n_valid_i               (tirdy_n_valid_i),
    .host_read_data_o              (sound_cpu_read_status_data_o),
    .host_driven_mask_o            (sound_cpu_read_status_driven_mask_o),
    .host_valid_mask_o             (sound_cpu_read_status_valid_mask_o)
  );

  hard_drivin_sound_switches switches (
    .j3_switch_i                   (j3_switch_i),
    .j3_switch_valid_i             (j3_switch_valid_i),
    .host_read_data_o              (sound_cpu_switches_data_o),
    .host_driven_mask_o            (sound_cpu_switches_driven_mask_o),
    .host_valid_mask_o             (sound_cpu_switches_valid_mask_o)
  );

  hard_drivin_sound_host_read_mux host_read_mux (
    .read_select_valid_i           (selected_sound_cpu_low_read_select_valid),
    .read_quadrant_i               (selected_sound_cpu_low_read_quadrant),
    .sound_read_data_i             (sound_cpu_mailbox_read_data_o),
    .sound_read_driven_mask_i      (sound_cpu_mailbox_read_driven_mask),
    .sound_read_valid_mask_i       (sound_cpu_mailbox_read_valid_mask),
    .port_320_data_i               (host_320_port_read_data_o),
    .port_320_driven_mask_i        (host_320_port_driven_mask_o),
    .port_320_valid_mask_i         (host_320_port_valid_mask_o),
    .switches_data_i               (sound_cpu_switches_data_o),
    .switches_driven_mask_i        (sound_cpu_switches_driven_mask_o),
    .switches_valid_mask_i         (sound_cpu_switches_valid_mask_o),
    .read_status_data_i            (sound_cpu_read_status_data_o),
    .read_status_driven_mask_i     (sound_cpu_read_status_driven_mask_o),
    .read_status_valid_mask_i      (sound_cpu_read_status_valid_mask_o),
    .host_read_data_o              (sound_cpu_low_read_data_o),
    .host_driven_mask_o            (sound_cpu_low_read_driven_mask_o),
    .host_valid_mask_o             (sound_cpu_low_read_valid_mask_o),
    .target_select_o               (sound_cpu_low_read_target_select_o)
  );

  tms32010_mister processor (
    .clk_i                         (clk_i),
    .reset_i                       (initialize_i),
    .processor_reset_i             (!selected_dsp_reset_n_o),
    .clock_enable_i                (clock_enable_i),
    .bio_i                         (selected_bio_n_o),
    .int_i                         (1'b1),
    .program_address_o             (native_address_o),
    .program_read_o                (logical_program_read),
    .program_write_o               (logical_program_write),
    .program_write_data_o          (logical_program_write_data),
    .program_read_data_i           (ram_tms_read_data),
    .program_ready_i               (logical_program_ready),
    .io_port_o                     (logical_io_port),
    .io_read_o                     (logical_io_read),
    .io_write_o                    (logical_io_write),
    .io_write_data_o               (logical_io_write_data),
    .io_read_data_i                (selected_io_read_data),
    .io_ready_i                    (selected_io_ready),
    .debug_data_write_i            (debug_data_write_i),
    .debug_data_address_i          (debug_data_address_i),
    .debug_data_i                  (debug_data_i),
    .debug_data_address_o          (debug_data_address_o),
    .debug_data_read_o             (debug_data_read_o),
    .debug_data_write_o            (debug_data_write_o),
    .debug_data_address_valid_o    (debug_data_address_valid_o),
    .debug_data_write_address_o    (debug_data_write_address_o),
    .debug_data_read_data_o        (debug_data_read_data_o),
    .debug_data_write_data_o       (debug_data_write_data_o),
    .reset_active_o                (reset_active_o),
    .memory_wait_o                 (memory_wait_o),
    .phase_advance_o               (phase_advance_o),
    .phase_o                       (phase_o),
    .clkout_o                      (clkout_o),
    .native_men_n_o                (native_men_n_o),
    .native_den_n_o                (native_den_n_o),
    .native_we_n_o                 (native_we_n_o),
    .native_sample_o               (native_sample_o),
    .native_bus_active_o           (native_bus_active_o),
    .execute_valid_o               (execute_valid_o),
    .execute_address_o             (execute_address_o),
    .execute_word_o                (execute_word_o),
    .pipeline_blocked_o            (pipeline_blocked_o),
    .pc_o                          (pc_o),
    .accumulator_o                 (accumulator_o),
    .t_register_o                  (t_register_o),
    .product_register_o            (product_register_o),
    .auxiliary_register_0_o        (auxiliary_register_0_o),
    .auxiliary_register_1_o        (auxiliary_register_1_o),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer_o),
    .data_page_pointer_o           (data_page_pointer_o),
    .stack_top_o                    (stack_top_o),
    .stack_level_1_o                (stack_level_1_o),
    .stack_level_2_o                (stack_level_2_o),
    .stack_bottom_o                 (stack_bottom_o),
    .overflow_flag_o               (overflow_flag_o),
    .overflow_mode_o               (overflow_mode_o),
    .interrupt_mask_o              (interrupt_mask_o),
    .interrupt_pending_o           (interrupt_pending_o),
    .instruction_valid_o           (instruction_valid_o),
    .retired_o                     (retired_o),
    .illegal_o                     (illegal_o),
    .cycle_count_o                 (cycle_count_o)
  );

  always_ff @(posedge clk_i) begin
    if (!initialize_i) begin
      assert (!ownership_conflict_o || (
        !host_access_permitted_o && !tms_access_permitted_o
      ));
      assert (!logical_program_write ||
              (ram_tms_program_write || io_write_o));
      assert (!logical_program_read || ram_tms_program_read);
      assert (!io_write_o || (logical_io_write || logical_program_write));
      assert (!logical_io_read || io_read_o);
      assert (selected_bio_n_o ==
              (use_board_bio_i ? board_bio_n_o : bio_i));
      assert (selected_bio_valid_o ==
              (!use_board_bio_i || board_bio_valid_o));
      assert (selected_dsp_reset_n_o ==
              (use_host_control_i ? host_latch_q_o[4] : dsp_reset_n_i));
      assert (selected_dsp_reset_valid_o ==
              (!use_host_control_i || host_latch_valid_o[4]));
      assert (selected_communication_host_enable_o ==
              (use_host_control_i
                 ? host_latch_q_o[3]
                 : communication_host_enable_i));
      assert (selected_communication_host_enable_valid_o ==
              (!use_host_control_i || host_latch_valid_o[3]));
      assert (sound_cpu_read_status_driven_mask_o == 16'hf000);
      assert (sound_cpu_read_status_valid_mask_o[15] == main_flag_valid_o);
      assert (sound_cpu_read_status_valid_mask_o[14] == sound_flag_valid_o);
      assert (sound_cpu_read_status_data_o[15] ==
              (main_flag_valid_o && main_flag_o));
      assert (sound_cpu_read_status_data_o[14] ==
              (sound_flag_valid_o && sound_flag_o));
      assert (sound_cpu_switches_driven_mask_o == 16'hf000);
      assert (sound_cpu_switches_valid_mask_o ==
              {j3_switch_valid_i, 12'h000});
      assert (!selected_sound_cpu_low_read_select_valid ||
              $onehot(sound_cpu_low_read_target_select_o));
      assert ($onehot0(host_timing_target_select_o));
      assert (!(host_timing_read_complete_event &&
                host_timing_write_complete_event));
      assert (!host_timing_read_complete_event ||
              host_timing_cycle_complete_event);
      assert (!host_timing_write_complete_event ||
              host_timing_cycle_complete_event);
      assert (!host_timing_partial_sound_write_o ||
              !selected_sound_cpu_mailbox_write_commit);
      assert (!host_timing_partial_program_write_o ||
              (host_timing_cycle_complete_o &&
               !selected_host_program_commit));
      assert (!host_timing_partial_communication_write_o ||
              (host_timing_cycle_complete_o &&
               !selected_host_communication_commit));
      assert ($onehot0(~bridge_high_bank_select_n));
      assert (bridge_rvf_select_n == bridge_high_bank_select_n[4]);
      assert (bridge_local_ram_select_n == bridge_high_bank_select_n[7]);
      assert (bridge_host_program_ram_select_n ||
              !bridge_host_program_select_n);
      assert (!host_timing_program_io_read_o ||
              !bridge_host_program_select_n);
      assert (!host_timing_program_io_write_o ||
              !bridge_host_program_select_n);
      assert ((host_local_memory_read_valid_mask_o &
               ~host_local_memory_read_driven_mask_o) == 16'h0000);
      assert ((host_local_memory_read_data_o &
               ~host_local_memory_read_valid_mask_o) == 16'h0000);
      if (use_host_timing_i) begin
        assert (selected_sound_cpu_low_read_select_valid ==
                host_timing_read_select_valid_o);
        assert (selected_sound_cpu_low_read_quadrant ==
                host_timing_select_quadrant_o);
        assert (selected_sound_cpu_mailbox_read_commit ==
                (host_timing_read_complete_event &&
                 (host_timing_select_quadrant_o == 2'b00)));
        assert (selected_sound_cpu_mailbox_write_commit ==
                (host_timing_write_complete_event &&
                 (host_timing_select_quadrant_o == 2'b00) &&
                 host_timing_whole_word_write));
        assert (selected_host_latch_write_commit ==
                (host_timing_write_complete_event &&
                 (host_timing_select_quadrant_o == 2'b01)));
        assert (selected_host_irq_clear_commit ==
                (host_timing_write_complete_event &&
                 (host_timing_select_quadrant_o == 2'b11)));
        assert (selected_host_program_select_n ==
                bridge_host_program_ram_select_n);
        assert (selected_host_program_write ==
                bridge_host_program_ram_write);
        assert (selected_host_program_commit ==
                (bridge_host_program_ram_write_commit &&
                 host_timing_whole_word_write));
        assert (selected_host_program_address ==
                host_timing_program_io_word_address_o);
        assert (selected_host_program_write_data ==
                host_bus_write_data_i);
        assert (selected_host_communication_select_n ==
                bridge_host_communication_select_n);
        assert (selected_host_communication_write ==
                bridge_host_communication_write);
        assert (selected_host_communication_commit ==
                (bridge_host_communication_write_commit &&
                 host_timing_whole_word_write));
        assert (selected_host_communication_address ==
                bridge_host_communication_address);
        assert (selected_host_communication_write_data ==
                host_bus_write_data_i);
        assert (bridge_host_program_ram_read ==
                (!bridge_host_program_ram_select_n &&
                 host_timing_latched_read_not_write_o));
        assert (bridge_host_communication_read ==
                (!bridge_host_communication_select_n &&
                 host_timing_latched_read_not_write_o));
      end else begin
        assert (selected_sound_cpu_low_read_select_valid ==
                sound_cpu_low_read_select_valid_i);
        assert (selected_sound_cpu_low_read_quadrant ==
                sound_cpu_low_read_quadrant_i);
        assert (selected_sound_cpu_mailbox_read_commit ==
                sound_cpu_mailbox_read_commit_i);
        assert (selected_sound_cpu_mailbox_write_commit ==
                sound_cpu_mailbox_write_commit_i);
        assert (selected_host_latch_write_commit ==
                host_latch_write_commit_i);
        assert (selected_host_irq_clear_commit ==
                host_irq_clear_commit_i);
        assert (selected_host_program_select_n ==
                host_program_select_n_i);
        assert (selected_host_program_write == host_write_i);
        assert (selected_host_program_commit == host_commit_i);
        assert (selected_host_program_address == host_address_i);
        assert (selected_host_program_write_data == host_write_data_i);
        assert (selected_host_communication_select_n ==
                host_communication_select_n_i);
        assert (selected_host_communication_write ==
                host_communication_write_i);
        assert (selected_host_communication_commit ==
                host_communication_commit_i);
        assert (selected_host_communication_address ==
                host_communication_address_i);
        assert (selected_host_communication_write_data ==
                host_communication_write_data_i);
        assert (!host_local_rom_read_request_o);
        assert (!host_local_ram_read_request_o);
        assert (!host_local_ram_upper_write_commit_o);
        assert (!host_local_ram_lower_write_commit_o);
        assert (!host_timing_program_io_read_o);
        assert (!host_timing_program_io_write_o);
        assert (!host_timing_program_io_write_commit_o);
        assert (!host_timing_partial_program_write_o);
        assert (!host_timing_partial_communication_write_o);
      end
      if (!use_board_bio_i) begin
        assert (selected_bio_valid_o);
      end
      if (!use_host_control_i) begin
        assert (selected_dsp_reset_valid_o);
        assert (selected_communication_host_enable_valid_o);
      end
      if (io_read_o || io_write_o) begin
        assert (logical_io_port == io_port_o || logical_program_write);
      end
      if (port_region && !native_we_n_o) begin
        assert (program_ram_select_n);
      end
      if (io_read_o && (io_port_o == 3'd1)) begin
        assert (selected_io_ready == communication_port_1_ready);
        assert (selected_io_read_data == communication_port_1_read_data);
      end
      if (io_read_o && (io_port_o == 3'd0)) begin
        assert (selected_io_ready == sound_rom_port_0_ready);
        assert (selected_io_read_data == sound_rom_port_0_read_data);
        assert (!io_commit_o || sound_rom_request_o);
      end
      if (io_write_o && (
        (io_port_o == 3'd0) ||
        (io_port_o == 3'd3) ||
        (io_port_o == 3'd4) ||
        (io_port_o == 3'd5)
      )) begin
        assert (selected_io_ready);
      end
    end
  end
endmodule

`default_nettype wire
