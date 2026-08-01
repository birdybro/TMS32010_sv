`default_nettype none

module tb_hard_drivin_sound_mister;
  logic        clk;
  logic        initialize;
  logic        clock_enable;
  logic        dsp_reset_n;
  logic        external_bio_n;
  logic        use_board_bio;
  logic        board_reset_n;
  logic        bio_one_mhz_rise;
  logic [7:0]  bio_counter_seed;
  logic        bio_counter_seed_valid;
  logic [7:0]  bio_divider_state;
  logic        bio_divider_phase_valid;
  logic        raw_320bio_n;
  logic        raw_320bio_valid;
  logic        board_bio_n;
  logic        board_bio_valid;
  logic        selected_bio_n;
  logic        selected_bio_valid;
  logic        use_host_control;
  logic        host_latch_write_commit;
  logic [3:0]  host_latch_address;
  logic [7:0]  host_latch_q;
  logic [7:0]  host_latch_valid;
  logic        selected_dsp_reset_n;
  logic        selected_dsp_reset_valid;
  logic        selected_communication_host_enable;
  logic        selected_communication_host_enable_valid;
  logic        use_host_timing;
  logic        host_8mhz_rise;
  logic        host_8mhz_fall;
  logic        host_address_strobe_assert;
  logic        host_address_strobe_deassert;
  logic [2:0]  host_function_code;
  logic [23:1] host_bus_address;
  logic        host_read_not_write;
  logic        host_upper_data_strobe_n;
  logic        host_lower_data_strobe_n;
  logic [15:0] host_bus_write_data;
  logic        host_timing_cycle_active;
  logic        host_timing_rva;
  logic        host_timing_vpa_n;
  logic        host_timing_dtack_n;
  logic        host_timing_rvas_n;
  logic        host_timing_rvf_n;
  logic        host_timing_read_write_strobe_n;
  logic        host_timing_upper_write_enable_n;
  logic        host_timing_lower_write_enable_n;
  logic        host_timing_read_select_valid;
  logic        host_timing_write_select_valid;
  logic [23:1] host_timing_latched_address;
  logic        host_timing_latched_read_not_write;
  logic        host_timing_latched_upper_data_strobe_n;
  logic        host_timing_latched_lower_data_strobe_n;
  logic [1:0]  host_timing_select_quadrant;
  logic [7:0]  host_timing_target_select;
  logic        host_timing_cycle_complete;
  logic        host_timing_read_complete;
  logic        host_timing_write_complete;
  logic        host_timing_speech_write_complete;
  logic        host_timing_partial_sound_write;
  logic        host_timing_partial_program_write;
  logic        host_timing_partial_communication_write;
  logic [15:0] host_local_rom_read_data;
  logic        host_local_rom_read_data_valid;
  logic        host_local_rom_read_request;
  logic [14:0] host_local_rom_word_address;
  logic        use_internal_local_ram;
  logic        local_processor_halt_n_input;
  logic [15:0] host_local_ram_read_data;
  logic [15:0] host_local_ram_read_valid_mask;
  logic        host_local_ram_read_request;
  logic [12:0] host_local_ram_word_address;
  logic        host_local_ram_upper_write_commit;
  logic        host_local_ram_lower_write_commit;
  logic [15:0] host_local_ram_write_data;
  logic        host_local_ram_storage_ready;
  logic        host_local_ram_storage_scrub_active;
  logic [12:0] host_local_ram_storage_scrub_address;
  logic        host_local_ram_storage_write_blocked;
  logic        local_processor_reset_n;
  logic        local_processor_halt_n;
  logic        local_processor_release_blocked;
  logic [15:0] host_local_memory_read_data;
  logic [15:0] host_local_memory_read_driven_mask;
  logic [15:0] host_local_memory_read_valid_mask;
  logic [1:0]  host_local_memory_read_target_select;
  logic        host_local_memory_read_missing;
  logic        host_timing_program_io_read;
  logic        host_timing_program_io_write;
  logic        host_timing_program_io_write_commit;
  logic [11:0] host_timing_program_io_word_address;
  logic [15:0] host_direct_io_read_data;
  logic [15:0] host_direct_io_read_driven_mask;
  logic [15:0] host_direct_io_read_valid_mask;
  logic [3:0]  host_direct_io_read_target_select;
  logic [3:0]  host_direct_io_read_complete_select;
  logic        host_direct_io_read_alias;
  logic [7:0]  host_direct_io_write_target_select;
  logic [7:0]  host_direct_io_write_commit_select;
  logic [15:0] host_direct_io_write_data;
  logic        host_direct_io_write_unselected;
  logic        host_direct_io_write_commit_unselected;
  logic        direct_io_ownership_conflict;
  logic        host_program_select_n;
  logic        host_write;
  logic        host_commit;
  logic [11:0] host_address;
  logic [15:0] host_write_data;
  logic [15:0] host_read_data;
  logic        host_ready;
  logic        host_access_permitted;
  logic        ownership_conflict;
  logic        communication_host_enable;
  logic        host_communication_select_n;
  logic        host_communication_write;
  logic        host_communication_commit;
  logic [8:0]  host_communication_address;
  logic [15:0] host_communication_write_data;
  logic [15:0] host_communication_read_data;
  logic        host_communication_ready;
  logic        host_communication_access_permitted;
  logic        host_communication_blocked;
  logic        host_irq_clear_commit;
  logic        main_mailbox_write_commit;
  logic [15:0] main_mailbox_write_data;
  logic        sound_cpu_mailbox_read_commit;
  logic [15:0] sound_cpu_mailbox_read_data;
  logic        sound_cpu_mailbox_read_data_valid;
  logic        main_flag;
  logic        main_flag_valid;
  logic        main_flag_conflict;
  logic        sound_cpu_mailbox_write_commit;
  logic [15:0] sound_cpu_mailbox_write_data;
  logic        main_mailbox_read_commit;
  logic [15:0] main_mailbox_read_data;
  logic        main_mailbox_read_data_valid;
  logic        sound_flag;
  logic        sound_flag_valid;
  logic        sound_flag_conflict;
  logic        sound_test;
  logic        sound_test_valid;
  logic        tirdy_n;
  logic        tirdy_n_valid;
  logic [15:0] sound_cpu_read_status_data;
  logic [15:0] sound_cpu_read_status_driven_mask;
  logic [15:0] sound_cpu_read_status_valid_mask;
  logic [3:0]  j3_switch;
  logic [3:0]  j3_switch_valid;
  logic [15:0] sound_cpu_switches_data;
  logic [15:0] sound_cpu_switches_driven_mask;
  logic [15:0] sound_cpu_switches_valid_mask;
  logic        sound_cpu_low_read_select_valid;
  logic [1:0]  sound_cpu_low_read_quadrant;
  logic [15:0] sound_cpu_low_read_data;
  logic [15:0] sound_cpu_low_read_driven_mask;
  logic [15:0] sound_cpu_low_read_valid_mask;
  logic [3:0]  sound_cpu_low_read_target_select;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic [15:0] io_write_data;
  logic        io_commit;
  logic [15:0] io_read_data;
  logic        port_1_blocked;
  logic        port_1_address_invalid;
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
  logic        sound_rom_delayed_ready;
  logic        sound_rom_selection_invalid;
  logic [11:0] dac_code;
  logic        dac_code_valid;
  logic        dac_commit;
  logic [7:0]  cport_latch_data;
  logic        cport_latch_data_valid;
  logic        cport_latch_commit;
  logic [15:0] host_320_port_read_data;
  logic [15:0] host_320_port_driven_mask;
  logic [15:0] host_320_port_valid_mask;
  logic        mute_net;
  logic        mute_commit;
  logic        irq_68000;
  logic        external_io_ready;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic        reset_active;
  logic        memory_wait;
  logic        phase_advance;
  logic [1:0]  phase;
  logic        clkout;
  logic [11:0] native_address;
  logic        men_n;
  logic        den_n;
  logic        we_n;
  logic        native_bus_active;
  logic        tms_access_permitted;
  logic        execute_valid;
  logic [11:0] execute_address;
  logic [15:0] execute_word;
  logic        pipeline_blocked;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;

  logic [15:0] output_ports [0:7];
  integer      io_read_count;
  integer      io_write_count;
  integer      sound_rom_commit_count;
  integer      sound_rom_wait_cycles;
  integer      dac_commit_count;
  integer      cport_latch_commit_count;
  integer      mute_commit_count;
  integer      host_local_ram_upper_write_count;
  integer      host_local_ram_lower_write_count;
  integer      host_program_io_write_count;
  integer      host_direct_selected_write_commit_count;
  integer      host_direct_unselected_write_commit_count;
  integer      host_direct_read_complete_count;
  logic        sound_rom_request_seen;

  hard_drivin_sound_mister dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .clock_enable_i                (clock_enable),
    .dsp_reset_n_i                 (dsp_reset_n),
    .bio_i                         (external_bio_n),
    .use_board_bio_i               (use_board_bio),
    .board_reset_n_i               (board_reset_n),
    .bio_one_mhz_rise_i            (bio_one_mhz_rise),
    .bio_counter_seed_i            (bio_counter_seed),
    .bio_counter_seed_valid_i      (bio_counter_seed_valid),
    .bio_divider_state_o           (bio_divider_state),
    .bio_divider_phase_valid_o     (bio_divider_phase_valid),
    .raw_320bio_n_o                (raw_320bio_n),
    .raw_320bio_valid_o            (raw_320bio_valid),
    .board_bio_n_o                 (board_bio_n),
    .board_bio_valid_o             (board_bio_valid),
    .selected_bio_n_o              (selected_bio_n),
    .selected_bio_valid_o          (selected_bio_valid),
    .use_host_control_i            (use_host_control),
    .host_latch_write_commit_i     (host_latch_write_commit),
    .host_latch_address_i          (host_latch_address),
    .host_latch_q_o                (host_latch_q),
    .host_latch_valid_o            (host_latch_valid),
    .selected_dsp_reset_n_o        (selected_dsp_reset_n),
    .selected_dsp_reset_valid_o    (selected_dsp_reset_valid),
    .selected_communication_host_enable_o(
      selected_communication_host_enable
    ),
    .selected_communication_host_enable_valid_o(
      selected_communication_host_enable_valid
    ),
    .use_host_timing_i             (use_host_timing),
    .host_8mhz_rise_i              (host_8mhz_rise),
    .host_8mhz_fall_i              (host_8mhz_fall),
    .host_address_strobe_assert_i  (host_address_strobe_assert),
    .host_address_strobe_deassert_i(host_address_strobe_deassert),
    .host_function_code_i          (host_function_code),
    .host_bus_address_i            (host_bus_address),
    .host_read_not_write_i         (host_read_not_write),
    .host_upper_data_strobe_n_i    (host_upper_data_strobe_n),
    .host_lower_data_strobe_n_i    (host_lower_data_strobe_n),
    .host_bus_write_data_i         (host_bus_write_data),
    .host_timing_cycle_active_o    (host_timing_cycle_active),
    .host_timing_rva_o             (host_timing_rva),
    .host_timing_vpa_n_o           (host_timing_vpa_n),
    .host_timing_dtack_n_o         (host_timing_dtack_n),
    .host_timing_rvas_n_o          (host_timing_rvas_n),
    .host_timing_rvf_n_o           (host_timing_rvf_n),
    .host_timing_read_write_strobe_n_o(
      host_timing_read_write_strobe_n
    ),
    .host_timing_upper_write_enable_n_o(
      host_timing_upper_write_enable_n
    ),
    .host_timing_lower_write_enable_n_o(
      host_timing_lower_write_enable_n
    ),
    .host_timing_read_select_valid_o(host_timing_read_select_valid),
    .host_timing_write_select_valid_o(host_timing_write_select_valid),
    .host_timing_latched_address_o(host_timing_latched_address),
    .host_timing_latched_read_not_write_o(
      host_timing_latched_read_not_write
    ),
    .host_timing_latched_upper_data_strobe_n_o(
      host_timing_latched_upper_data_strobe_n
    ),
    .host_timing_latched_lower_data_strobe_n_o(
      host_timing_latched_lower_data_strobe_n
    ),
    .host_timing_select_quadrant_o(host_timing_select_quadrant),
    .host_timing_target_select_o  (host_timing_target_select),
    .host_timing_cycle_complete_o (host_timing_cycle_complete),
    .host_timing_read_complete_o  (host_timing_read_complete),
    .host_timing_write_complete_o (host_timing_write_complete),
    .host_timing_speech_write_complete_o(
      host_timing_speech_write_complete
    ),
    .host_timing_partial_sound_write_o(host_timing_partial_sound_write),
    .host_timing_partial_program_write_o(
      host_timing_partial_program_write
    ),
    .host_timing_partial_communication_write_o(
      host_timing_partial_communication_write
    ),
    .host_local_rom_read_data_i   (host_local_rom_read_data),
    .host_local_rom_read_data_valid_i(host_local_rom_read_data_valid),
    .host_local_rom_read_request_o(host_local_rom_read_request),
    .host_local_rom_word_address_o(host_local_rom_word_address),
    .use_internal_local_ram_i     (use_internal_local_ram),
    .local_processor_halt_n_i     (local_processor_halt_n_input),
    .host_local_ram_read_data_i   (host_local_ram_read_data),
    .host_local_ram_read_valid_mask_i(host_local_ram_read_valid_mask),
    .host_local_ram_read_request_o(host_local_ram_read_request),
    .host_local_ram_word_address_o(host_local_ram_word_address),
    .host_local_ram_upper_write_commit_o(
      host_local_ram_upper_write_commit
    ),
    .host_local_ram_lower_write_commit_o(
      host_local_ram_lower_write_commit
    ),
    .host_local_ram_write_data_o  (host_local_ram_write_data),
    .host_local_ram_storage_ready_o(host_local_ram_storage_ready),
    .host_local_ram_storage_scrub_active_o(
      host_local_ram_storage_scrub_active
    ),
    .host_local_ram_storage_scrub_address_o(
      host_local_ram_storage_scrub_address
    ),
    .host_local_ram_storage_write_blocked_o(
      host_local_ram_storage_write_blocked
    ),
    .local_processor_reset_n_o    (local_processor_reset_n),
    .local_processor_halt_n_o     (local_processor_halt_n),
    .local_processor_release_blocked_o(
      local_processor_release_blocked
    ),
    .host_local_memory_read_data_o(host_local_memory_read_data),
    .host_local_memory_read_driven_mask_o(
      host_local_memory_read_driven_mask
    ),
    .host_local_memory_read_valid_mask_o(
      host_local_memory_read_valid_mask
    ),
    .host_local_memory_read_target_select_o(
      host_local_memory_read_target_select
    ),
    .host_local_memory_read_missing_o(host_local_memory_read_missing),
    .host_timing_program_io_read_o(host_timing_program_io_read),
    .host_timing_program_io_write_o(host_timing_program_io_write),
    .host_timing_program_io_write_commit_o(
      host_timing_program_io_write_commit
    ),
    .host_timing_program_io_word_address_o(
      host_timing_program_io_word_address
    ),
    .host_direct_io_read_data_o    (host_direct_io_read_data),
    .host_direct_io_read_driven_mask_o(
      host_direct_io_read_driven_mask
    ),
    .host_direct_io_read_valid_mask_o(host_direct_io_read_valid_mask),
    .host_direct_io_read_target_select_o(
      host_direct_io_read_target_select
    ),
    .host_direct_io_read_complete_select_o(
      host_direct_io_read_complete_select
    ),
    .host_direct_io_read_alias_o   (host_direct_io_read_alias),
    .host_direct_io_write_target_select_o(
      host_direct_io_write_target_select
    ),
    .host_direct_io_write_commit_select_o(
      host_direct_io_write_commit_select
    ),
    .host_direct_io_write_data_o   (host_direct_io_write_data),
    .host_direct_io_write_unselected_o(
      host_direct_io_write_unselected
    ),
    .host_direct_io_write_commit_unselected_o(
      host_direct_io_write_commit_unselected
    ),
    .direct_io_ownership_conflict_o(direct_io_ownership_conflict),
    .host_program_select_n_i       (host_program_select_n),
    .host_write_i                  (host_write),
    .host_commit_i                 (host_commit),
    .host_address_i                (host_address),
    .host_write_data_i             (host_write_data),
    .host_read_data_o              (host_read_data),
    .host_ready_o                  (host_ready),
    .host_access_permitted_o       (host_access_permitted),
    .ownership_conflict_o          (ownership_conflict),
    .communication_host_enable_i   (communication_host_enable),
    .host_communication_select_n_i (host_communication_select_n),
    .host_communication_write_i    (host_communication_write),
    .host_communication_commit_i   (host_communication_commit),
    .host_communication_address_i  (host_communication_address),
    .host_communication_write_data_i(host_communication_write_data),
    .host_communication_read_data_o(host_communication_read_data),
    .host_communication_ready_o    (host_communication_ready),
    .host_communication_access_permitted_o(
      host_communication_access_permitted
    ),
    .host_communication_blocked_o  (host_communication_blocked),
    .host_irq_clear_commit_i       (host_irq_clear_commit),
    .main_mailbox_write_commit_i   (main_mailbox_write_commit),
    .main_mailbox_write_data_i     (main_mailbox_write_data),
    .sound_cpu_mailbox_read_commit_i(sound_cpu_mailbox_read_commit),
    .sound_cpu_mailbox_read_data_o (sound_cpu_mailbox_read_data),
    .sound_cpu_mailbox_read_data_valid_o(
      sound_cpu_mailbox_read_data_valid
    ),
    .main_flag_o                   (main_flag),
    .main_flag_valid_o             (main_flag_valid),
    .main_flag_conflict_o          (main_flag_conflict),
    .sound_cpu_mailbox_write_commit_i(sound_cpu_mailbox_write_commit),
    .sound_cpu_mailbox_write_data_i(sound_cpu_mailbox_write_data),
    .main_mailbox_read_commit_i    (main_mailbox_read_commit),
    .main_mailbox_read_data_o      (main_mailbox_read_data),
    .main_mailbox_read_data_valid_o(main_mailbox_read_data_valid),
    .sound_flag_o                  (sound_flag),
    .sound_flag_valid_o            (sound_flag_valid),
    .sound_flag_conflict_o         (sound_flag_conflict),
    .sound_test_i                  (sound_test),
    .sound_test_valid_i            (sound_test_valid),
    .tirdy_n_i                     (tirdy_n),
    .tirdy_n_valid_i               (tirdy_n_valid),
    .sound_cpu_read_status_data_o  (sound_cpu_read_status_data),
    .sound_cpu_read_status_driven_mask_o(
      sound_cpu_read_status_driven_mask
    ),
    .sound_cpu_read_status_valid_mask_o(
      sound_cpu_read_status_valid_mask
    ),
    .j3_switch_i                   (j3_switch),
    .j3_switch_valid_i             (j3_switch_valid),
    .sound_cpu_switches_data_o     (sound_cpu_switches_data),
    .sound_cpu_switches_driven_mask_o(
      sound_cpu_switches_driven_mask
    ),
    .sound_cpu_switches_valid_mask_o(sound_cpu_switches_valid_mask),
    .sound_cpu_low_read_select_valid_i(sound_cpu_low_read_select_valid),
    .sound_cpu_low_read_quadrant_i (sound_cpu_low_read_quadrant),
    .sound_cpu_low_read_data_o     (sound_cpu_low_read_data),
    .sound_cpu_low_read_driven_mask_o(sound_cpu_low_read_driven_mask),
    .sound_cpu_low_read_valid_mask_o(sound_cpu_low_read_valid_mask),
    .sound_cpu_low_read_target_select_o(sound_cpu_low_read_target_select),
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (io_write_data),
    .io_commit_o                   (io_commit),
    .io_read_data_i                (io_read_data),
    .io_ready_i                    (external_io_ready),
    .port_1_blocked_o              (port_1_blocked),
    .port_1_address_invalid_o      (port_1_address_invalid),
    .sound_address_o               (sound_address),
    .sound_address_valid_o         (sound_address_valid),
    .sound_rom_block_o             (sound_rom_block),
    .sound_rom_block_valid_o       (sound_rom_block_valid),
    .sound_rom_present_i           (sound_rom_present),
    .sound_rom_request_o           (sound_rom_request),
    .sound_rom_request_block_o     (sound_rom_request_block),
    .sound_rom_request_address_o   (sound_rom_request_address),
    .sound_rom_byte_i              (sound_rom_byte),
    .sound_rom_byte_ready_i        (sound_rom_byte_ready),
    .sound_rom_selection_invalid_o (sound_rom_selection_invalid),
    .dac_code_o                    (dac_code),
    .dac_code_valid_o              (dac_code_valid),
    .dac_commit_o                  (dac_commit),
    .cport_latch_data_o            (cport_latch_data),
    .cport_latch_data_valid_o      (cport_latch_data_valid),
    .cport_latch_commit_o          (cport_latch_commit),
    .host_320_port_read_data_o     (host_320_port_read_data),
    .host_320_port_driven_mask_o   (host_320_port_driven_mask),
    .host_320_port_valid_mask_o    (host_320_port_valid_mask),
    .mute_net_o                    (mute_net),
    .mute_commit_o                 (mute_commit),
    .irq_68000_o                   (irq_68000),
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
    .debug_data_address_o          (),
    .debug_data_read_o             (),
    .debug_data_write_o            (),
    .debug_data_address_valid_o    (),
    .debug_data_write_address_o    (),
    .debug_data_read_data_o        (),
    .debug_data_write_data_o       (),
    .reset_active_o                (reset_active),
    .memory_wait_o                 (memory_wait),
    .phase_advance_o               (phase_advance),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .native_address_o              (native_address),
    .native_men_n_o                (men_n),
    .native_den_n_o                (den_n),
    .native_we_n_o                 (we_n),
    .native_sample_o               (),
    .native_bus_active_o           (native_bus_active),
    .tms_access_permitted_o        (tms_access_permitted),
    .execute_valid_o               (execute_valid),
    .execute_address_o             (execute_address),
    .execute_word_o                (execute_word),
    .pipeline_blocked_o            (pipeline_blocked),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (),
    .interrupt_pending_o           (),
    .instruction_valid_o           (),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  always_comb begin
    // The fixed-timing local host path is given a same-cycle combinational ROM
    // response. Native DSP reads retain the separate three-clock stall below.
    sound_rom_byte_ready =
      host_direct_io_read_target_select[0] || sound_rom_delayed_ready;
    // Prove that internal port-0/3/4/5 latch targets do not inherit downstream
    // callback backpressure. Other still-external targets remain ready.
    external_io_ready = !(
      io_write && (
        (io_port == 3'd0) ||
        (io_port == 3'd3) ||
        (io_port == 3'd4) ||
        (io_port == 3'd5)
      )
    );
    if (host_direct_io_read_target_select[2]) begin
      // Rev-A qualifies only comparator bit TD15; lower bits are deliberately
      // nonzero nowhere so the direct-path mask remains observable.
      io_read_data = 16'h8000;
    end else begin
      case (io_port)
        3'd0: io_read_data = 16'h6a80;
        3'd1: io_read_data = 16'hdead;
        3'd2: io_read_data = 16'h0000;
        default: io_read_data = 16'hffff;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (initialize) begin
      io_read_count  <= 0;
      io_write_count <= 0;
      sound_rom_commit_count <= 0;
      for (int unsigned port = 0; port < 8; port++) begin
        output_ports[port] <= 16'h0000;
      end
    end else if (io_commit) begin
      if (io_read) begin
        io_read_count <= io_read_count + 1;
        if (io_port == 3'd0) begin
          if (!sound_rom_request ||
              sound_rom_request_block != 4'h3 ||
              sound_rom_request_address != 16'h3457 ||
              sound_rom_selection_invalid) begin
            $fatal(1, "port-0 commit lacks the exact internal ROM callback");
          end
          sound_rom_commit_count <= sound_rom_commit_count + 1;
        end
      end
      if (io_write) begin
        if (((io_port == 3'd0) ||
             (io_port == 3'd3) ||
             (io_port == 3'd4) ||
             (io_port == 3'd5)) && external_io_ready) begin
          $fatal(1, "internal output commit relied on external readiness");
        end
        io_write_count <= io_write_count + 1;
        output_ports[io_port] <= io_write_data;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (initialize) begin
      host_local_ram_upper_write_count <= 0;
      host_local_ram_lower_write_count <= 0;
      host_program_io_write_count <= 0;
      host_direct_selected_write_commit_count <= 0;
      host_direct_unselected_write_commit_count <= 0;
      host_direct_read_complete_count <= 0;
    end else begin
      if (host_local_ram_upper_write_commit) begin
        host_local_ram_upper_write_count <=
          host_local_ram_upper_write_count + 1;
      end
      if (host_local_ram_lower_write_commit) begin
        host_local_ram_lower_write_count <=
          host_local_ram_lower_write_count + 1;
      end
      if (host_timing_program_io_write_commit) begin
        host_program_io_write_count <= host_program_io_write_count + 1;
      end
      if (|host_direct_io_write_commit_select) begin
        host_direct_selected_write_commit_count <=
          host_direct_selected_write_commit_count + 1;
      end
      if (host_direct_io_write_commit_unselected) begin
        host_direct_unselected_write_commit_count <=
          host_direct_unselected_write_commit_count + 1;
      end
      if (|host_direct_io_read_complete_select) begin
        host_direct_read_complete_count <=
          host_direct_read_complete_count + 1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (initialize) begin
      dac_commit_count <= 0;
      cport_latch_commit_count <= 0;
      mute_commit_count <= 0;
    end else if (dac_commit) begin
      dac_commit_count <= dac_commit_count + 1;
    end else if (cport_latch_commit) begin
      cport_latch_commit_count <= cport_latch_commit_count + 1;
    end else if (mute_commit) begin
      mute_commit_count <= mute_commit_count + 1;
    end
  end

  // Exercise a stalled same-clock sample-ROM callback. The request block and
  // pre-increment address must remain owned until the response is accepted.
  always_ff @(posedge clk) begin
    if (initialize) begin
      sound_rom_delayed_ready <= 1'b0;
      sound_rom_wait_cycles  <= 0;
      sound_rom_request_seen <= 1'b0;
    end else if (sound_rom_request && !sound_rom_byte_ready) begin
      if (sound_rom_request_block != 4'h3 ||
          sound_rom_request_address != 16'h3457 ||
          sound_rom_selection_invalid) begin
        $fatal(1, "stalled sound-ROM callback changed ownership");
      end
      sound_rom_request_seen <= 1'b1;
      sound_rom_wait_cycles  <= sound_rom_wait_cycles + 1;
      if (sound_rom_wait_cycles == 2) begin
        sound_rom_delayed_ready <= 1'b1;
      end
    end else if ((io_commit && io_read && (io_port == 3'd0)) ||
                 host_direct_io_read_complete_select[0]) begin
      sound_rom_delayed_ready <= 1'b0;
    end
  end

  task automatic tick;
    @(posedge clk);
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  function automatic logic [15:0] smoke_word(input logic [3:0] address);
    case (address)
      4'h0: smoke_word = 16'h4810;
      4'h1: smoke_word = 16'h4f15;
      4'h2: smoke_word = 16'h4b11;
      4'h3: smoke_word = 16'h4c12;
      4'h4: smoke_word = 16'h4d13;
      4'h5: smoke_word = 16'h4e14;
      4'h6: smoke_word = 16'h4120;
      4'h7: smoke_word = 16'h4021;
      4'h8: smoke_word = 16'h4222;
      4'h9: smoke_word = 16'hf600;
      4'ha: smoke_word = 16'h000c;
      4'hb: smoke_word = 16'h7eee;
      4'hc: smoke_word = 16'h2020;
      4'hd: smoke_word = 16'h7f80;
      default: smoke_word = 16'h7f83;
    endcase
  endfunction

  task automatic host_write_word(
    input logic [11:0] address,
    input logic [15:0] data
  );
    host_write      = 1'b1;
    host_address    = address;
    host_write_data = data;
    host_commit     = 1'b1;
    #1;
    require(host_ready && host_access_permitted,
            "host write is accepted only in reset-qualified ownership");
    tick();
    host_commit = 1'b0;
  endtask

  task automatic host_communication_write_word(
    input logic [8:0] address,
    input logic [15:0] data
  );
    host_communication_write      = 1'b1;
    host_communication_address    = address;
    host_communication_write_data = data;
    host_communication_commit     = 1'b1;
    #1;
    require(
      host_communication_ready &&
      host_communication_access_permitted &&
      !host_communication_blocked,
      "CRAMEN high accepts a whole-word communication-RAM write"
    );
    tick();
    host_communication_commit = 1'b0;
  endtask

  task automatic host_latch_write(
    input logic [2:0] select,
    input logic       value
  );
    host_latch_address = {value, select};
    host_latch_write_commit = 1'b1;
    tick();
    host_latch_write_commit = 1'b0;
  endtask

  task automatic local_host_start_address(
    input logic [23:1] cycle_address,
    input logic        read_not_write_value,
    input logic        upper_strobe_n,
    input logic        lower_strobe_n,
    input logic [15:0] write_data
  );
    host_bus_address = cycle_address;
    host_function_code = 3'b101;
    host_read_not_write = read_not_write_value;
    host_upper_data_strobe_n = upper_strobe_n;
    host_lower_data_strobe_n = lower_strobe_n;
    host_bus_write_data = write_data;
    host_address_strobe_assert = 1'b1;
    tick();
    host_address_strobe_assert = 1'b0;
    require(host_timing_cycle_active && host_timing_vpa_n &&
            host_timing_latched_address == cycle_address &&
            host_timing_latched_read_not_write == read_not_write_value &&
            host_timing_select_quadrant == cycle_address[13:12] &&
            host_timing_latched_upper_data_strobe_n == upper_strobe_n &&
            host_timing_latched_lower_data_strobe_n == lower_strobe_n,
            "opt-in host timing captures the qualified complete address");
  endtask

  task automatic local_host_start(
    input logic [1:0]  quadrant,
    input logic        read_not_write_value,
    input logic [3:0]  low_address,
    input logic        upper_strobe_n,
    input logic        lower_strobe_n,
    input logic [15:0] write_data
  );
    logic [23:1] cycle_address;
    cycle_address = '0;
    cycle_address[23] = 1'b1;
    cycle_address[16:14] = 3'b100;
    cycle_address[13:12] = quadrant;
    cycle_address[4:1] = low_address;
    local_host_start_address(
      cycle_address,
      read_not_write_value,
      upper_strobe_n,
      lower_strobe_n,
      write_data
    );
    require(!host_timing_rvf_n,
            "low-I/O helper selects the qualified RVF page");
  endtask

  task automatic local_host_rising_edge;
    host_8mhz_rise = 1'b1;
    tick();
    host_8mhz_rise = 1'b0;
  endtask

  task automatic local_host_falling_edge;
    host_8mhz_fall = 1'b1;
    tick();
    host_8mhz_fall = 1'b0;
  endtask

  task automatic local_host_advance_to_s6;
    local_host_falling_edge();
    require(host_timing_rva && !host_timing_dtack_n &&
            !host_timing_rvas_n,
            "S5 captures DTACK while preserving the selected target");
    local_host_rising_edge();
    require(!host_timing_rva && host_timing_dtack_n &&
            !host_timing_rvas_n,
            "S6 releases DTACK while holding the selected read/write path");
  endtask

  task automatic local_host_complete_s7(
    input logic expected_read_complete,
    input logic expected_write_complete
  );
    host_8mhz_fall = 1'b1;
    host_address_strobe_deassert = 1'b1;
    tick();
    host_8mhz_fall = 1'b0;
    host_address_strobe_deassert = 1'b0;
    require(!host_timing_cycle_active && host_timing_rvas_n &&
            host_timing_cycle_complete &&
            host_timing_read_complete == expected_read_complete &&
            host_timing_write_complete == expected_write_complete,
            "S7 updates stateful consumers and emits the exact trace pulse");
  endtask

  task automatic local_host_finish(
    input logic expected_read_complete,
    input logic expected_write_complete
  );
    local_host_advance_to_s6();
    local_host_complete_s7(
      expected_read_complete,
      expected_write_complete
    );
  endtask

  task automatic debug_write_word(
    input logic [7:0] address,
    input logic [15:0] data
  );
    debug_data_address = address;
    debug_data = data;
    debug_data_write = 1'b1;
    tick();
    debug_data_write = 1'b0;
  endtask

  task automatic release_and_check_reset;
    int unsigned falling_boundaries;
    logic previous_clkout;
    logic previous_reset_active;

    host_program_select_n = 1'b1;
    tick();
    require(!host_access_permitted && !tms_access_permitted,
            "safe handoff disables host before reset release");
    dsp_reset_n = 1'b1;
    falling_boundaries = 0;
    for (int unsigned elapsed = 0; elapsed < 32; elapsed++) begin
      previous_clkout       = clkout;
      previous_reset_active = reset_active;
      tick();
      if (previous_reset_active && previous_clkout && !clkout) begin
        falling_boundaries++;
      end
      if (!reset_active) begin
        break;
      end
    end
    require(falling_boundaries == 5,
            "physical reset release retains the five-cycle modeled hold");
    require((phase == 2'd0) && !clkout && native_address == 12'h000,
            "reset release preserves native phase and address-zero state");
    require(tms_access_permitted && !ownership_conflict,
            "DSP owns RAM after safe reset release");
  endtask

  task automatic release_host_control_and_check_reset;
    int unsigned falling_boundaries;
    logic previous_clkout;
    logic previous_reset_active;

    host_program_select_n = 1'b1;
    tick();
    require(!host_access_permitted && !tms_access_permitted,
            "latched handoff disables host before /320RES release");
    host_latch_write(3'd4, 1'b1);
    require(selected_dsp_reset_n && selected_dsp_reset_valid,
            "Q4 releases the qualified selected /320RES path");
    falling_boundaries = 0;
    for (int unsigned elapsed = 0; elapsed < 32; elapsed++) begin
      previous_clkout       = clkout;
      previous_reset_active = reset_active;
      tick();
      if (previous_reset_active && previous_clkout && !clkout) begin
        falling_boundaries++;
      end
      if (!reset_active) begin
        break;
      end
    end
    require(falling_boundaries == 5,
            "latched reset release retains the five-cycle modeled hold");
    require((phase == 2'd0) && !clkout && native_address == 12'h000,
            "latched reset release reaches address-zero fetch state");
    require(tms_access_permitted && !ownership_conflict,
            "DSP owns program RAM after the latched handoff");
  endtask

  task automatic run_until_retired(input int unsigned target);
    int unsigned count;
    count = 0;
    for (int unsigned elapsed = 0; elapsed < 1200; elapsed++) begin
      tick();
      require(!ownership_conflict, "execution never overlaps host ownership");
      require(!illegal, "synthetic integration program remains legal");
      if (retired) begin
        count++;
      end
      if (count == target) begin
        return;
      end
    end
    $display(
      "TIMEOUT count=%0d pc=%03x exec=%03x/%04x phase=%0d wait=%0b io=%0b/%0b p=%0d commit=%0b sa=%04x valid=%0b p1=%0b/%0b",
      count, pc, execute_address, execute_word, phase, memory_wait,
      io_read, io_write, io_port, io_commit, sound_address,
      sound_address_valid, port_1_blocked, port_1_address_invalid
    );
    $fatal(1, "retirement target was not reached");
  endtask

  initial begin
    initialize = 1'b1;
    clock_enable = 1'b1;
    dsp_reset_n = 1'b0;
    external_bio_n = 1'b0;
    use_board_bio = 1'b0;
    board_reset_n = 1'b1;
    use_host_control = 1'b0;
    host_latch_write_commit = 1'b0;
    host_latch_address = 4'h0;
    use_host_timing = 1'b0;
    host_8mhz_rise = 1'b0;
    host_8mhz_fall = 1'b0;
    host_address_strobe_assert = 1'b0;
    host_address_strobe_deassert = 1'b0;
    host_function_code = 3'b101;
    host_bus_address = '0;
    host_read_not_write = 1'b1;
    host_upper_data_strobe_n = 1'b1;
    host_lower_data_strobe_n = 1'b1;
    host_bus_write_data = 16'h0000;
    host_local_rom_read_data = 16'h0000;
    host_local_rom_read_data_valid = 1'b0;
    use_internal_local_ram = 1'b0;
    local_processor_halt_n_input = 1'b1;
    host_local_ram_read_data = 16'h0000;
    host_local_ram_read_valid_mask = 16'h0000;
    bio_one_mhz_rise = 1'b0;
    bio_counter_seed = 8'hff;
    bio_counter_seed_valid = 1'b1;
    host_program_select_n = 1'b1;
    host_write = 1'b0;
    host_commit = 1'b0;
    host_address = 12'h000;
    host_write_data = 16'h0000;
    communication_host_enable = 1'b0;
    host_communication_select_n = 1'b1;
    host_communication_write = 1'b0;
    host_communication_commit = 1'b0;
    host_communication_address = 9'h000;
    host_communication_write_data = 16'h0000;
    host_irq_clear_commit = 1'b0;
    main_mailbox_write_commit = 1'b0;
    main_mailbox_write_data = 16'h0000;
    sound_cpu_mailbox_read_commit = 1'b0;
    sound_cpu_mailbox_write_commit = 1'b0;
    sound_cpu_mailbox_write_data = 16'h0000;
    main_mailbox_read_commit = 1'b0;
    sound_test = 1'b1;
    sound_test_valid = 1'b1;
    tirdy_n = 1'b0;
    tirdy_n_valid = 1'b1;
    j3_switch = 4'b1010;
    j3_switch_valid = 4'b1111;
    sound_cpu_low_read_select_valid = 1'b0;
    sound_cpu_low_read_quadrant = 2'b00;
    sound_rom_present = 12'h008;
    sound_rom_byte = 8'hd5;
    debug_data_write = 1'b0;
    debug_data_address = 8'h00;
    debug_data = 16'h0000;
    tick();
    require(!local_processor_reset_n && !local_processor_halt_n &&
            local_processor_release_blocked,
            "FPGA initialization clamps local-processor reset release");
    initialize = 1'b0;
    tick();

    require(local_processor_reset_n && local_processor_halt_n &&
            !local_processor_release_blocked,
            "external local storage does not wait for internal metadata");
    board_reset_n = 1'b0;
    #1;
    require(!local_processor_reset_n && local_processor_halt_n &&
            !local_processor_release_blocked,
            "raw board RESET assertion does not invent a HALT assertion");
    board_reset_n = 1'b1;
    local_processor_halt_n_input = 1'b0;
    #1;
    require(local_processor_reset_n && !local_processor_halt_n &&
            !local_processor_release_blocked,
            "raw HALT assertion does not invent a board RESET assertion");
    local_processor_halt_n_input = 1'b1;
    use_internal_local_ram = 1'b1;
    #1;
    require(!local_processor_reset_n && !local_processor_halt_n &&
            local_processor_release_blocked,
            "selected internal SRAM blocks release throughout its scrub");
    use_internal_local_ram = 1'b0;
    #1;
    require(local_processor_reset_n && local_processor_halt_n &&
            !local_processor_release_blocked,
            "returning to external storage restores board reset request");

    require(reset_active && !native_bus_active && men_n && den_n && we_n,
            "held physical reset keeps every TMS native strobe inactive");
    require(selected_bio_valid && !selected_bio_n &&
            !board_bio_valid && board_bio_n,
            "external BIO remains selected while board BIO power-up is invalid");
    require(
      !cport_latch_data_valid &&
      host_320_port_driven_mask == 16'hff00 &&
      host_320_port_valid_mask == 16'h0000,
      "host D15:D8 are the only /320PORT lanes and power-up data is invalid"
    );
    require(
      !sound_cpu_mailbox_read_data_valid &&
      !main_mailbox_read_data_valid &&
      !main_flag_valid && !sound_flag_valid &&
      sound_cpu_read_status_data == 16'h2000 &&
      sound_cpu_read_status_driven_mask == 16'hf000 &&
      sound_cpu_read_status_valid_mask == 16'h3000,
      "mailbox power-up remains invalid while raw test/ready lanes are valid"
    );
    require(
      sound_cpu_switches_data == 16'ha000 &&
      sound_cpu_switches_driven_mask == 16'hf000 &&
      sound_cpu_switches_valid_mask == 16'hf000 &&
      sound_cpu_low_read_data == 16'h0000 &&
      sound_cpu_low_read_driven_mask == 16'h0000 &&
      sound_cpu_low_read_valid_mask == 16'h0000 &&
      sound_cpu_low_read_target_select == 4'b0000,
      "raw switches are live while an unqualified mux claims no read target"
    );

    // Opposite-side reads qualify the independent LS74 flags without
    // fabricating LS374 word data or changing the separate board-BIO reset
    // history used later in this integration test.
    sound_cpu_mailbox_read_commit = 1'b1;
    main_mailbox_read_commit = 1'b1;
    tick();
    require(
      !main_flag && main_flag_valid &&
      !sound_flag && sound_flag_valid &&
      !sound_cpu_mailbox_read_data_valid &&
      !main_mailbox_read_data_valid &&
      sound_cpu_read_status_data == 16'h2000 &&
      sound_cpu_read_status_valid_mask == 16'hf000,
      "read-clear completions qualify both flags without qualifying latch data"
    );
    sound_cpu_mailbox_read_commit = 1'b0;
    main_mailbox_read_commit = 1'b0;
    tick();

    // This is only combinational LS138 target composition. It proves the
    // primary Atari order, including the two read names swapped by MAME, but
    // neither generates /RVAS nor clears MAINFLAG.
    sound_cpu_low_read_select_valid = 1'b1;
    sound_cpu_low_read_quadrant = 2'b00;
    #1;
    require(
      sound_cpu_low_read_data == 16'h0000 &&
      sound_cpu_low_read_driven_mask == 16'hffff &&
      sound_cpu_low_read_valid_mask == 16'h0000 &&
      sound_cpu_low_read_target_select == 4'b0001,
      "quadrant 00 selects invalid-startup /SOUNDRD without inventing data"
    );
    sound_cpu_low_read_quadrant = 2'b01;
    #1;
    require(
      sound_cpu_low_read_data == 16'h0000 &&
      sound_cpu_low_read_driven_mask == 16'hff00 &&
      sound_cpu_low_read_valid_mask == 16'h0000 &&
      sound_cpu_low_read_target_select == 4'b0010,
      "quadrant 01 follows Atari /320PORT rather than MAME's switch name"
    );
    sound_cpu_low_read_quadrant = 2'b10;
    #1;
    require(
      sound_cpu_low_read_data == 16'ha000 &&
      sound_cpu_low_read_driven_mask == 16'hf000 &&
      sound_cpu_low_read_valid_mask == 16'hf000 &&
      sound_cpu_low_read_target_select == 4'b0100,
      "quadrant 10 follows Atari /SWITCHES rather than MAME's port name"
    );
    sound_cpu_low_read_quadrant = 2'b11;
    #1;
    require(
      sound_cpu_low_read_data == 16'h2000 &&
      sound_cpu_low_read_driven_mask == 16'hf000 &&
      sound_cpu_low_read_valid_mask == 16'hf000 &&
      sound_cpu_low_read_target_select == 4'b1000,
      "quadrant 11 selects the qualified raw status nibble"
    );

    j3_switch = 4'b1100;
    j3_switch_valid = 4'b0101;
    sound_cpu_low_read_quadrant = 2'b10;
    #1;
    require(
      sound_cpu_low_read_data == 16'h4000 &&
      sound_cpu_low_read_driven_mask == 16'hf000 &&
      sound_cpu_low_read_valid_mask == 16'h5000,
      "switch validity remains per lane through board-top composition"
    );
    j3_switch = 4'b1010;
    j3_switch_valid = 4'b1111;
    sound_cpu_low_read_quadrant = 2'b00;

    main_mailbox_write_data = 16'h5aa5;
    main_mailbox_write_commit = 1'b1;
    tick();
    require(
      sound_cpu_mailbox_read_data_valid &&
      sound_cpu_mailbox_read_data == 16'h5aa5 &&
      main_flag && main_flag_valid && !main_flag_conflict &&
      sound_cpu_read_status_data == 16'ha000 &&
      sound_cpu_read_status_valid_mask == 16'hf000 &&
      sound_cpu_low_read_data == 16'h5aa5 &&
      sound_cpu_low_read_driven_mask == 16'hffff &&
      sound_cpu_low_read_valid_mask == 16'hffff &&
      sound_cpu_low_read_target_select == 4'b0001,
      "selection exposes /SOUNDRD data but cannot clear the live MAINFLAG"
    );
    main_mailbox_write_commit = 1'b0;
    sound_cpu_mailbox_read_commit = 1'b1;
    tick();
    require(
      !main_flag && main_flag_valid &&
      sound_cpu_mailbox_read_data == 16'h5aa5 &&
      sound_cpu_mailbox_read_data_valid &&
      sound_cpu_read_status_data == 16'h2000,
      "sound-CPU read completion clears MAINFLAG but preserves latch data"
    );
    sound_cpu_mailbox_read_commit = 1'b0;
    tick();

    sound_cpu_mailbox_write_data = 16'ha55a;
    sound_cpu_mailbox_write_commit = 1'b1;
    tick();
    require(
      main_mailbox_read_data_valid &&
      main_mailbox_read_data == 16'ha55a &&
      sound_flag && sound_flag_valid && !sound_flag_conflict &&
      sound_cpu_read_status_data == 16'h6000,
      "sound-CPU whole-word completion sets SOUNDFLAG and status bit 14"
    );
    sound_cpu_mailbox_write_commit = 1'b0;
    main_mailbox_read_commit = 1'b1;
    tick();
    require(
      !sound_flag && sound_flag_valid &&
      main_mailbox_read_data == 16'ha55a &&
      main_mailbox_read_data_valid &&
      sound_cpu_read_status_data == 16'h2000,
      "main read completion clears SOUNDFLAG but preserves latch data"
    );
    main_mailbox_read_commit = 1'b0;
    tick();

    // Opt into the qualified same-clock local-68000 bridge. The external
    // low-read selector and local sound-side completion callbacks become
    // sentinels; main-system mailbox callbacks remain a separate bus.
    use_host_timing = 1'b1;
    sound_cpu_low_read_select_valid = 1'b1;
    sound_cpu_low_read_quadrant = 2'b11;

    main_mailbox_write_data = 16'h6db6;
    main_mailbox_write_commit = 1'b1;
    tick();
    main_mailbox_write_commit = 1'b0;
    require(main_flag && sound_cpu_mailbox_read_data == 16'h6db6,
            "main-system callback supplies a live word for timed /SOUNDRD");

    local_host_start(2'b00, 1'b1, 4'h0, 1'b0, 1'b0, 16'h0000);
    require(sound_cpu_low_read_target_select == 4'b0000,
            "external read-selector sentinel is ignored before timed S4");
    local_host_rising_edge();
    require(
      host_timing_read_select_valid && !host_timing_write_select_valid &&
      host_timing_target_select == 8'h10 &&
      sound_cpu_low_read_target_select == 4'b0001 &&
      sound_cpu_low_read_data == 16'h6db6 &&
      sound_cpu_low_read_driven_mask == 16'hffff &&
      sound_cpu_low_read_valid_mask == 16'hffff && main_flag,
      "timed S4 selects complete /SOUNDRD data without an early side effect"
    );
    local_host_finish(1'b1, 1'b0);
    require(!main_flag && main_flag_valid &&
            sound_cpu_mailbox_read_data == 16'h6db6,
            "timed S7 /SOUNDRD clears MAINFLAG while retaining the word");
    tick();

    local_host_start(2'b01, 1'b1, 4'h0, 1'b0, 1'b0, 16'h0000);
    local_host_rising_edge();
    require(
      host_timing_target_select == 8'h20 &&
      sound_cpu_low_read_target_select == 4'b0010 &&
      sound_cpu_low_read_data == 16'h0000 &&
      sound_cpu_low_read_driven_mask == 16'hff00 &&
      sound_cpu_low_read_valid_mask == 16'h0000,
      "timed quadrant 01 forwards only the currently invalid /320PORT lanes"
    );
    local_host_finish(1'b1, 1'b0);
    tick();

    local_host_start(2'b10, 1'b1, 4'h0, 1'b0, 1'b0, 16'h0000);
    local_host_rising_edge();
    require(
      host_timing_target_select == 8'h40 &&
      sound_cpu_low_read_target_select == 4'b0100 &&
      sound_cpu_low_read_data == 16'ha000 &&
      sound_cpu_low_read_driven_mask == 16'hf000 &&
      sound_cpu_low_read_valid_mask == 16'hf000,
      "timed quadrant 10 forwards the live raw switch nibble and mask"
    );
    local_host_finish(1'b1, 1'b0);
    tick();

    local_host_start(2'b11, 1'b1, 4'h0, 1'b0, 1'b0, 16'h0000);
    local_host_rising_edge();
    require(
      host_timing_target_select == 8'h80 &&
      sound_cpu_low_read_target_select == 4'b1000 &&
      sound_cpu_low_read_data == 16'h2000 &&
      sound_cpu_low_read_driven_mask == 16'hf000 &&
      sound_cpu_low_read_valid_mask == 16'hf000,
      "timed quadrant 11 forwards the live raw status nibble and mask"
    );
    local_host_finish(1'b1, 1'b0);
    tick();

    // Both byte strobes preserve the raw bus word; an asserted external
    // callback carrying a different word must be ignored while the timing
    // bridge is selected.
    sound_cpu_mailbox_write_data = 16'hdead;
    sound_cpu_mailbox_write_commit = 1'b1;
    local_host_start(2'b00, 1'b0, 4'h0, 1'b0, 1'b0, 16'hb44b);
    local_host_rising_edge();
    require(
      host_timing_write_select_valid && !host_timing_read_select_valid &&
      host_timing_target_select == 8'h01 &&
      !host_timing_read_write_strobe_n &&
      !host_timing_upper_write_enable_n &&
      !host_timing_lower_write_enable_n &&
      sound_cpu_low_read_target_select == 4'b0000,
      "timed S4 exposes the complete-word /SOUNDWR write path"
    );
    local_host_finish(1'b0, 1'b1);
    require(main_mailbox_read_data == 16'hb44b &&
            main_mailbox_read_data_valid && sound_flag && sound_flag_valid &&
            !host_timing_partial_sound_write,
            "timed S7 captures raw local-host data instead of external sentinel"
    );
    sound_cpu_mailbox_write_commit = 1'b0;
    tick();

    main_mailbox_read_commit = 1'b1;
    tick();
    main_mailbox_read_commit = 1'b0;
    require(!sound_flag && sound_flag_valid,
            "main-side callback clears SOUNDFLAG before byte-write tests");
    local_host_start(2'b00, 1'b0, 4'h0, 1'b0, 1'b1, 16'hab34);
    local_host_rising_edge();
    require(!host_timing_upper_write_enable_n &&
            host_timing_lower_write_enable_n,
            "timed write retains the asymmetric physical byte strobes");
    local_host_finish(1'b0, 1'b1);
    require(host_timing_partial_sound_write &&
            main_mailbox_read_data == 16'habab && sound_flag &&
            sound_flag_valid,
            "upper-byte /SOUNDWR duplicates D15:D8 into both mailbox latches"
    );
    tick();
    require(!host_timing_partial_sound_write,
            "partial-write disclosure is exactly one trace clock");

    main_mailbox_read_commit = 1'b1;
    tick();
    main_mailbox_read_commit = 1'b0;
    local_host_start(2'b00, 1'b0, 4'h0, 1'b1, 1'b0, 16'hab34);
    local_host_rising_edge();
    require(host_timing_upper_write_enable_n &&
            !host_timing_lower_write_enable_n,
            "timed lower-byte write retains the physical byte strobes");
    local_host_finish(1'b0, 1'b1);
    require(host_timing_partial_sound_write &&
            main_mailbox_read_data == 16'h3434 && sound_flag &&
            sound_flag_valid,
            "lower-byte /SOUNDWR duplicates D7:D0 into both mailbox latches"
    );
    tick();
    main_mailbox_read_commit = 1'b1;
    tick();
    main_mailbox_read_commit = 1'b0;
    require(!sound_flag && sound_flag_valid,
            "main-side read clears the byte-write pending flag");

    // `/LATCHES` is address/data-independent of UDS/LDS on A044427. The
    // external callback points at Q6 while the timed bus targets Q5=1.
    host_latch_address = 4'b0110;
    host_latch_write_commit = 1'b1;
    local_host_start(2'b01, 1'b0, 4'b1101, 1'b1, 1'b0, 16'hffff);
    local_host_rising_edge();
    require(host_timing_target_select == 8'h02,
            "timed write quadrant 01 selects only /LATCHES");
    local_host_finish(1'b0, 1'b1);
    require(host_latch_q[5] && host_latch_valid[5] &&
            !host_latch_valid[6],
            "timed /LATCHES uses A4:A1 and ignores the external callback");
    host_latch_write_commit = 1'b0;
    tick();

    // The unimplemented speech endpoint remains observable and cannot be
    // mistaken for any implemented write callback.
    local_host_start(2'b10, 1'b0, 4'h0, 1'b0, 1'b0, 16'hcafe);
    local_host_rising_edge();
    require(host_timing_target_select == 8'h04,
            "timed write quadrant 10 remains the distinct /SPEECH target");
    local_host_finish(1'b0, 1'b1);
    require(host_timing_speech_write_complete &&
            !host_timing_partial_sound_write &&
            main_mailbox_read_data == 16'h3434 && !sound_flag,
            "unimplemented /SPEECH completion is visible without side effects"
    );
    tick();

    // Outside Y4, the same captured host cycle feeds the storage-free local
    // memory callback boundary. Authorized ROM contents and local SRAM state
    // remain external, including lane validity.
    host_local_rom_read_data = 16'ha55a;
    host_local_rom_read_data_valid = 1'b1;
    local_host_start_address(
      23'h091a2b, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    require(
      host_local_rom_read_request &&
      host_local_rom_word_address == 15'h1a2b &&
      !host_local_ram_read_request &&
      host_local_memory_read_target_select == 2'b01 &&
      host_local_memory_read_data == 16'ha55a &&
      host_local_memory_read_driven_mask == 16'hffff &&
      host_local_memory_read_valid_mask == 16'hffff &&
      !host_local_memory_read_missing,
      "timed mirrored ROM read retains the external valid-data carrier"
    );
    local_host_rising_edge();
    local_host_finish(1'b0, 1'b0);
    tick();

    host_local_ram_read_data = 16'hcafe;
    host_local_ram_read_valid_mask = 16'hffff;
    local_host_start_address(
      23'h7fe123, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    require(
      host_local_ram_read_request &&
      host_local_ram_word_address == 13'h0123 &&
      !host_local_rom_read_request &&
      host_local_memory_read_target_select == 2'b10 &&
      host_local_memory_read_data == 16'hcafe &&
      host_local_memory_read_driven_mask == 16'hffff &&
      host_local_memory_read_valid_mask == 16'hffff,
      "timed Y7 read forwards integration-owned SRAM data and validity"
    );
    local_host_rising_edge();
    local_host_finish(1'b0, 1'b0);
    tick();

    local_host_start_address(
      23'h7fe123, 1'b0, 1'b0, 1'b1, 16'h12aa
    );
    local_host_rising_edge();
    require(host_local_ram_write_data == 16'h12aa,
            "timed Y7 write forwards the captured raw host word");
    local_host_finish(1'b0, 1'b0);
    require(host_local_ram_upper_write_count == 1 &&
            host_local_ram_lower_write_count == 0,
            "timed Y7 upper-byte write commits only the physical upper slice");
    tick();

    // The optional FPGA SRAM cannot silently turn uninitialized data into a
    // board value. Its two-bit validity metadata is scrubbed sequentially;
    // the external callback remains authoritative until the explicit opt-in.
    require(host_local_ram_storage_scrub_active &&
            !host_local_ram_storage_ready,
            "internal local SRAM remains unavailable during validity scrub");
    while (!host_local_ram_storage_ready) begin
      tick();
    end
    require(!host_local_ram_storage_scrub_active &&
            host_local_ram_storage_scrub_address == 13'h1fff,
            "internal local SRAM becomes ready only after all 8192 words");

    use_internal_local_ram = 1'b1;
    #1;
    require(local_processor_reset_n && local_processor_halt_n &&
            !local_processor_release_blocked,
            "selected internal SRAM releases reset only after final scrub word");
    host_local_ram_read_data = 16'hffff;
    host_local_ram_read_valid_mask = 16'hffff;
    local_host_start_address(
      23'h7fe321, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    require(
      !host_local_ram_read_request &&
      host_local_ram_word_address == 13'h0321 &&
      host_local_memory_read_target_select == 2'b10 &&
      host_local_memory_read_data == 16'h0000 &&
      host_local_memory_read_driven_mask == 16'hffff &&
      host_local_memory_read_valid_mask == 16'h0000,
      "internal unwritten SRAM masks retained data and external sentinel"
    );
    local_host_rising_edge();
    local_host_finish(1'b0, 1'b0);
    tick();

    local_host_start_address(
      23'h7fe321, 1'b0, 1'b0, 1'b1, 16'h5ade
    );
    local_host_rising_edge();
    local_host_finish(1'b0, 1'b0);
    require(
      !host_local_ram_upper_write_commit &&
      !host_local_ram_lower_write_commit &&
      !host_local_ram_storage_write_blocked &&
      host_local_ram_upper_write_count == 1 &&
      host_local_ram_lower_write_count == 0,
      "internal upper-byte write is isolated from the external callback"
    );
    tick();

    local_host_start_address(
      23'h7fe321, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    require(
      !host_local_ram_read_request &&
      host_local_memory_read_data == 16'h5a00 &&
      host_local_memory_read_valid_mask == 16'hff00,
      "internal SRAM read reports only its written upper lane"
    );
    local_host_rising_edge();
    local_host_finish(1'b0, 1'b0);
    tick();

    local_host_start_address(
      23'h7fe321, 1'b0, 1'b1, 1'b0, 16'hc3a7
    );
    local_host_rising_edge();
    local_host_finish(1'b0, 1'b0);
    require(!host_local_ram_upper_write_commit &&
            !host_local_ram_lower_write_commit &&
            !host_local_ram_storage_write_blocked,
            "internal lower-byte write is accepted without external callback");
    tick();

    local_host_start_address(
      23'h7fe321, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    require(
      host_local_memory_read_data == 16'h5aa7 &&
      host_local_memory_read_driven_mask == 16'hffff &&
      host_local_memory_read_valid_mask == 16'hffff,
      "independent internal byte writes compose one fully valid SRAM word"
    );
    local_host_rising_edge();
    local_host_finish(1'b0, 1'b0);
    tick();
    use_internal_local_ram = 1'b0;

    // Timing mode owns the program-RAM callbacks. Opposite explicit callback
    // values are sentinels and must neither select nor alter another address.
    host_program_select_n = 1'b0;
    host_write = 1'b1;
    host_commit = 1'b1;
    host_address = 12'h777;
    host_write_data = 16'hdead;
    local_host_start_address(
      23'h7fa123, 1'b0, 1'b0, 1'b0, 16'h3456
    );
    local_host_rising_edge();
    require(host_access_permitted && host_ready &&
            host_timing_program_io_word_address == 12'h123 &&
            !host_timing_program_io_write &&
            !host_timing_program_io_read,
            "timed lower-Y5 whole-word write owns program RAM");
    local_host_finish(1'b0, 1'b0);
    tick();

    local_host_start_address(
      23'h7fa123, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    local_host_rising_edge();
    require(host_access_permitted && !host_ready,
            "timed lower-Y5 read waits for the synchronous RAM response");
    local_host_advance_to_s6();
    require(host_ready && host_read_data == 16'h3456,
            "timed lower-Y5 read returns the word written at S7");
    local_host_complete_s7(1'b0, 1'b0);
    tick();

    local_host_start_address(
      23'h7fa123, 1'b0, 1'b0, 1'b1, 16'hdead
    );
    local_host_rising_edge();
    require(host_access_permitted && host_ready,
            "physical lower-Y5 write level remains visible for a byte cycle");
    local_host_finish(1'b0, 1'b0);
    require(host_timing_partial_program_write &&
            !host_timing_partial_communication_write,
            "partial lower-Y5 write is reported and rejected at S7");
    tick();

    local_host_start_address(
      23'h7fa123, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    local_host_rising_edge();
    local_host_advance_to_s6();
    require(host_ready && host_read_data == 16'h3456,
            "rejected partial lower-Y5 write preserves program RAM");
    local_host_complete_s7(1'b0, 1'b0);
    tick();

    // Upper-Y5 host writes reach LS138 100K only at canonical RA11:RA3=0
    // addresses. Use the same physical targets as native TMS I/O to load the
    // shared sound address and block latch, then exercise the DAC and CPORT.
    local_host_start_address(
      23'h7fb007, 1'b0, 1'b0, 1'b0, 16'h3457
    );
    local_host_rising_edge();
    require(host_direct_io_write_target_select == 8'h80 &&
            host_direct_io_write_data == 16'h3457 &&
            !host_direct_io_write_unselected &&
            !direct_io_ownership_conflict,
            "canonical direct port-7 write selects shared address load");
    local_host_finish(1'b0, 1'b0);
    require(sound_address == 16'h3457 && sound_address_valid,
            "direct port-7 S6 commit loads the physical sound address");
    tick();

    local_host_start_address(
      23'h7fb006, 1'b0, 1'b0, 1'b0, 16'h0003
    );
    local_host_rising_edge();
    require(host_direct_io_write_target_select == 8'h40,
            "canonical direct port-6 write selects the ROM block latch");
    local_host_finish(1'b0, 1'b0);
    require(sound_rom_block == 4'h3 && sound_rom_block_valid,
            "direct port-6 S6 commit loads the physical ROM block");
    tick();

    local_host_start_address(
      23'h7fb000, 1'b0, 1'b0, 1'b0, 16'hbcde
    );
    local_host_rising_edge();
    require(host_direct_io_write_target_select == 8'h01,
            "canonical direct port-0 write selects DACL");
    local_host_finish(1'b0, 1'b0);
    require(dac_code == 12'hbcd && dac_code_valid,
            "direct port-0 S6 commit reaches the raw DAC latch");
    tick();

    local_host_start_address(
      23'h7fb003, 1'b0, 1'b0, 1'b0, 16'h12a5
    );
    local_host_rising_edge();
    require(host_direct_io_write_target_select == 8'h08,
            "canonical direct port-3 write selects CPORT");
    local_host_finish(1'b0, 1'b0);
    require(cport_latch_data == 8'ha5 && cport_latch_data_valid,
            "direct port-3 S6 commit reaches the physical LS374");
    tick();

    // LS139 95K ignores RA11:RA2 on reads. Canonical port 0 returns the full
    // signed-byte carrier and completes the shared-address increment at S7.
    local_host_start_address(
      23'h7fb000, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    local_host_rising_edge();
    require(host_direct_io_read_target_select == 4'h1 &&
            !host_direct_io_read_alias && sound_rom_request &&
            sound_rom_request_block == 4'h3 &&
            sound_rom_request_address == 16'h3457,
            "canonical direct port-0 read owns the sample-ROM callback");
    local_host_advance_to_s6();
    require(host_direct_io_read_data == 16'hea80 &&
            host_direct_io_read_driven_mask == 16'hffff &&
            host_direct_io_read_valid_mask == 16'hffff,
            "direct port-0 read carries the complete qualified ROM word");
    local_host_complete_s7(1'b0, 1'b0);
    require(sound_address == 16'h3458,
            "direct input-read S7 completion increments shared address");
    tick();

    // The unloaded comparator source remains only a one-bit physical carrier.
    local_host_start_address(
      23'h7fb002, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    local_host_rising_edge();
    require(host_direct_io_read_target_select == 4'h4 &&
            host_direct_io_read_data == 16'h8000 &&
            host_direct_io_read_driven_mask == 16'h8000 &&
            host_direct_io_read_valid_mask == 16'h8000,
            "direct port-2 read exposes only externally qualified TD15");
    local_host_finish(1'b0, 1'b0);
    tick();

    // A noncanonical write has /PWE timing but no LS138 output target.
    local_host_start_address(
      23'h7fb123, 1'b0, 1'b0, 1'b0, 16'hbcde
    );
    local_host_rising_edge();
    require(host_timing_program_io_write &&
            !host_timing_program_io_read && !host_access_permitted &&
            host_direct_io_write_target_select == 8'h00 &&
            host_direct_io_write_unselected &&
            host_direct_io_write_data == 16'hbcde,
            "noncanonical upper-Y5 write has /PWE but no output target");
    local_host_advance_to_s6();
    require(host_program_io_write_count == 5 &&
            host_direct_selected_write_commit_count == 4 &&
            host_direct_unselected_write_commit_count == 1,
            "S6 distinguishes four selected writes from one raw /PWE edge");
    local_host_complete_s7(1'b0, 1'b0);
    tick();

    // The same noncanonical address aliases read port 3 because the read
    // decoder sees only RA1:RA0. Y3 has no drawn Rev-A data-source enable.
    local_host_start_address(
      23'h7fb123, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    local_host_rising_edge();
    require(host_timing_program_io_read &&
            !host_timing_program_io_write && !host_access_permitted &&
            host_direct_io_read_target_select == 4'h8 &&
            host_direct_io_read_alias &&
            host_direct_io_read_data == 16'h0000 &&
            host_direct_io_read_driven_mask == 16'h0000 &&
            host_direct_io_read_valid_mask == 16'h0000,
            "noncanonical read aliases undriven LS139 port 3 without filler");
    local_host_finish(1'b0, 1'b0);
    require(host_direct_read_complete_count == 3,
            "every direct input-read completion emits one S7 callback");
    tick();

    local_host_start_address(
      23'h7fa123, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    local_host_rising_edge();
    local_host_advance_to_s6();
    require(host_ready && host_read_data == 16'h3456,
            "direct upper-Y5 activity cannot modify lower-Y5 program RAM");
    local_host_complete_s7(1'b0, 1'b0);
    host_program_select_n = 1'b1;
    host_write = 1'b0;
    host_commit = 1'b0;
    tick();

    // CRAMEN ownership is still authoritative, but timed Y6 callbacks now
    // provide the physical select, direction, address, data, and S7 commit.
    communication_host_enable = 1'b1;
    host_communication_select_n = 1'b0;
    host_communication_write = 1'b1;
    host_communication_commit = 1'b1;
    host_communication_address = 9'h077;
    host_communication_write_data = 16'hdead;
    local_host_start_address(
      23'h7fc123, 1'b0, 1'b0, 1'b0, 16'h789a
    );
    local_host_rising_edge();
    require(host_communication_access_permitted &&
            host_communication_ready && !host_communication_blocked,
            "timed Y6 whole-word write is accepted under CRAMEN ownership");
    local_host_finish(1'b0, 1'b0);
    tick();

    local_host_start_address(
      23'h7fc123, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    local_host_rising_edge();
    require(host_communication_access_permitted &&
            !host_communication_ready && !host_communication_blocked,
            "timed Y6 read waits for its synchronous RAM response");
    local_host_advance_to_s6();
    require(host_communication_ready &&
            host_communication_read_data == 16'h789a,
            "timed Y6 read returns the S7-committed communication word");
    local_host_complete_s7(1'b0, 1'b0);
    tick();

    local_host_start_address(
      23'h7fc123, 1'b0, 1'b1, 1'b0, 16'hbeef
    );
    local_host_rising_edge();
    require(host_communication_access_permitted &&
            host_communication_ready && !host_communication_blocked,
            "physical Y6 write level remains visible for a byte cycle");
    local_host_finish(1'b0, 1'b0);
    require(host_timing_partial_communication_write &&
            !host_timing_partial_program_write,
            "lower-byte Y6 write is reported and accepted at S7");
    tick();

    local_host_start_address(
      23'h7fc123, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    local_host_rising_edge();
    local_host_advance_to_s6();
    require(host_communication_ready &&
            host_communication_read_data == 16'hefef,
            "lower-byte Y6 write duplicates D7:D0 into both HM6116 banks");
    local_host_complete_s7(1'b0, 1'b0);
    tick();

    local_host_start_address(
      23'h7fc123, 1'b0, 1'b0, 1'b1, 16'hbca7
    );
    local_host_rising_edge();
    local_host_finish(1'b0, 1'b0);
    require(host_timing_partial_communication_write &&
            !host_timing_partial_program_write,
            "upper-byte Y6 write is reported and accepted at S7");
    tick();

    local_host_start_address(
      23'h7fc123, 1'b1, 1'b0, 1'b0, 16'h0000
    );
    local_host_rising_edge();
    local_host_advance_to_s6();
    require(host_communication_ready &&
            host_communication_read_data == 16'hbcbc,
            "upper-byte Y6 write duplicates D15:D8 into both HM6116 banks");
    local_host_complete_s7(1'b0, 1'b0);
    communication_host_enable = 1'b0;
    host_communication_select_n = 1'b1;
    host_communication_write = 1'b0;
    host_communication_commit = 1'b0;
    tick();

    use_host_timing = 1'b0;

    sound_cpu_low_read_quadrant = 2'b11;
    sound_test_valid = 1'b0;
    tirdy_n_valid = 1'b0;
    #1;
    require(
      sound_cpu_read_status_data == 16'h0000 &&
      sound_cpu_read_status_driven_mask == 16'hf000 &&
      sound_cpu_read_status_valid_mask == 16'hc000 &&
      sound_cpu_low_read_data == 16'h0000 &&
      sound_cpu_low_read_driven_mask == 16'hf000 &&
      sound_cpu_low_read_valid_mask == 16'hc000,
      "raw peripheral validity never changes the physical driven-lane mask"
    );
    sound_test_valid = 1'b1;
    tirdy_n_valid = 1'b1;
    #1;

    // The integration must preserve each standalone conflict result rather
    // than assigning a board-top priority to unrelated bus completions.
    main_mailbox_write_data = 16'hc33c;
    main_mailbox_write_commit = 1'b1;
    sound_cpu_mailbox_read_commit = 1'b1;
    #1;
    require(main_flag_conflict,
            "coincident main write/sound read is reported before capture");
    tick();
    require(
      sound_cpu_mailbox_read_data == 16'hc33c &&
      sound_cpu_mailbox_read_data_valid &&
      !main_flag && !main_flag_valid && main_flag_conflict &&
      sound_cpu_read_status_data == 16'h2000 &&
      sound_cpu_read_status_valid_mask == 16'h7000,
      "main conflict captures data but invalidates only MAINFLAG/status bit 15"
    );
    main_mailbox_write_commit = 1'b0;
    sound_cpu_mailbox_read_commit = 1'b0;
    tick();
    sound_cpu_mailbox_read_commit = 1'b1;
    tick();
    sound_cpu_mailbox_read_commit = 1'b0;
    require(!main_flag && main_flag_valid,
            "later sound read requalifies a cleared MAINFLAG");

    sound_cpu_mailbox_write_data = 16'h3cc3;
    sound_cpu_mailbox_write_commit = 1'b1;
    main_mailbox_read_commit = 1'b1;
    #1;
    require(sound_flag_conflict,
            "coincident sound write/main read is reported before capture");
    tick();
    require(
      main_mailbox_read_data == 16'h3cc3 &&
      main_mailbox_read_data_valid &&
      !sound_flag && !sound_flag_valid && sound_flag_conflict &&
      sound_cpu_read_status_data == 16'h2000 &&
      sound_cpu_read_status_valid_mask == 16'hb000,
      "sound conflict captures data but invalidates only SOUNDFLAG/status bit 14"
    );
    sound_cpu_mailbox_write_commit = 1'b0;
    main_mailbox_read_commit = 1'b0;
    tick();
    main_mailbox_read_commit = 1'b1;
    tick();
    main_mailbox_read_commit = 1'b0;
    require(
      !sound_flag && sound_flag_valid &&
      sound_cpu_read_status_data == 16'h2000 &&
      sound_cpu_read_status_valid_mask == 16'hf000,
      "later main read requalifies SOUNDFLAG and complete high-nibble validity"
    );

    // The host loads the project-authored ROM-free board smoke program while
    // /320RES is asserted. Address 14 is an explicit conservative park word.
    host_program_select_n = 1'b0;
    for (int unsigned address = 0; address < 15; address++) begin
      host_write_word(address[11:0], smoke_word(address[3:0]));
    end

    debug_write_word(8'h10, 16'hf230);
    debug_write_word(8'h11, 16'h00a5);
    debug_write_word(8'h12, 16'h0001);
    debug_write_word(8'h13, 16'h0000);
    debug_write_word(8'h14, 16'h0003);
    debug_write_word(8'h15, 16'h3456);

    // Host preload at SA8:SA0=0x056 supplies the later processor port-1 read.
    // CRAMEN is returned to DSP ownership before processor reset is released.
    communication_host_enable = 1'b1;
    host_communication_select_n = 1'b0;
    host_communication_write_word(9'h056, 16'h55aa);
    host_communication_select_n = 1'b1;
    host_communication_write = 1'b0;
    communication_host_enable = 1'b0;
    tick();
    require(
      !host_communication_access_permitted &&
      !host_communication_blocked,
      "communication ownership handoff completes before DSP execution"
    );

    release_and_check_reset();
    run_until_retired(12);

    require(io_write_count == 6 && io_read_count == 3,
            "board smoke completes six physical writes and three reads");
    require(output_ports[0] == 16'hf230,
            "port zero receives the raw primary-backed DAC word");
    require(dac_code_valid && dac_code == 12'hf23 &&
            dac_commit_count == 2,
            "internal DAC latch commits one uncomplemented raw code");
    require(!mute_net && mute_commit_count == 1,
            "port-4 TD0=1 commits the primary raw complementary MUTE net");
    require(irq_68000,
            "data-independent port-5 request leaves 320IRQ asserted");
    require(
      cport_latch_data_valid && cport_latch_data == 8'ha5 &&
      cport_latch_commit_count == 2 &&
      host_320_port_read_data == 16'ha500 &&
      host_320_port_driven_mask == 16'hff00 &&
      host_320_port_valid_mask == 16'hff00,
      "port three exposes TD7:TD0 on host D15:D8 with explicit lane masks"
    );
    sound_cpu_low_read_quadrant = 2'b01;
    #1;
    require(
      sound_cpu_low_read_data == 16'ha500 &&
      sound_cpu_low_read_driven_mask == 16'hff00 &&
      sound_cpu_low_read_valid_mask == 16'hff00 &&
      sound_cpu_low_read_target_select == 4'b0010,
      "integrated quadrant 01 exposes the populated port-3 latch byte"
    );
    require(output_ports[3] == 16'h00a5 &&
            output_ports[4] == 16'h0001 &&
            output_ports[5] == 16'h0000 &&
            output_ports[6] == 16'h0003 &&
            output_ports[7] == 16'h3456,
            "all synthetic board control outputs match the fixed fixture");
    require(accumulator == 32'h0000_55aa && cycle_count == 32'd22,
            "host-loaded smoke reaches the fixed accumulator and cycle total");
    require(pc == 12'h00e,
            "BIOZ skips the sentinel and retires the expected final NOP");
    require(
      sound_address_valid && sound_address == 16'h3459 &&
      sound_rom_block_valid && sound_rom_block == 4'h3,
      "ports 7/6 load control state and all three input reads increment globally"
    );
    require(!port_1_blocked && !port_1_address_invalid,
            "processor port-1 communication read completed from internal RAM");
    require(sound_rom_commit_count == 1 &&
            sound_rom_request_seen && sound_rom_wait_cycles == 3 &&
            !sound_rom_selection_invalid,
            "processor port 0 held and committed one internal ROM response");

    use_host_timing = 1'b1;
    local_host_start(2'b11, 1'b0, 4'h0, 1'b0, 1'b0, 16'h0000);
    local_host_rising_edge();
    require(host_timing_target_select == 8'h08 && irq_68000,
            "timed write quadrant 11 selects /IRQCLR without clearing early");
    local_host_finish(1'b0, 1'b1);
    require(!irq_68000 && !mute_net,
            "timed S7 /IRQCLR clears only 320IRQ and preserves raw MUTE state");
    tick();
    use_host_timing = 1'b0;

    // Processor reset does not erase communication RAM. Give CRAMEN to the
    // host and read the word back through the integrated host callback.
    dsp_reset_n = 1'b0;
    tick();
    require(mute_net && !irq_68000,
            "/320RES clears both LS74 Q states and drives MUTE complement high");
    communication_host_enable = 1'b1;
    host_communication_select_n = 1'b0;
    host_communication_write = 1'b0;
    host_communication_address = 9'h056;
    #1;
    require(!host_communication_ready,
            "integrated communication host read is synchronous");
    tick();
    require(
      host_communication_ready &&
      host_communication_read_data == 16'h55aa,
      "communication RAM survives processor reset and DSP execution"
    );
    host_communication_select_n = 1'b1;
    communication_host_enable = 1'b0;
    tick();

    // Reset, reload a minimal program, and prove that a low-address TBLW is
    // acknowledged by the physical I/O callback without modifying RAM[3].
    require(reset_active && !tms_access_permitted,
            "reasserted /320RES immediately disables the physical TMS path");
    for (int unsigned elapsed = 0; elapsed < 4; elapsed++) begin
      if (!native_bus_active) begin
        break;
      end
      tick();
    end
    require(!native_bus_active,
            "processor recognizes reset at its documented falling boundary");
    host_program_select_n = 1'b0;
    host_write_word(12'h000, 16'h7e03);  // LACK 3
    host_write_word(12'h001, 16'h7d10);  // TBLW 0x10 -> address ACC=3
    host_write_word(12'h002, 16'h7f80);  // repeated NOP
    host_write_word(12'h003, 16'h7f83);  // conservative park word

    release_and_check_reset();
    run_until_retired(3);
    require(io_write_count == 7 && output_ports[3] == 16'hf230,
            "low-address TBLW commits exactly once through output port three");
    require(
      cport_latch_commit_count == 3 && cport_latch_data == 8'h30 &&
      host_320_port_read_data == 16'h3000 &&
      host_320_port_valid_mask == 16'hff00,
      "low-address TBLW clocks its low byte through the physical /CPORT path"
    );
    #1;
    require(
      sound_cpu_low_read_data == 16'h3000 &&
      sound_cpu_low_read_driven_mask == 16'hff00 &&
      sound_cpu_low_read_valid_mask == 16'hff00,
      "selected /320PORT follows the later TBLW capture without stale data"
    );
    require(cycle_count == 32'd5,
            "LACK/TBLW/NOP consumes the documented five cycles");
    require(execute_valid && execute_address == 12'h003 &&
            execute_word == 16'h7f83 && pipeline_blocked,
            "unchanged address-three park word proves TBLW did not write RAM");
    require(!memory_wait && !phase_advance && pipeline_blocked,
            "unsupported park is distinct from a callback wait");

    dsp_reset_n = 1'b0;
    tick();
    host_program_select_n = 1'b0;
    host_write = 1'b0;
    host_address = 12'h003;
    #1;
    require(!host_ready, "host read waits for the synchronous RAM response");
    tick();
    require(host_ready && host_read_data == 16'h7f83,
            "host reads the unchanged low-address park word after reset");

    // Reload a second focused alias program. TBLW at program address zero is
    // physically the same /DACL target as OUT PA0 and must not wait on the
    // deliberately unready external callback or modify program RAM word zero.
    host_write_word(12'h000, 16'h7e00);  // LACK 0
    host_write_word(12'h001, 16'h7d11);  // TBLW 0x11 -> address ACC=0
    host_write_word(12'h002, 16'h7f80);  // repeated NOP
    host_write_word(12'h003, 16'h7f83);  // conservative park word

    release_and_check_reset();
    run_until_retired(3);
    require(io_write_count == 8 && output_ports[0] == 16'h00a5,
            "address-zero TBLW commits once through the DAC output target");
    require(dac_commit_count == 3 && dac_code == 12'h00a,
            "TBLW captures the raw upper twelve bits without callback wait");
    require(cycle_count == 32'd5,
            "LACK/TBLW/NOP retains five cycles at the internal DAC target");

    dsp_reset_n = 1'b0;
    tick();
    host_program_select_n = 1'b0;
    host_write = 1'b0;
    host_address = 12'h000;
    #1;
    require(!host_ready, "final host read remains synchronous");
    tick();
    require(host_ready && host_read_data == 16'h7e00,
            "address-zero TBLW leaves its program word unchanged");

    // Keep the DSP reset, load a BIOZ fixture, and qualify the opt-in board
    // generator independently of the still-high external BIO sentinel.
    host_write_word(12'h000, 16'hf600);  // BIOZ target operand follows
    host_write_word(12'h001, 16'h0003);  // generated-low target
    host_write_word(12'h002, 16'h7e11);  // untaken sentinel LACK 0x11
    host_write_word(12'h003, 16'h7e22);  // taken target LACK 0x22
    host_write_word(12'h004, 16'h7f80);  // following NOP

    external_bio_n = 1'b1;
    while (phase == 2'd1) begin
      tick();
    end
    bio_one_mhz_rise = 1'b1;
    tick();
    bio_one_mhz_rise = 1'b0;
    require(bio_divider_state == 8'hce && bio_divider_phase_valid &&
            !raw_320bio_n && raw_320bio_valid &&
            board_bio_n && !board_bio_valid,
            "integrated terminal edge reloads CE before CLKOUT resampling");
    for (int unsigned elapsed = 0; elapsed < 8; elapsed++) begin
      if (board_bio_valid && !board_bio_n) begin
        break;
      end
      tick();
    end
    use_board_bio = 1'b1;
    #1;
    require(!board_bio_n && board_bio_valid &&
            !selected_bio_n && selected_bio_valid,
            "opt-in board BIO selects a qualified low over external high");

    release_and_check_reset();
    run_until_retired(2);
    require(accumulator == 32'h0000_0022 && cycle_count == 32'd3,
            "generated low BIO takes BIOZ and executes only target LACK 0x22");

    dsp_reset_n = 1'b0;
    tick();
    while (phase == 2'd1) begin
      tick();
    end
    bio_one_mhz_rise = 1'b1;
    tick();
    bio_one_mhz_rise = 1'b0;
    require(raw_320bio_n && !board_bio_n,
            "source release waits for the independent CLKOUT enable");
    for (int unsigned elapsed = 0; elapsed < 8; elapsed++) begin
      if (board_bio_n && board_bio_valid) begin
        break;
      end
      tick();
    end
    require(board_bio_n && board_bio_valid &&
            selected_bio_n && selected_bio_valid,
            "following CLKOUT enable propagates generated BIO release");

    // Finally opt into the qualified host latch. External reset and CRAMEN
    // inputs become deliberate opposite-valued sentinels, so every ownership
    // transition below must come from LS259 Q4/Q3 rather than the legacy
    // callbacks.
    use_board_bio = 1'b0;
    use_host_control = 1'b1;
    dsp_reset_n = 1'b1;
    communication_host_enable = 1'b1;
    board_reset_n = 1'b0;
    tick();
    board_reset_n = 1'b1;
    tick();
    require(
      (host_latch_q == 8'h00) && (host_latch_valid == 8'hff) &&
      !selected_dsp_reset_n && selected_dsp_reset_valid &&
      !selected_communication_host_enable &&
      selected_communication_host_enable_valid,
      "board reset qualifies Q4/Q3 low and ignores opposite external controls"
    );
    require(
      cport_latch_data_valid && cport_latch_data == 8'h30 &&
      host_320_port_valid_mask == 16'hff00,
      "board reset does not clear the separately unreset LS374 50L"
    );
    require(
      sound_cpu_mailbox_read_data_valid &&
      sound_cpu_mailbox_read_data == 16'hc33c &&
      main_mailbox_read_data_valid &&
      main_mailbox_read_data == 16'h3cc3 &&
      !main_flag && main_flag_valid &&
      !sound_flag && sound_flag_valid &&
      sound_cpu_read_status_data == 16'h2000 &&
      sound_cpu_read_status_valid_mask == 16'hf000,
      "board reset clears mailbox flags without erasing either retained word"
    );
    require(reset_active && !tms_access_permitted,
            "selected Q4 low holds the processor and TMS buffers reset");

    host_program_select_n = 1'b0;
    host_write_word(12'h000, 16'h7e5a);  // LACK 0x5a
    host_write_word(12'h001, 16'h7f80);  // NOP
    host_write_word(12'h002, 16'h7f83);  // conservative park word

    // Q3 high selects host communication-RAM ownership even while the legacy
    // callback is low. Returning Q3 low hands the word to the DSP side.
    communication_host_enable = 1'b0;
    host_latch_write(3'd3, 1'b1);
    require(
      selected_communication_host_enable &&
      selected_communication_host_enable_valid,
      "Q3 selects qualified host communication ownership"
    );
    host_communication_select_n = 1'b0;
    host_communication_write_word(9'h12a, 16'h1357);
    host_communication_select_n = 1'b1;
    host_communication_write = 1'b0;
    host_latch_write(3'd3, 1'b0);
    require(
      !selected_communication_host_enable &&
      !host_communication_access_permitted &&
      !host_communication_blocked,
      "Q3 low completes the communication handoff to the DSP"
    );

    release_host_control_and_check_reset();
    dsp_reset_n = 1'b0;
    #1;
    require(selected_dsp_reset_n && tms_access_permitted,
            "selected Q4 high ignores the low external reset sentinel");
    run_until_retired(2);
    require(accumulator == 32'h0000_005a && cycle_count == 32'd2,
            "latched host handoff executes the synthetic two-cycle program");

    dsp_reset_n = 1'b1;
    host_latch_write(3'd4, 1'b0);
    require(!selected_dsp_reset_n && selected_dsp_reset_valid &&
            !tms_access_permitted,
            "Q4 low immediately disables TMS ownership after completion");
    tick();
    require(reset_active,
            "processor recognizes the selected latched reset synchronously");

    communication_host_enable = 1'b0;
    host_latch_write(3'd3, 1'b1);
    host_communication_select_n = 1'b0;
    host_communication_write = 1'b0;
    host_communication_address = 9'h12a;
    #1;
    require(!host_communication_ready,
            "latched CRAMEN host read retains synchronous response timing");
    tick();
    require(
      host_communication_ready &&
      host_communication_read_data == 16'h1357,
      "latched reset/CRAMEN handoff preserves the synthetic communication word"
    );
    host_communication_select_n = 1'b1;

    $display("PASS tb_hard_drivin_sound_mister");
    $finish;
  end
endmodule

`default_nettype wire
