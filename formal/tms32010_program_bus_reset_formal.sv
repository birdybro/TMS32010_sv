`default_nettype none

// CTRL-001 bounded proof for the active-high logical reset presented to the
// native program-bus phase engine. The physical TMS32010 pin is active-low;
// polarity conversion belongs at the pin wrapper.
module tms32010_program_bus_reset_formal (
  input logic        clk_i,
  input logic        rs_i,
  input logic        clock_enable_i,
  input logic        program_read_i,
  input logic [11:0] next_address_i
);
  logic       initialized = 1'b0;
  logic       past_valid = 1'b0;
  logic       release_boundary_model = 1'b0;
  logic [5:0] cover_stage = 6'd0;
  logic       initialize;
  logic [1:0] phase;
  logic       clkout;
  logic [11:0] address;
  logic       men_n;
  logic       sample;
  logic       active;

  assign initialize = !initialized;

  tms32010_program_bus dut (
    .clk_i          (clk_i),
    .initialize_i   (initialize),
    .rs_i           (rs_i),
    .clock_enable_i (clock_enable_i),
    .program_read_i (program_read_i),
    .next_address_i (next_address_i),
    .phase_o        (phase),
    .clkout_o       (clkout),
    .address_o      (address),
    .men_n_o        (men_n),
    .sample_o       (sample),
    .active_o       (active)
  );

  always_ff @(posedge clk_i) begin
    initialized <= 1'b1;
    past_valid  <= 1'b1;

    // This monitor states the source-derived release contract independently
    // of the DUT's private release-history bit. Reset is recognized only at
    // an enabled falling-CLKOUT boundary; two deasserted boundaries are
    // required before the bus can be active.
    if (initialize) begin
      release_boundary_model <= 1'b0;
    end else if (clock_enable_i && phase == 2'd3) begin
      if (rs_i) begin
        release_boundary_model <= 1'b0;
      end else if (!release_boundary_model) begin
        release_boundary_model <= 1'b1;
      end
    end

    if (initialized) begin
      assert (clkout == phase[1]);
      assert (men_n ==
              (~active | ~program_read_i | (phase == 2'd0)));
      assert (!sample || (active && phase == 2'd0));
      assert (!active || release_boundary_model);
    end

    if (past_valid) begin
      if ($past(initialize)) begin
        assert (phase == 2'd0);
        assert (address == 12'h000);
        assert (!active && !sample);
      end else begin
        if ($past(clock_enable_i)) begin
          assert (phase == $past(phase) + 2'd1);
        end else begin
          assert (phase == $past(phase));
          assert (clkout == $past(clkout));

          // program_read_i is a combinational transaction qualifier rather
          // than retained DUT state.  With that wrapper-owned qualifier held
          // stable, a disabled host clock also holds the native MEN level.
          if (program_read_i == $past(program_read_i)) begin
            assert (men_n == $past(men_n));
          end
        end

        if (!$past(clock_enable_i) || $past(phase) != 2'd3) begin
          // Physical RS is synchronous: assertion before its recognition
          // boundary does not asynchronously abort an in-flight read.
          assert (active == $past(active));
          assert (address == $past(address));
          assert (!sample);
        end else if ($past(rs_i)) begin
          // The recognized boundary disables the logical transaction and
          // establishes the documented reset address.
          assert (!active);
          assert (address == 12'h000);
          assert (!sample);
        end else if (!$past(release_boundary_model)) begin
          // First deasserted falling boundary synchronizes release. The
          // following complete machine cycle remains inactive.
          assert (!active);
          assert (address == $past(address));
          assert (!sample);
        end else if (!$past(active)) begin
          // Second deasserted boundary begins the first post-reset read.
          assert (active);
          assert (address == $past(next_address_i));
          assert (!sample);
        end else begin
          // An ordinary active read samples the old address and advances to
          // the next one at the falling boundary.
          assert (active);
          assert (address == $past(next_address_i));
          assert (sample);
        end
      end
    end

    // Non-vacuity path: five consecutive complete asserted cycles, release
    // synchronization, one full inactive cycle, address-0 read, then the
    // address-1 sample boundary. Clock-enable stalls remain arbitrary in the
    // safety proof; this cover deliberately selects an unstalled path.
    if (!initialized) begin
      cover_stage <= 6'd0;
    end else begin
      case (cover_stage)
        6'd0: begin
          if (
            phase == 2'd0 &&
            !active &&
            address == 12'h000 &&
            rs_i &&
            clock_enable_i
          ) begin
            cover_stage <= 6'd1;
          end
        end
        6'd1, 6'd2, 6'd3, 6'd4, 6'd5, 6'd6, 6'd7, 6'd8,
        6'd9, 6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15,
        6'd16, 6'd17, 6'd18, 6'd19: begin
          if (rs_i && clock_enable_i) begin
            cover_stage <= cover_stage + 6'd1;
          end else begin
            cover_stage <= 6'd0;
          end
        end
        6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26: begin
          if (!rs_i && clock_enable_i) begin
            cover_stage <= cover_stage + 6'd1;
          end else begin
            cover_stage <= 6'd0;
          end
        end
        6'd27: begin
          if (!rs_i && clock_enable_i && next_address_i == 12'h000) begin
            cover_stage <= 6'd28;
          end else begin
            cover_stage <= 6'd0;
          end
        end
        6'd28, 6'd29, 6'd30: begin
          if (!rs_i && clock_enable_i && program_read_i) begin
            cover_stage <= cover_stage + 6'd1;
          end else begin
            cover_stage <= 6'd0;
          end
        end
        6'd31: begin
          if (
            !rs_i &&
            clock_enable_i &&
            program_read_i &&
            next_address_i == 12'h001
          ) begin
            cover_stage <= 6'd32;
          end else begin
            cover_stage <= 6'd0;
          end
        end
        default: begin
          cover_stage <= cover_stage;
        end
      endcase
    end

    cover (
      initialized &&
      cover_stage == 6'd32 &&
      active &&
      sample &&
      phase == 2'd0 &&
      address == 12'h001 &&
      men_n
    );
  end
endmodule

`default_nettype wire
