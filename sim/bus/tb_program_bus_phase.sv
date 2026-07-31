`default_nettype none

module tb_program_bus_phase;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic [11:0] next_address;
  logic [1:0]  phase;
  logic        clkout;
  logic [11:0] address;
  logic        men_n;
  logic        sample;
  logic        active;

  tms32010_program_bus dut (
    .clk_i          (clk),
    .initialize_i   (initialize),
    .rs_i           (rs),
    .clock_enable_i (clock_enable),
    .program_read_i (1'b1),
    .next_address_i (next_address),
    .phase_o        (phase),
    .clkout_o       (clkout),
    .address_o      (address),
    .men_n_o        (men_n),
    .sample_o       (sample),
    .active_o       (active)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    @(posedge clk);
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  task automatic check_phase_outputs;
    require(clkout == phase[1], "CLKOUT follows four-phase encoding");
    require(men_n == (!active || phase == 2'd0), "MEN phase relationship");
    require(!(sample && phase != 2'd0), "sampling occurs after falling edge");
  endtask

  initial begin
    // FPGA initialization is explicitly separate from physical RS.
    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    next_address = 12'h000;
    tick();
    require(phase == 2'd0, "initialization establishes phase zero");
    initialize = 1'b0;

    // Physical RS remains asserted for the required five complete machine
    // cycles while CLKOUT continues to run.
    for (int unsigned index = 0; index < 20; index++) begin
      tick();
      check_phase_outputs();
      require(!active && men_n, "reset keeps bus inactive");
      require(address == 12'h000, "reset address is zero");
    end
    require(phase == 2'd0, "five reset cycles wrap phase");

    // Release is recognized at the first falling boundary. The complete
    // following machine cycle remains inactive; the bus starts at the second
    // boundary and asserts MEN one quarter-cycle later.
    rs           = 1'b0;
    next_address = 12'h000;
    for (int unsigned index = 0; index < 4; index++) begin
      tick();
      check_phase_outputs();
      require(!active, "release synchronization cycle remains inactive");
    end
    for (int unsigned index = 0; index < 3; index++) begin
      tick();
      check_phase_outputs();
      require(!active, "full release wait cycle remains inactive");
    end
    tick();
    check_phase_outputs();
    require(active, "bus activates after full release cycle");
    require(phase == 2'd0 && men_n, "address transition phase has MEN high");
    require(address == 12'h000, "first reset fetch uses address zero");
    require(!sample, "activation boundary does not sample");

    tick();
    check_phase_outputs();
    require(phase == 2'd1 && !men_n, "MEN asserts one quarter-cycle later");
    next_address = 12'h001;
    tick();
    check_phase_outputs();
    require(phase == 2'd2 && !men_n, "MEN stays active through rising edge");
    tick();
    check_phase_outputs();
    require(phase == 2'd3 && !men_n, "MEN stays active before sample");
    require(address == 12'h000, "address stable for entire active strobe");
    tick();
    check_phase_outputs();
    require(sample, "falling boundary samples input");
    require(address == 12'h001, "second reset fetch uses address one");
    require(men_n, "MEN deasserts for address transition");

    // A disabled FPGA phase clock holds pin phase and address/control state.
    clock_enable = 1'b0;
    tick();
    require(!sample, "sample event is a single FPGA-clock pulse");
    logic_stall_check: begin
      logic [1:0] saved_phase;
      logic [11:0] saved_address;
      logic saved_clkout;
      logic saved_men_n;
      saved_phase   = phase;
      saved_address = address;
      saved_clkout  = clkout;
      saved_men_n   = men_n;
      tick();
      require(phase == saved_phase, "disabled phase holds");
      require(address == saved_address, "disabled address holds");
      require(clkout == saved_clkout && men_n == saved_men_n,
              "disabled bus controls hold");
    end

    // A newly asserted RS permits the current machine cycle to finish and
    // disables the strobe at the next falling-CLKOUT boundary.
    clock_enable = 1'b1;
    rs           = 1'b1;
    for (int unsigned index = 0; index < 4; index++) begin
      tick();
    end
    require(!active && men_n, "reset aborts logical bus activity");
    require(address == 12'h000, "reset restores address zero");

    $display("PASS tb_program_bus_phase");
    $finish;
  end
endmodule

`default_nettype wire
