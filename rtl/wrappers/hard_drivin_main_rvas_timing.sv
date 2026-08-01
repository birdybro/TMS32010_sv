`default_nettype none

// Same-clock event adaptation of the SP-327 main-board /AS -> /RVAS0, RVA,
// and sampled-/DTACK -> /RVAS hold logic. The caller supplies mutually
// exclusive 8 MHz edge events, the corresponding level, and the physical
// /DTACK level; the rest of the main-board acknowledgement tree and all
// raw-pin CDC remain external.
module hard_drivin_main_rvas_timing (
  input  logic clk_i,
  input  logic initialize_i,
  input  logic main_8mhz_rise_i,
  input  logic main_8mhz_fall_i,
  input  logic main_8mhz_high_i,
  input  logic address_strobe_assert_i,
  input  logic dtack_n_i,
  output logic rva_o,
  output logic sampled_dtack_n_o,
  output logic rvas0_n_o,
  output logic rvas_n_o,
  output logic rvas0_assert_event_o,
  output logic rvas0_release_event_o,
  output logic rvas_assert_event_o,
  output logic rvas_release_event_o
);
  logic as_seen_q;
  logic rvas0_active_q;
  logic rvas_active_q;
  logic rvas0_assert_event_q;
  logic rvas0_release_event_q;
  logic rvas_assert_event_q;
  logic rvas_release_event_q;
  logic initialized_q;

  logic previous_main_8mhz_rise_q;
  logic previous_main_8mhz_fall_q;
  logic previous_main_8mhz_high_q;
  logic previous_address_strobe_assert_q;
  logic previous_as_seen_q;
  logic previous_sampled_dtack_n_q;
  logic previous_dtack_n_q;
  logic previous_rvas0_active_q;

  assign rvas0_n_o = !rvas0_active_q;
  assign rvas_n_o = !rvas_active_q;
  assign rvas0_assert_event_o = !initialize_i && rvas0_assert_event_q;
  assign rvas0_release_event_o = !initialize_i && rvas0_release_event_q;
  assign rvas_assert_event_o = !initialize_i && rvas_assert_event_q;
  assign rvas_release_event_o = !initialize_i && rvas_release_event_q;

  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      // Deterministic idle is an FPGA convention. SP-327 ties the physical
      // F74 asynchronous controls high and does not reset this state.
      as_seen_q <= 1'b0;
      rva_o <= 1'b0;
      sampled_dtack_n_o <= 1'b1;
      rvas0_active_q <= 1'b0;
      rvas_active_q <= 1'b0;
      rvas0_assert_event_q <= 1'b0;
      rvas0_release_event_q <= 1'b0;
      rvas_assert_event_q <= 1'b0;
      rvas_release_event_q <= 1'b0;
      initialized_q <= 1'b1;
    end else begin
      rvas0_assert_event_q <= 1'b0;
      rvas0_release_event_q <= 1'b0;
      rvas_assert_event_q <= 1'b0;
      rvas_release_event_q <= 1'b0;

      // F74 135C captures the positive form of /AS assertion. F74 135H then
      // samples that state on rising 8 MHz and /RVA clears the first stage.
      if (address_strobe_assert_i) begin
        as_seen_q <= 1'b1;

        // AS32 135K drives the active-low preset of the D=0 /RVAS0 F74 from
        // 8MHZ OR /S4. An assertion during the low phase therefore presets
        // /RVAS0 immediately; a normal S2 high-phase assertion waits for S3.
        if (!main_8mhz_high_i) begin
          rvas0_active_q <= 1'b1;
          rvas0_assert_event_q <= !rvas0_active_q;
        end
      end
      if (main_8mhz_rise_i) begin
        rva_o <= as_seen_q;
        if (as_seen_q) begin
          as_seen_q <= 1'b0;
          // /RVA asynchronously presets F74 120H, asserting /RVAS.
          rvas_active_q <= 1'b1;
          rvas_assert_event_q <= 1'b1;
        end
      end

      // Falling 8 MHz both makes the /RVAS0 preset active for a pending /S4
      // and clocks /DTACK into F74 135C. The asynchronous preset dominates
      // the D=0 release clock if a new request and sampled release coincide.
      if (main_8mhz_fall_i) begin
        sampled_dtack_n_o <= dtack_n_i;
        if (as_seen_q) begin
          rvas0_active_q <= 1'b1;
          rvas0_assert_event_q <= !rvas0_active_q;
        end else if (!sampled_dtack_n_o && dtack_n_i) begin
          rvas0_active_q <= 1'b0;
          rvas0_release_event_q <= rvas0_active_q;
        end

        // The sampled-/DTACK Q also clocks the D=0 /RVAS F74, so only a
        // sampled low-to-high transition releases the separately preset hold.
        if (!sampled_dtack_n_o && dtack_n_i) begin
          rvas_active_q <= 1'b0;
          rvas_release_event_q <= 1'b1;
        end
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      previous_main_8mhz_rise_q <= 1'b0;
      previous_main_8mhz_fall_q <= 1'b0;
      previous_main_8mhz_high_q <= 1'b0;
      previous_address_strobe_assert_q <= 1'b0;
      previous_as_seen_q <= 1'b0;
      previous_sampled_dtack_n_q <= 1'b1;
      previous_dtack_n_q <= 1'b1;
      previous_rvas0_active_q <= 1'b0;
    end else if (initialized_q) begin
      assert (!(main_8mhz_rise_i && main_8mhz_fall_i));
      assert (!(address_strobe_assert_i && main_8mhz_rise_i));
      assert (!(address_strobe_assert_i && main_8mhz_fall_i));
      assert (!main_8mhz_rise_i || main_8mhz_high_i);
      assert (!main_8mhz_fall_i || !main_8mhz_high_i);
      assert (!main_8mhz_rise_i || !previous_main_8mhz_high_q);
      assert (!main_8mhz_fall_i || previous_main_8mhz_high_q);
      assert ((main_8mhz_high_i == previous_main_8mhz_high_q) ||
              (main_8mhz_high_i && main_8mhz_rise_i) ||
              (!main_8mhz_high_i && main_8mhz_fall_i));
      assert (!rvas0_assert_event_o || !rvas0_release_event_o);
      assert (!rvas_assert_event_o || !rvas_release_event_o);
      assert (rvas0_n_o == !rvas0_active_q);
      assert (rvas_n_o == !rvas_active_q);

      if (previous_address_strobe_assert_q &&
          !previous_main_8mhz_high_q) begin
        assert (!rvas0_n_o);
        if (!previous_rvas0_active_q) begin
          assert (rvas0_assert_event_o);
        end
      end

      if (previous_main_8mhz_rise_q) begin
        assert (rva_o == previous_as_seen_q);
        if (previous_as_seen_q) begin
          assert (!as_seen_q);
          assert (!rvas_n_o);
          assert (rvas_assert_event_o);
        end
      end
      if (previous_main_8mhz_fall_q) begin
        assert (sampled_dtack_n_o == previous_dtack_n_q);
        if (previous_as_seen_q) begin
          assert (!rvas0_n_o);
          if (!previous_rvas0_active_q) begin
            assert (rvas0_assert_event_o);
          end
        end else if (!previous_sampled_dtack_n_q &&
                     previous_dtack_n_q && previous_rvas0_active_q) begin
          assert (rvas0_n_o);
          assert (rvas0_release_event_o);
        end
        if (!previous_sampled_dtack_n_q && previous_dtack_n_q) begin
          assert (rvas_n_o);
          assert (rvas_release_event_o);
        end
      end

      previous_main_8mhz_rise_q <= main_8mhz_rise_i;
      previous_main_8mhz_fall_q <= main_8mhz_fall_i;
      previous_main_8mhz_high_q <= main_8mhz_high_i;
      previous_address_strobe_assert_q <= address_strobe_assert_i;
      previous_as_seen_q <= as_seen_q;
      previous_sampled_dtack_n_q <= sampled_dtack_n_o;
      previous_dtack_n_q <= dtack_n_i;
      previous_rvas0_active_q <= rvas0_active_q;
    end
  end
endmodule

`default_nettype wire
