`default_nettype none

module tms32010_program_bus (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic        rs_i,
  input  logic        clock_enable_i,
  input  logic [11:0] next_address_i,

  output logic [1:0]  phase_o,
  output logic        clkout_o,
  output logic [11:0] address_o,
  output logic        men_n_o,
  output logic        sample_o,
  output logic        active_o
);
  logic release_boundary_seen;

  assign clkout_o = phase_o[1];
  assign men_n_o  = ~active_o | (phase_o == 2'd0);

  always_ff @(posedge clk_i) begin
    sample_o <= 1'b0;

    if (initialize_i) begin
      phase_o                  <= 2'd0;
      address_o                <= 12'h000;
      active_o                 <= 1'b0;
      release_boundary_seen    <= 1'b0;
    end else begin
      if (clock_enable_i) begin
        phase_o <= phase_o + 2'd1;

        if (phase_o == 2'd3) begin
          if (rs_i) begin
            // RS is sampled at the falling-CLKOUT boundary. Complete the
            // current machine cycle before clearing the logical bus state.
            address_o             <= 12'h000;
            active_o              <= 1'b0;
            release_boundary_seen <= 1'b0;
          end else if (!release_boundary_seen) begin
            // Synchronize release at a falling-CLKOUT boundary, then retain
            // one complete inactive cycle as required by the data sheet.
            release_boundary_seen <= 1'b1;
          end else if (!active_o) begin
            active_o  <= 1'b1;
            address_o <= next_address_i;
          end else begin
            // The word associated with the old address is sampled here;
            // next_address_i becomes the following bus address.
            sample_o  <= 1'b1;
            address_o <= next_address_i;
          end
        end
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (!initialize_i) begin
      assert (!(sample_o && !active_o));
    end
  end
endmodule

`default_nettype wire
