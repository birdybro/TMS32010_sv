`default_nettype none

// Same-clock FPGA integration of the generic MiSTer callback wrapper with the
// qualified A044427 Rev-A program/communication RAM ownership and native
// target decode. Remaining peripherals and the 68000 bus bridge are external.
module hard_drivin_sound_mister (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        clock_enable_i,
  input  logic        dsp_reset_n_i,
  input  logic        bio_i,

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
  logic [15:0] selected_io_read_data;
  logic        selected_io_ready;

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
        logical_program_ready = io_ready_i;
      end
    end
  end

  // Port 1 is served by the internal communication-RAM path. Every other
  // physical port remains on the external callback. The physical request and
  // commit signals stay visible for trace/debug ownership.
  always_comb begin
    selected_io_read_data = io_read_data_i;
    selected_io_ready     = io_ready_i;
    if (io_read_o && (io_port_o == 3'd1)) begin
      selected_io_read_data = communication_port_1_read_data;
      selected_io_ready     = communication_port_1_ready;
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
    .dsp_reset_n_i                 (dsp_reset_n_i),
    .host_program_select_n_i       (host_program_select_n_i),
    .host_write_i                  (host_write_i),
    .host_commit_i                 (host_commit_i),
    .host_address_i                (host_address_i),
    .host_write_data_i             (host_write_data_i),
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
    .communication_host_enable_i   (communication_host_enable_i),
    .host_select_n_i               (host_communication_select_n_i),
    .host_write_i                  (host_communication_write_i),
    .host_commit_i                 (host_communication_commit_i),
    .host_address_i                (host_communication_address_i),
    .host_write_data_i             (host_communication_write_data_i),
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

  tms32010_mister processor (
    .clk_i                         (clk_i),
    .reset_i                       (initialize_i),
    .processor_reset_i             (!dsp_reset_n_i),
    .clock_enable_i                (clock_enable_i),
    .bio_i                         (bio_i),
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
    end
  end
endmodule

`default_nettype wire
