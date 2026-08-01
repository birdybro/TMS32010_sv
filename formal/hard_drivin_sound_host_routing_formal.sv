`default_nettype none

// FORMAL-001 bounded composition check for the timing-enabled A044427 board
// wrapper. One symbolic legal S2-through-S7 transaction selects among the
// implemented read/write routing cases. The processor itself remains paused;
// this harness proves host-side composition, not DSP execution.
module hard_drivin_sound_host_routing_formal (
  input logic        clk_i,
  input logic [2:0]  transaction_kind_i,
  input logic [15:0] transaction_data_i,
  input logic [3:0]  latch_address_i,
  input logic        partial_upper_i
);
  localparam logic [2:0] TX_SOUND_READ    = 3'd0;
  localparam logic [2:0] TX_SOUND_WRITE   = 3'd1;
  localparam logic [2:0] TX_PARTIAL_WRITE = 3'd2;
  localparam logic [2:0] TX_LATCH_WRITE   = 3'd3;
  localparam logic [2:0] TX_SPEECH_WRITE  = 3'd4;
  localparam logic [2:0] TX_IRQ_CLEAR     = 3'd5;

  logic        initialized = 1'b0;
  logic [3:0]  step_q = 4'd0;
  logic [2:0]  transaction_kind_q = TX_SOUND_READ;
  logic [15:0] transaction_data_q = 16'h0000;
  logic [3:0]  latch_address_q = 4'h0;
  logic        partial_upper_q = 1'b0;
  logic        initialize;
  logic        board_reset_n;
  logic [1:0]  transaction_quadrant;
  logic [23:1] host_bus_address;
  logic        host_read_not_write;
  logic        host_upper_data_strobe_n;
  logic        host_lower_data_strobe_n;
  logic        host_8mhz_rise;
  logic        host_8mhz_fall;
  logic        host_as_assert;
  logic        host_as_deassert;

  logic [7:0]  host_latch_q;
  logic [7:0]  host_latch_valid;
  logic        host_timing_cycle_active;
  logic        host_timing_rva;
  logic        host_timing_rvas_n;
  logic        host_timing_read_select_valid;
  logic        host_timing_write_select_valid;
  logic [1:0]  host_timing_select_quadrant;
  logic [7:0]  host_timing_target_select;
  logic        host_timing_cycle_complete;
  logic        host_timing_read_complete;
  logic        host_timing_write_complete;
  logic        host_timing_speech_write_complete;
  logic        host_timing_partial_sound_write;
  logic [15:0] sound_cpu_mailbox_read_data;
  logic        sound_cpu_mailbox_read_data_valid;
  logic        main_flag;
  logic        main_flag_valid;
  logic [15:0] main_mailbox_read_data;
  logic        main_mailbox_read_data_valid;
  logic        sound_flag;
  logic        sound_flag_valid;
  logic [15:0] sound_cpu_low_read_data;
  logic [15:0] sound_cpu_low_read_driven_mask;
  logic [15:0] sound_cpu_low_read_valid_mask;
  logic [3:0]  sound_cpu_low_read_target_select;
  logic        irq_68000;

  assign initialize = !initialized;
  assign board_reset_n = initialized && (step_q != 4'd0);
  assign transaction_quadrant =
    (transaction_kind_q == TX_LATCH_WRITE)  ? 2'b01 :
    (transaction_kind_q == TX_SPEECH_WRITE) ? 2'b10 :
    (transaction_kind_q == TX_IRQ_CLEAR)    ? 2'b11 : 2'b00;
  assign host_bus_address = {
    1'b1,
    6'b000000,
    3'b100,
    transaction_quadrant,
    7'b0000000,
    (transaction_kind_q == TX_LATCH_WRITE) ? latch_address_q : 4'h0
  };
  assign host_read_not_write =
    transaction_kind_q == TX_SOUND_READ;
  assign host_upper_data_strobe_n =
    (transaction_kind_q == TX_PARTIAL_WRITE) && !partial_upper_q;
  assign host_lower_data_strobe_n =
    (transaction_kind_q == TX_PARTIAL_WRITE) && partial_upper_q;
  assign host_as_assert = step_q == 4'd2;
  assign host_8mhz_fall =
    (step_q == 4'd3) || (step_q == 4'd5) || (step_q == 4'd7);
  assign host_8mhz_rise =
    (step_q == 4'd4) || (step_q == 4'd6);
  assign host_as_deassert = step_q == 4'd7;

  always_ff @(posedge clk_i) begin
    initialized <= 1'b1;
    if (initialize) begin
      assume (transaction_kind_i <= TX_IRQ_CLEAR);
      step_q <= 4'd0;
      transaction_kind_q <= transaction_kind_i;
      transaction_data_q <= transaction_data_i;
      latch_address_q <= latch_address_i;
      partial_upper_q <= partial_upper_i;
    end else if (step_q != 4'd9) begin
      step_q <= step_q + 1'b1;
    end
  end

  hard_drivin_sound_mister dut (
    .clk_i                                  (clk_i),
    .initialize_i                           (initialize),
    .clock_enable_i                         (1'b0),
    .dsp_reset_n_i                          (1'b1),
    .bio_i                                  (1'b1),
    .use_board_bio_i                        (1'b0),
    .board_reset_n_i                        (board_reset_n),
    .local_processor_halt_n_i               (1'b1),
    .bio_one_mhz_rise_i                     (1'b0),
    .bio_counter_seed_i                     (8'h00),
    .bio_counter_seed_valid_i               (1'b0),

    .use_host_control_i                     (1'b0),
    // Opposite-path sentinels remain asserted. Timing mode must isolate them.
    .host_latch_write_commit_i              (1'b1),
    .host_latch_address_i                   (~latch_address_q),

    .use_host_timing_i                      (1'b1),
    .host_8mhz_rise_i                       (host_8mhz_rise),
    .host_8mhz_fall_i                       (host_8mhz_fall),
    .host_address_strobe_assert_i            (host_as_assert),
    .host_address_strobe_deassert_i          (host_as_deassert),
    .host_function_code_i                   (3'b001),
    .host_bus_address_i                     (host_bus_address),
    .host_read_not_write_i                  (host_read_not_write),
    .host_upper_data_strobe_n_i             (host_upper_data_strobe_n),
    .host_lower_data_strobe_n_i             (host_lower_data_strobe_n),
    .host_bus_write_data_i                  (transaction_data_q),
    .host_local_rom_read_data_i             (16'h0000),
    .host_local_rom_read_data_valid_i       (1'b0),
    .use_internal_local_ram_i               (1'b0),
    .host_local_ram_read_data_i             (16'h0000),
    .host_local_ram_read_valid_mask_i       (16'h0000),

    .host_program_select_n_i                (1'b1),
    .host_write_i                           (1'b0),
    .host_commit_i                          (1'b0),
    .host_address_i                         (12'h000),
    .host_write_data_i                      (16'h0000),

    .communication_host_enable_i            (1'b0),
    .host_communication_select_n_i          (1'b1),
    .host_communication_write_i             (1'b0),
    .host_communication_commit_i            (1'b0),
    .host_communication_address_i           (9'h000),
    .host_communication_write_data_i        (16'h0000),
    .host_irq_clear_commit_i                (1'b1),

    .main_mailbox_write_commit_i            (
      (step_q == 4'd1) &&
      (transaction_kind_q == TX_SOUND_READ)
    ),
    .main_mailbox_write_data_i              (transaction_data_q),
    .sound_cpu_mailbox_read_commit_i        (1'b1),
    .sound_cpu_mailbox_write_commit_i       (1'b1),
    .sound_cpu_mailbox_write_data_i         (~transaction_data_q),
    .main_mailbox_read_commit_i             (1'b0),
    .sound_test_i                           (1'b1),
    .sound_test_valid_i                     (1'b1),
    .tirdy_n_i                              (1'b1),
    .tirdy_n_valid_i                        (1'b1),
    .j3_switch_i                            (4'ha),
    .j3_switch_valid_i                      (4'hf),
    .sound_cpu_low_read_select_valid_i      (1'b1),
    .sound_cpu_low_read_quadrant_i          (2'b11),

    .io_read_data_i                         (16'h0000),
    .io_ready_i                             (1'b1),
    .sound_rom_present_i                    (12'h000),
    .sound_rom_byte_i                       (8'h00),
    .sound_rom_byte_ready_i                 (1'b0),

    .debug_data_write_i                     (1'b0),
    .debug_data_address_i                   (8'h00),
    .debug_data_i                           (16'h0000),

    .host_latch_q_o                         (host_latch_q),
    .host_latch_valid_o                     (host_latch_valid),
    .host_timing_cycle_active_o             (host_timing_cycle_active),
    .host_timing_rva_o                      (host_timing_rva),
    .host_timing_rvas_n_o                   (host_timing_rvas_n),
    .host_timing_read_select_valid_o        (
      host_timing_read_select_valid
    ),
    .host_timing_write_select_valid_o       (
      host_timing_write_select_valid
    ),
    .host_timing_latched_read_not_write_o   (),
    .host_timing_select_quadrant_o          (
      host_timing_select_quadrant
    ),
    .host_timing_target_select_o            (host_timing_target_select),
    .host_timing_cycle_complete_o           (host_timing_cycle_complete),
    .host_timing_read_complete_o            (host_timing_read_complete),
    .host_timing_write_complete_o           (host_timing_write_complete),
    .host_timing_speech_write_complete_o    (
      host_timing_speech_write_complete
    ),
    .host_timing_partial_sound_write_o      (
      host_timing_partial_sound_write
    ),
    .sound_cpu_mailbox_read_data_o          (
      sound_cpu_mailbox_read_data
    ),
    .sound_cpu_mailbox_read_data_valid_o    (
      sound_cpu_mailbox_read_data_valid
    ),
    .main_flag_o                            (main_flag),
    .main_flag_valid_o                      (main_flag_valid),
    .main_mailbox_read_data_o               (main_mailbox_read_data),
    .main_mailbox_read_data_valid_o         (
      main_mailbox_read_data_valid
    ),
    .sound_flag_o                           (sound_flag),
    .sound_flag_valid_o                     (sound_flag_valid),
    .sound_cpu_low_read_data_o              (sound_cpu_low_read_data),
    .sound_cpu_low_read_driven_mask_o       (
      sound_cpu_low_read_driven_mask
    ),
    .sound_cpu_low_read_valid_mask_o        (
      sound_cpu_low_read_valid_mask
    ),
    .sound_cpu_low_read_target_select_o     (
      sound_cpu_low_read_target_select
    ),
    .irq_68000_o                            (irq_68000)
  );

  always_ff @(posedge clk_i) begin
    if (initialized) begin
      if (step_q >= 4'd1) begin
        assert (host_latch_valid == 8'hff);
      end

      if ((step_q >= 4'd3) && (step_q <= 4'd7)) begin
        assert (host_timing_cycle_active);
        assert (host_timing_select_quadrant == transaction_quadrant);
      end

      if ((step_q >= 4'd5) && (step_q <= 4'd7)) begin
        assert (host_timing_target_select ==
                (8'h01 << {host_read_not_write, transaction_quadrant}));
        if (transaction_kind_q == TX_SOUND_READ) begin
          assert (host_timing_read_select_valid);
          assert (!host_timing_write_select_valid);
          assert (sound_cpu_low_read_target_select == 4'b0001);
          assert (sound_cpu_low_read_data == transaction_data_q);
          assert (sound_cpu_low_read_driven_mask == 16'hffff);
          assert (sound_cpu_low_read_valid_mask == 16'hffff);
        end else begin
          assert (!host_timing_read_select_valid);
          assert (host_timing_write_select_valid);
        end
      end

      if ((step_q >= 4'd1) && (step_q < 4'd8)) begin
        assert (!host_timing_cycle_complete);
        assert (!host_timing_read_complete);
        assert (!host_timing_write_complete);
        assert (!host_timing_speech_write_complete);
        assert (!host_timing_partial_sound_write);
        assert (host_latch_q == 8'h00);
        assert (!main_mailbox_read_data_valid);
        assert (!sound_flag);
        assert (sound_flag_valid);
        if (transaction_kind_q != TX_SOUND_READ) begin
          assert (!sound_cpu_mailbox_read_data_valid);
          assert (!main_flag);
          assert (main_flag_valid);
        end
      end

      if (step_q == 4'd7) begin
        assert (!host_timing_rva && !host_timing_rvas_n);
      end

      if (step_q == 4'd8) begin
        assert (!host_timing_cycle_active);
        assert (host_timing_cycle_complete);
        assert (host_timing_read_complete ==
                (transaction_kind_q == TX_SOUND_READ));
        assert (host_timing_write_complete ==
                (transaction_kind_q != TX_SOUND_READ));
        assert (host_timing_partial_sound_write ==
                (transaction_kind_q == TX_PARTIAL_WRITE));
        assert (host_timing_speech_write_complete ==
                (transaction_kind_q == TX_SPEECH_WRITE));

        case (transaction_kind_q)
          TX_SOUND_READ: begin
            assert (sound_cpu_mailbox_read_data == transaction_data_q);
            assert (sound_cpu_mailbox_read_data_valid);
            assert (!main_flag && main_flag_valid);
          end
          TX_SOUND_WRITE: begin
            assert (main_mailbox_read_data == transaction_data_q);
            assert (main_mailbox_read_data_valid);
            assert (sound_flag && sound_flag_valid);
          end
          TX_PARTIAL_WRITE: begin
            assert (!main_mailbox_read_data_valid);
            assert (!sound_flag && sound_flag_valid);
          end
          TX_LATCH_WRITE: begin
            assert (host_latch_q ==
                    ({8{latch_address_q[3]}} &
                     (8'h01 << latch_address_q[2:0])));
            assert (host_latch_valid == 8'hff);
          end
          TX_SPEECH_WRITE: begin
            assert (!main_mailbox_read_data_valid);
            assert (!sound_flag && sound_flag_valid);
            assert (host_latch_q == 8'h00);
          end
          TX_IRQ_CLEAR: begin
            assert (!irq_68000);
            assert (host_latch_q == 8'h00);
          end
          default: assert (1'b0);
        endcase
      end

      cover ((step_q == 4'd8) &&
             (transaction_kind_q == TX_SOUND_READ) &&
             host_timing_read_complete && !main_flag);
      cover ((step_q == 4'd8) &&
             (transaction_kind_q == TX_SOUND_WRITE) &&
             host_timing_write_complete && sound_flag);
      cover ((step_q == 4'd8) &&
             (transaction_kind_q == TX_PARTIAL_WRITE) &&
             partial_upper_q && host_timing_partial_sound_write &&
             !sound_flag);
      cover ((step_q == 4'd8) &&
             (transaction_kind_q == TX_PARTIAL_WRITE) &&
             !partial_upper_q && host_timing_partial_sound_write &&
             !sound_flag);
      cover ((step_q == 4'd8) &&
             (transaction_kind_q == TX_LATCH_WRITE) &&
             host_timing_write_complete);
      cover ((step_q == 4'd8) &&
             (transaction_kind_q == TX_SPEECH_WRITE) &&
             host_timing_speech_write_complete);
      cover ((step_q == 4'd8) &&
             (transaction_kind_q == TX_IRQ_CLEAR) &&
             host_timing_write_complete && !irq_68000);
    end
  end
endmodule

`default_nettype wire
