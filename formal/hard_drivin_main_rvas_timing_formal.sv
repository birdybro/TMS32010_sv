`default_nettype none

module hard_drivin_main_rvas_timing_formal;
  (* gclk *) logic clk_i;
  (* anyseq *) logic initialize_i;
  (* anyseq *) logic main_8mhz_rise_i;
  (* anyseq *) logic main_8mhz_fall_i;
  (* anyseq *) logic main_8mhz_high_i;
  (* anyseq *) logic address_strobe_assert_i;
  (* anyseq *) logic dtack_n_i;

  logic rva;
  logic sampled_dtack_n;
  logic rvas0_n;
  logic rvas_n;
  logic rvas0_assert_event;
  logic rvas0_release_event;
  logic rvas_assert_event;
  logic rvas_release_event;
  logic past_valid_q;
  logic reference_as_seen_q;
  logic reference_main_8mhz_high_q;
  logic reference_rva_q;
  logic reference_sampled_dtack_n_q;
  logic reference_rvas0_active_q;
  logic reference_rvas_active_q;
  logic reference_rvas0_assert_event_q;
  logic reference_rvas0_release_event_q;
  logic reference_assert_event_q;
  logic reference_release_event_q;
  logic saw_rvas0_early_q;
  logic saw_low_phase_assert_q;
  logic saw_preset_priority_q;
  logic saw_assert_q;
  logic saw_low_sample_q;
  logic saw_rva_end_q;
  logic saw_release_q;
  logic saw_missed_sample_q;

  hard_drivin_main_rvas_timing dut (
    .clk_i                    (clk_i),
    .initialize_i             (initialize_i),
    .main_8mhz_rise_i         (main_8mhz_rise_i),
    .main_8mhz_fall_i         (main_8mhz_fall_i),
    .main_8mhz_high_i         (main_8mhz_high_i),
    .address_strobe_assert_i  (address_strobe_assert_i),
    .dtack_n_i                (dtack_n_i),
    .rva_o                    (rva),
    .sampled_dtack_n_o        (sampled_dtack_n),
    .rvas0_n_o                (rvas0_n),
    .rvas_n_o                 (rvas_n),
    .rvas0_assert_event_o     (rvas0_assert_event),
    .rvas0_release_event_o    (rvas0_release_event),
    .rvas_assert_event_o      (rvas_assert_event),
    .rvas_release_event_o     (rvas_release_event)
  );

  initial begin
    past_valid_q = 1'b0;
    reference_as_seen_q = 1'b0;
    reference_main_8mhz_high_q = 1'b0;
    reference_rva_q = 1'b0;
    reference_sampled_dtack_n_q = 1'b1;
    reference_rvas0_active_q = 1'b0;
    reference_rvas_active_q = 1'b0;
    reference_rvas0_assert_event_q = 1'b0;
    reference_rvas0_release_event_q = 1'b0;
    reference_assert_event_q = 1'b0;
    reference_release_event_q = 1'b0;
    saw_rvas0_early_q = 1'b0;
    saw_low_phase_assert_q = 1'b0;
    saw_preset_priority_q = 1'b0;
    saw_assert_q = 1'b0;
    saw_low_sample_q = 1'b0;
    saw_rva_end_q = 1'b0;
    saw_release_q = 1'b0;
    saw_missed_sample_q = 1'b0;
  end

  always_ff @(posedge clk_i) begin
    past_valid_q <= 1'b1;

    if (!past_valid_q) begin
      assume (initialize_i);
    end
    if (!initialize_i) begin
      assume (!(main_8mhz_rise_i && main_8mhz_fall_i));
      assume (!(address_strobe_assert_i && main_8mhz_rise_i));
      assume (!(address_strobe_assert_i && main_8mhz_fall_i));
      assume (!main_8mhz_rise_i || main_8mhz_high_i);
      assume (!main_8mhz_fall_i || !main_8mhz_high_i);
      assume (!main_8mhz_rise_i || !reference_main_8mhz_high_q);
      assume (!main_8mhz_fall_i || reference_main_8mhz_high_q);
      assume ((main_8mhz_high_i == reference_main_8mhz_high_q) ||
              (main_8mhz_high_i && main_8mhz_rise_i) ||
              (!main_8mhz_high_i && main_8mhz_fall_i));
    end

    if (past_valid_q) begin
      assert (rva == reference_rva_q);
      assert (sampled_dtack_n == reference_sampled_dtack_n_q);
      assert (rvas0_n == !reference_rvas0_active_q);
      assert (rvas_n == !reference_rvas_active_q);
      assert (rvas0_assert_event ==
              (!initialize_i && reference_rvas0_assert_event_q));
      assert (rvas0_release_event ==
              (!initialize_i && reference_rvas0_release_event_q));
      assert (rvas_assert_event ==
              (!initialize_i && reference_assert_event_q));
      assert (rvas_release_event ==
              (!initialize_i && reference_release_event_q));
    end

    if (initialize_i) begin
      reference_as_seen_q <= 1'b0;
      reference_main_8mhz_high_q <= 1'b0;
      reference_rva_q <= 1'b0;
      reference_sampled_dtack_n_q <= 1'b1;
      reference_rvas0_active_q <= 1'b0;
      reference_rvas_active_q <= 1'b0;
      reference_rvas0_assert_event_q <= 1'b0;
      reference_rvas0_release_event_q <= 1'b0;
      reference_assert_event_q <= 1'b0;
      reference_release_event_q <= 1'b0;
    end else begin
      reference_main_8mhz_high_q <= main_8mhz_high_i;
      reference_rvas0_assert_event_q <= 1'b0;
      reference_rvas0_release_event_q <= 1'b0;
      reference_assert_event_q <= 1'b0;
      reference_release_event_q <= 1'b0;
      if (address_strobe_assert_i) begin
        reference_as_seen_q <= 1'b1;
        if (!main_8mhz_high_i) begin
          reference_rvas0_active_q <= 1'b1;
          reference_rvas0_assert_event_q <=
            !reference_rvas0_active_q;
        end
      end
      if (main_8mhz_rise_i) begin
        reference_rva_q <= reference_as_seen_q;
        if (reference_as_seen_q) begin
          reference_as_seen_q <= 1'b0;
          reference_rvas_active_q <= 1'b1;
          reference_assert_event_q <= 1'b1;
        end
      end
      if (main_8mhz_fall_i) begin
        reference_sampled_dtack_n_q <= dtack_n_i;
        if (reference_as_seen_q) begin
          reference_rvas0_active_q <= 1'b1;
          reference_rvas0_assert_event_q <=
            !reference_rvas0_active_q;
        end else if (!reference_sampled_dtack_n_q && dtack_n_i) begin
          reference_rvas0_active_q <= 1'b0;
          reference_rvas0_release_event_q <=
            reference_rvas0_active_q;
        end
        if (!reference_sampled_dtack_n_q && dtack_n_i) begin
          reference_rvas_active_q <= 1'b0;
          reference_release_event_q <= 1'b1;
        end
      end
    end

    if (rvas0_assert_event && !rva) begin
      saw_rvas0_early_q <= 1'b1;
    end
    if (address_strobe_assert_i && !main_8mhz_high_i) begin
      saw_low_phase_assert_q <= 1'b1;
    end
    if (main_8mhz_fall_i && reference_as_seen_q &&
        !reference_sampled_dtack_n_q && dtack_n_i) begin
      saw_preset_priority_q <= 1'b1;
    end
    if (rvas_assert_event) begin
      saw_assert_q <= 1'b1;
    end
    if (!sampled_dtack_n && !rvas_n) begin
      saw_low_sample_q <= 1'b1;
    end
    if (saw_low_sample_q && !rva && !rvas_n) begin
      saw_rva_end_q <= 1'b1;
    end
    if (rvas_release_event) begin
      saw_release_q <= 1'b1;
    end
    if (main_8mhz_fall_i && dtack_n_i && rva && !rvas_n) begin
      saw_missed_sample_q <= 1'b1;
    end

    cover (saw_assert_q && saw_low_sample_q && saw_rva_end_q &&
           saw_release_q && rvas_n);
    cover (saw_missed_sample_q && !rva && !rvas_n);
    cover (rvas_release_event && sampled_dtack_n && rvas_n);
    cover (saw_rvas0_early_q && !rvas0_n && !rva);
    cover (saw_low_phase_assert_q && rvas0_assert_event && !rvas0_n);
    cover (saw_preset_priority_q && !rvas0_n && !rvas0_release_event);
    cover (rvas0_release_event && rvas0_n);
  end
endmodule

`default_nettype wire
