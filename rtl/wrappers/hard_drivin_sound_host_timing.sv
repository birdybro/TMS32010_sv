`default_nettype none

// Logical, same-clock adaptation of A044427 Rev-A's local-68000
// /AS -> RVA -> /DTACK -> /RVAS path and LS138 30P/30N qualification.
// The physical 8 MHz edges are represented by mutually exclusive enables.
// This adapter intentionally has no READY input: the board circuit emits one
// fixed acknowledgement pulse and cannot re-arm while /AS remains asserted.
module hard_drivin_sound_host_timing (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        host_8mhz_rise_i,
  input  logic        host_8mhz_fall_i,
  input  logic        address_strobe_assert_i,
  input  logic        address_strobe_deassert_i,
  input  logic [2:0]  function_code_i,
  input  logic [23:1] address_i,
  input  logic        read_not_write_i,
  input  logic        upper_data_strobe_n_i,
  input  logic        lower_data_strobe_n_i,

  output logic        cycle_active_o,
  output logic        rva_o,
  output logic        vpa_n_o,
  output logic        dtack_n_o,
  output logic        rvas_n_o,
  output logic        rvf_n_o,
  output logic        read_write_strobe_n_o,
  output logic        upper_write_enable_n_o,
  output logic        lower_write_enable_n_o,
  output logic        read_select_valid_o,
  output logic        write_select_valid_o,
  output logic [23:1] latched_address_o,
  output logic        latched_read_not_write_o,
  output logic        latched_upper_data_strobe_n_o,
  output logic        latched_lower_data_strobe_n_o,
  output logic [1:0]  select_quadrant_o,
  output logic [7:0]  target_select_o,
  output logic        cycle_complete_event_o,
  output logic        read_complete_event_o,
  output logic        write_complete_event_o,
  output logic        cycle_complete_o,
  output logic        read_complete_o,
  output logic        write_complete_o
);
  logic        as_seen_q;
  logic        dtack_seen_q;
  logic [2:0]  function_code_q;
  logic        rvf_address_qualified;
  logic        read_not_write_q;
  logic        upper_data_strobe_n_q;
  logic        lower_data_strobe_n_q;
  logic        normal_completion_seen_q;
  logic        initialized_q;

  logic io_decode_active;
  logic normal_completion_condition;

  logic previous_host_8mhz_rise;
  logic previous_host_8mhz_fall;
  logic previous_as_seen;
  logic previous_dtack_n;
  logic previous_start;
  logic previous_deassert;
  logic previous_normal_completion;
  logic previous_rvf_address_qualified;
  logic previous_read_not_write;

  assign vpa_n_o =
    !(cycle_active_o && (function_code_q == 3'b111));
  assign dtack_n_o = !(vpa_n_o && rva_o);
  assign rvas_n_o = dtack_seen_q && !rva_o;
  assign rvf_address_qualified =
    latched_address_o[23] &&
    (latched_address_o[16:14] == 3'b100);
  assign rvf_n_o = !(cycle_active_o && rvf_address_qualified);

  assign read_write_strobe_n_o = rvas_n_o || read_not_write_q;
  assign upper_write_enable_n_o =
    upper_data_strobe_n_q || read_write_strobe_n_o;
  assign lower_write_enable_n_o =
    lower_data_strobe_n_q || read_write_strobe_n_o;

  assign io_decode_active = !rvf_n_o && !rvas_n_o;
  assign read_select_valid_o = io_decode_active && read_not_write_q;
  assign write_select_valid_o = io_decode_active && !read_not_write_q;
  assign select_quadrant_o = latched_address_o[13:12];
  assign latched_read_not_write_o = read_not_write_q;
  assign latched_upper_data_strobe_n_o = upper_data_strobe_n_q;
  assign latched_lower_data_strobe_n_o = lower_data_strobe_n_q;

  always_comb begin
    target_select_o = 8'h00;
    if (io_decode_active) begin
      target_select_o =
        8'h01 << {read_not_write_q, select_quadrant_o};
    end
  end

  assign normal_completion_condition =
    cycle_active_o && vpa_n_o && !rva_o && !dtack_seen_q;
  // These pre-edge event forms let same-clock downstream storage consume the
  // selected strobe's S7 trailing edge. The registered forms below remain
  // available for trace/debug observation during the following clock.
  assign cycle_complete_event_o =
    host_8mhz_fall_i && normal_completion_condition;
  assign read_complete_event_o =
    cycle_complete_event_o && rvf_address_qualified && read_not_write_q;
  assign write_complete_event_o =
    cycle_complete_event_o && rvf_address_qualified && !read_not_write_q;

  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      // These idle values are a deterministic FPGA convention. The physical
      // F74 devices have pulled-high asynchronous controls and no board reset.
      cycle_active_o              <= 1'b0;
      rva_o                      <= 1'b0;
      as_seen_q                  <= 1'b0;
      dtack_seen_q               <= 1'b1;
      function_code_q            <= 3'b000;
      latched_address_o          <= '0;
      read_not_write_q           <= 1'b1;
      upper_data_strobe_n_q      <= 1'b1;
      lower_data_strobe_n_q      <= 1'b1;
      normal_completion_seen_q   <= 1'b0;
      cycle_complete_o           <= 1'b0;
      read_complete_o            <= 1'b0;
      write_complete_o           <= 1'b0;
      initialized_q              <= 1'b1;
    end else begin
      cycle_complete_o <= 1'b0;
      read_complete_o  <= 1'b0;
      write_complete_o <= 1'b0;

      // The first half of F74 40R is clocked by the positive form of AS,
      // which rises after the processor asserts active-low /AS.
      if (address_strobe_assert_i) begin
        cycle_active_o <= 1'b1;
        as_seen_q <= 1'b1;
        function_code_q <= function_code_i;
        latched_address_o <= address_i;
        read_not_write_q <= read_not_write_i;
        upper_data_strobe_n_q <= upper_data_strobe_n_i;
        lower_data_strobe_n_q <= lower_data_strobe_n_i;
        normal_completion_seen_q <= 1'b0;
      end

      // The second half of F74 40R samples as_seen_q on rising 8 MHz.
      // When it asserts RVA, /RVA asynchronously clears the first half; the
      // same-clock adaptation records the settled post-edge state directly.
      if (host_8mhz_rise_i) begin
        rva_o <= as_seen_q;
        if (as_seen_q) begin
          as_seen_q <= 1'b0;
        end
      end

      // F74 50S samples /DTACK on falling 8 MHz. A prior low sample keeps
      // /RVAS active after RVA drops; the following high sample releases it
      // at the MC68000 S7 data-latch boundary.
      if (host_8mhz_fall_i) begin
        dtack_seen_q <= dtack_n_o;
        if (cycle_complete_event_o) begin
          cycle_complete_o <= 1'b1;
          read_complete_o <=
            rvf_address_qualified && read_not_write_q;
          write_complete_o <=
            rvf_address_qualified && !read_not_write_q;
          normal_completion_seen_q <= 1'b1;
        end
      end

      // /AS is a processor output. The ordinary MC68000 path deasserts it at
      // S7; CPU-space/VPA cycles may hold it through their separate sequence.
      if (address_strobe_deassert_i) begin
        cycle_active_o <= 1'b0;
        normal_completion_seen_q <= 1'b0;
      end
    end
  end

  // Retained transition checks describe the explicit-edge contract without
  // relying on simulator-only temporal syntax.
  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      previous_host_8mhz_rise        <= 1'b0;
      previous_host_8mhz_fall        <= 1'b0;
      previous_as_seen               <= 1'b0;
      previous_dtack_n               <= 1'b1;
      previous_start                 <= 1'b0;
      previous_deassert              <= 1'b0;
      previous_normal_completion     <= 1'b0;
      previous_rvf_address_qualified <= 1'b0;
      previous_read_not_write        <= 1'b1;
    end else if (initialized_q) begin
      assert (!(host_8mhz_rise_i && host_8mhz_fall_i));
      assert (!(address_strobe_assert_i && host_8mhz_rise_i));
      assert (!(address_strobe_assert_i && host_8mhz_fall_i));
      assert (!(address_strobe_assert_i && address_strobe_deassert_i));
      assert (!(address_strobe_assert_i && cycle_active_o));
      assert (!address_strobe_deassert_i || cycle_active_o);
      assert (!address_strobe_deassert_i || !vpa_n_o ||
              normal_completion_condition || normal_completion_seen_q);

      assert (!(read_select_valid_o && write_select_valid_o));
      assert ($onehot0(target_select_o));
      assert (target_select_o ==
              (io_decode_active
                 ? (8'h01 << {read_not_write_q, select_quadrant_o})
                 : 8'h00));
      assert (rvf_n_o ==
              !(cycle_active_o && rvf_address_qualified));
      assert (dtack_n_o == !(vpa_n_o && rva_o));
      assert (rvas_n_o == (dtack_seen_q && !rva_o));
      assert (cycle_complete_event_o ==
              (host_8mhz_fall_i && normal_completion_condition));
      assert (read_complete_event_o ==
              (cycle_complete_event_o &&
               rvf_address_qualified && read_not_write_q));
      assert (write_complete_event_o ==
              (cycle_complete_event_o &&
               rvf_address_qualified && !read_not_write_q));

      if (previous_host_8mhz_rise) begin
        assert (rva_o == previous_as_seen);
        assert (!as_seen_q);
      end
      if (previous_host_8mhz_fall) begin
        assert (dtack_seen_q == previous_dtack_n);
      end
      if (previous_start) begin
        assert (cycle_active_o);
      end
      if (previous_deassert) begin
        assert (!cycle_active_o);
      end
      assert (cycle_complete_o == previous_normal_completion);
      assert (read_complete_o ==
              (previous_normal_completion &&
               previous_rvf_address_qualified &&
               previous_read_not_write));
      assert (write_complete_o ==
              (previous_normal_completion &&
               previous_rvf_address_qualified &&
               !previous_read_not_write));

      previous_host_8mhz_rise        <= host_8mhz_rise_i;
      previous_host_8mhz_fall        <= host_8mhz_fall_i;
      previous_as_seen               <= as_seen_q;
      previous_dtack_n               <= dtack_n_o;
      previous_start                 <= address_strobe_assert_i;
      previous_deassert              <= address_strobe_deassert_i;
      previous_normal_completion     <=
        host_8mhz_fall_i && normal_completion_condition;
      previous_rvf_address_qualified <= rvf_address_qualified;
      previous_read_not_write        <= read_not_write_q;
    end
  end
endmodule

`default_nettype wire
