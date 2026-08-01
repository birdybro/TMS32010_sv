`default_nettype none

// FORMAL-001 bounded proof for the isolated A044427 same-clock host-timing
// adapter. The assumptions describe legal event ownership only; address,
// function code, direction, byte strobes, and spacing between events remain
// arbitrary. See formal/README.md for the exact claim boundary.
module hard_drivin_sound_host_timing_formal (
  input logic        clk_i,
  input logic        host_8mhz_rise_i,
  input logic        host_8mhz_fall_i,
  input logic        address_strobe_assert_i,
  input logic        address_strobe_deassert_i,
  input logic [2:0]  function_code_i,
  input logic [23:1] address_i,
  input logic        read_not_write_i,
  input logic        upper_data_strobe_n_i,
  input logic        lower_data_strobe_n_i
);
  logic        initialized = 1'b0;
  logic        past_valid = 1'b0;
  logic        armed_model = 1'b0;
  logic        ordinary_completed = 1'b0;
  logic        captured_read_not_write_model = 1'b1;
  logic [2:0]  captured_function_code_model = 3'b000;
  logic        edge_seen_model = 1'b0;
  logic        last_edge_was_rise_model = 1'b0;
  logic        vpa_rva_seen_model = 1'b0;
  logic        vpa_release_ready_model = 1'b0;
  logic [2:0]  read_cover_stage = 3'd0;
  logic [2:0]  write_cover_stage = 3'd0;
  logic [2:0]  vpa_cover_stage = 3'd0;
  logic        initialize;

  logic        cycle_active;
  logic        rva;
  logic        vpa_n;
  logic        dtack_n;
  logic        rvas_n;
  logic        rvf_n;
  logic        read_write_strobe_n;
  logic        upper_write_enable_n;
  logic        lower_write_enable_n;
  logic        read_select_valid;
  logic        write_select_valid;
  logic [23:1] latched_address;
  logic        latched_upper_data_strobe_n;
  logic        latched_lower_data_strobe_n;
  logic        latched_read_not_write;
  logic [1:0]  select_quadrant;
  logic [7:0]  target_select;
  logic        cycle_complete_event;
  logic        read_complete_event;
  logic        write_complete_event;
  logic        cycle_complete;
  logic        read_complete;
  logic        write_complete;
  logic        qualified_address;
  logic        expected_cycle_event;

  assign initialize = !initialized;
  assign qualified_address =
    latched_address[23] && (latched_address[16:14] == 3'b100);
  assign expected_cycle_event =
    host_8mhz_fall_i && cycle_active && vpa_n &&
    !rva && !rvas_n;

  hard_drivin_sound_host_timing dut (
    .clk_i                         (clk_i),
    .initialize_i                  (initialize),
    .host_8mhz_rise_i              (host_8mhz_rise_i),
    .host_8mhz_fall_i              (host_8mhz_fall_i),
    .address_strobe_assert_i       (address_strobe_assert_i),
    .address_strobe_deassert_i     (address_strobe_deassert_i),
    .function_code_i               (function_code_i),
    .address_i                     (address_i),
    .read_not_write_i              (read_not_write_i),
    .upper_data_strobe_n_i         (upper_data_strobe_n_i),
    .lower_data_strobe_n_i         (lower_data_strobe_n_i),
    .cycle_active_o                (cycle_active),
    .rva_o                         (rva),
    .vpa_n_o                       (vpa_n),
    .dtack_n_o                     (dtack_n),
    .rvas_n_o                      (rvas_n),
    .rvf_n_o                       (rvf_n),
    .read_write_strobe_n_o         (read_write_strobe_n),
    .upper_write_enable_n_o        (upper_write_enable_n),
    .lower_write_enable_n_o        (lower_write_enable_n),
    .read_select_valid_o           (read_select_valid),
    .write_select_valid_o          (write_select_valid),
    .latched_address_o             (latched_address),
    .latched_read_not_write_o      (latched_read_not_write),
    .latched_upper_data_strobe_n_o (latched_upper_data_strobe_n),
    .latched_lower_data_strobe_n_o (latched_lower_data_strobe_n),
    .select_quadrant_o             (select_quadrant),
    .target_select_o               (target_select),
    .cycle_complete_event_o        (cycle_complete_event),
    .read_complete_event_o         (read_complete_event),
    .write_complete_event_o        (write_complete_event),
    .cycle_complete_o              (cycle_complete),
    .read_complete_o               (read_complete),
    .write_complete_o              (write_complete)
  );

  always_ff @(posedge clk_i) begin
    initialized <= 1'b1;
    past_valid <= 1'b1;

    // Same-clock caller contract. Stalls are represented by clocks with none
    // of these explicit events asserted. CPU-space deassertion remains owned
    // by the external VPA sequence; an ordinary cycle may release /AS at its
    // S7 event or after the registered completion pulse.
    if (initialized) begin
      assume (!(host_8mhz_rise_i && host_8mhz_fall_i));
      assume (!(address_strobe_assert_i && host_8mhz_rise_i));
      assume (!(address_strobe_assert_i && host_8mhz_fall_i));
      assume (!(address_strobe_assert_i && address_strobe_deassert_i));
      assume (!address_strobe_assert_i || !cycle_active);
      assume (!address_strobe_deassert_i || cycle_active);
      assume (!host_8mhz_rise_i || !edge_seen_model ||
              !last_edge_was_rise_model);
      assume (!host_8mhz_fall_i || !edge_seen_model ||
              last_edge_was_rise_model);
      assume (!address_strobe_deassert_i || !vpa_n ||
              expected_cycle_event || cycle_complete);
      assume (!address_strobe_deassert_i || vpa_n ||
              (vpa_release_ready_model &&
               !host_8mhz_rise_i && !host_8mhz_fall_i &&
               !rva && rvas_n));
    end

    if (initialize) begin
      armed_model <= 1'b0;
      ordinary_completed <= 1'b0;
      captured_read_not_write_model <= 1'b1;
      captured_function_code_model <= 3'b000;
      edge_seen_model <= 1'b0;
      last_edge_was_rise_model <= 1'b0;
      vpa_rva_seen_model <= 1'b0;
      vpa_release_ready_model <= 1'b0;
    end else begin
      if (host_8mhz_rise_i || host_8mhz_fall_i) begin
        edge_seen_model <= 1'b1;
        last_edge_was_rise_model <= host_8mhz_rise_i;
      end
      if (address_strobe_assert_i) begin
        armed_model <= 1'b1;
        ordinary_completed <= 1'b0;
        captured_read_not_write_model <= read_not_write_i;
        captured_function_code_model <= function_code_i;
        vpa_rva_seen_model <= 1'b0;
        vpa_release_ready_model <= 1'b0;
      end
      if (host_8mhz_rise_i && cycle_active && !vpa_n && armed_model) begin
        vpa_rva_seen_model <= 1'b1;
      end
      if (host_8mhz_fall_i && cycle_active && !vpa_n &&
          vpa_rva_seen_model && !rva && rvas_n) begin
        vpa_release_ready_model <= 1'b1;
      end
      if (host_8mhz_rise_i) begin
        armed_model <= 1'b0;
      end
      if (cycle_complete_event && !address_strobe_deassert_i) begin
        ordinary_completed <= 1'b1;
      end
      if (address_strobe_deassert_i) begin
        ordinary_completed <= 1'b0;
        vpa_rva_seen_model <= 1'b0;
        vpa_release_ready_model <= 1'b0;
      end
    end

    if (initialized) begin
      assert (vpa_n ==
              !(cycle_active && captured_function_code_model == 3'b111));
      assert (dtack_n == !(vpa_n && rva));
      assert (rvf_n == !(cycle_active && qualified_address));
      assert (select_quadrant == latched_address[13:12]);
      assert (read_write_strobe_n ==
              (rvas_n || captured_read_not_write_model));
      assert (latched_read_not_write == captured_read_not_write_model);
      assert (upper_write_enable_n ==
              (latched_upper_data_strobe_n || read_write_strobe_n));
      assert (lower_write_enable_n ==
              (latched_lower_data_strobe_n || read_write_strobe_n));
      assert (read_select_valid ==
              (!rvf_n && !rvas_n && captured_read_not_write_model));
      assert (write_select_valid ==
              (!rvf_n && !rvas_n && !captured_read_not_write_model));
      assert (target_select ==
              ((!rvf_n && !rvas_n)
                 ? (8'h01 <<
                    {captured_read_not_write_model, select_quadrant})
                 : 8'h00));
      assert (cycle_complete_event == expected_cycle_event);
      assert (read_complete_event ==
              (expected_cycle_event && qualified_address &&
               captured_read_not_write_model));
      assert (write_complete_event ==
              (expected_cycle_event && qualified_address &&
               !captured_read_not_write_model));
      assert (!(read_select_valid && write_select_valid));
      assert ($onehot0(target_select));
      assert (!read_select_valid || target_select[7:4] != 4'b0000);
      assert (!write_select_valid || target_select[3:0] != 4'b0000);

      if (!vpa_n) begin
        assert (dtack_n);
        assert (!cycle_complete_event);
        assert (!read_complete_event && !write_complete_event);
      end

      if (ordinary_completed) begin
        assert (cycle_active);
        assert (!rva && dtack_n && rvas_n);
        assert (!read_select_valid && !write_select_valid);
        assert (target_select == 8'h00);
        assert (!cycle_complete_event);
      end
    end

    if (past_valid) begin
      if ($past(initialize)) begin
        assert (!cycle_active && !rva && vpa_n && dtack_n && rvas_n && rvf_n);
        assert (latched_address == '0);
        assert (latched_upper_data_strobe_n &&
                latched_lower_data_strobe_n);
        assert (!cycle_complete && !read_complete && !write_complete);
      end else begin
        assert (cycle_complete == $past(cycle_complete_event));
        assert (read_complete == $past(read_complete_event));
        assert (write_complete == $past(write_complete_event));

        if ($past(address_strobe_assert_i)) begin
          assert (cycle_active);
          assert (latched_address == $past(address_i));
          assert (select_quadrant == $past(address_i[13:12]));
          assert (latched_upper_data_strobe_n ==
                  $past(upper_data_strobe_n_i));
          assert (latched_lower_data_strobe_n ==
                  $past(lower_data_strobe_n_i));
          assert (vpa_n == ($past(function_code_i) != 3'b111));
          assert (rvf_n ==
                  !($past(address_i[23]) &&
                    ($past(address_i[16:14]) == 3'b100)));
        end else begin
          assert (latched_address == $past(latched_address));
          assert (latched_upper_data_strobe_n ==
                  $past(latched_upper_data_strobe_n));
          assert (latched_lower_data_strobe_n ==
                  $past(latched_lower_data_strobe_n));
        end

        if ($past(host_8mhz_rise_i)) begin
          assert (rva == $past(armed_model));
        end else begin
          assert (rva == $past(rva));
        end
      end
    end

    // Three non-vacuity paths select an ordinary complete-word read, an
    // ordinary complete-word write, and a CPU-space/VPA cycle. Each includes
    // the otherwise state-neutral falling edge between AS assertion and S4.
    if (!initialized) begin
      read_cover_stage <= 3'd0;
      write_cover_stage <= 3'd0;
      vpa_cover_stage <= 3'd0;
    end else begin
      case (read_cover_stage)
        3'd0: if (address_strobe_assert_i &&
                  function_code_i != 3'b111 &&
                  address_i[23] && address_i[16:14] == 3'b100 &&
                  read_not_write_i && !upper_data_strobe_n_i &&
                  !lower_data_strobe_n_i &&
                  address_i[13:12] == 2'b00) begin
          read_cover_stage <= 3'd1;
        end
        3'd1: if (host_8mhz_fall_i) read_cover_stage <= 3'd2;
        3'd2: if (host_8mhz_rise_i) read_cover_stage <= 3'd3;
        3'd3: if (host_8mhz_fall_i) read_cover_stage <= 3'd4;
        3'd4: if (host_8mhz_rise_i) read_cover_stage <= 3'd5;
        3'd5: if (host_8mhz_fall_i && address_strobe_deassert_i &&
                  read_complete_event) read_cover_stage <= 3'd6;
        default: read_cover_stage <= read_cover_stage;
      endcase

      case (write_cover_stage)
        3'd0: if (address_strobe_assert_i &&
                  function_code_i != 3'b111 &&
                  address_i[23] && address_i[16:14] == 3'b100 &&
                  !read_not_write_i && !upper_data_strobe_n_i &&
                  !lower_data_strobe_n_i && address_i[13:12] == 2'b00) begin
          write_cover_stage <= 3'd1;
        end
        3'd1: if (host_8mhz_fall_i) write_cover_stage <= 3'd2;
        3'd2: if (host_8mhz_rise_i) write_cover_stage <= 3'd3;
        3'd3: if (host_8mhz_fall_i) write_cover_stage <= 3'd4;
        3'd4: if (host_8mhz_rise_i) write_cover_stage <= 3'd5;
        3'd5: if (host_8mhz_fall_i && address_strobe_deassert_i &&
                  write_complete_event) write_cover_stage <= 3'd6;
        default: write_cover_stage <= write_cover_stage;
      endcase

      case (vpa_cover_stage)
        3'd0: if (address_strobe_assert_i &&
                  function_code_i == 3'b111) begin
          vpa_cover_stage <= 3'd1;
        end
        3'd1: if (host_8mhz_fall_i) vpa_cover_stage <= 3'd2;
        3'd2: if (host_8mhz_rise_i) vpa_cover_stage <= 3'd3;
        3'd3: if (host_8mhz_fall_i) vpa_cover_stage <= 3'd4;
        3'd4: if (host_8mhz_rise_i) vpa_cover_stage <= 3'd5;
        3'd5: if (host_8mhz_fall_i && !cycle_complete_event) begin
          vpa_cover_stage <= 3'd6;
        end
        3'd6: if (address_strobe_deassert_i &&
                  !host_8mhz_rise_i && !host_8mhz_fall_i) begin
          vpa_cover_stage <= 3'd7;
        end
        default: vpa_cover_stage <= vpa_cover_stage;
      endcase
    end

    cover (read_cover_stage == 3'd6 && !cycle_active && read_complete);
    cover (write_cover_stage == 3'd6 && !cycle_active && write_complete);
    cover (vpa_cover_stage == 3'd7 && !cycle_active &&
           !cycle_complete && !read_complete && !write_complete);
  end
endmodule

`default_nettype wire
