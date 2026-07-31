`default_nettype none

module tb_banz_phase;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic [15:0] program_data;
  logic [1:0]  phase;
  logic        clkout;
  logic [11:0] program_address;
  logic        men_n;
  logic        sample;
  logic        bus_active;
  logic [11:0] pc;
  logic [15:0] auxiliary_register_0;
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_phase_slice dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .rs_i                          (rs),
    .clock_enable_i                (clock_enable),
    .bio_i                          (1'b1),
    .program_data_i                (program_data),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .program_address_o             (program_address),
    .men_n_o                       (men_n),
    .sample_o                      (sample),
    .bus_active_o                  (bus_active),
    .data_address_o                (),
    .data_read_o                   (),
    .data_write_o                  (),
    .data_address_valid_o          (),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .pc_o                          (pc),
    .accumulator_o                 (),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (),
    .instruction_valid_o           (instruction_valid),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
  );

  assign program_data = program_memory[program_address];

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

  task automatic advance_to_sample;
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require(clkout == phase[1], "CLKOUT follows native phase encoding");
      if (sample) begin
        return;
      end
    end
    $fatal(1, "sample event did not arrive");
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7000;  // LARK AR0,0
    program_memory[1] = 16'hf400;  // untaken BANZ
    program_memory[2] = 16'h0006;  // fetched even when untaken
    program_memory[3] = 16'h7001;  // LARK AR0,1
    program_memory[4] = 16'hf400;  // taken BANZ
    program_memory[5] = 16'h0008;  // branch target
    program_memory[6] = 16'h7f89;  // skipped ZAC
    program_memory[7] = 16'h7f89;  // skipped ZAC
    program_memory[8] = 16'h7f80;  // branch destination

    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;

    for (int unsigned index = 0; index < 20; index++) begin
      tick();
      require(!bus_active && men_n, "reset keeps native bus inactive");
    end

    rs = 1'b0;
    advance_to_sample();
    require(retired && pc == 12'h001 &&
            program_address == 12'h001 && cycle_count == 32'd1,
            "setup LARK retires and advances to BANZ");
    require(auxiliary_register_0 == 16'h0000,
            "setup establishes a zero counter");

    advance_to_sample();
    require(sample && instruction_valid && !retired && !illegal,
            "BANZ opcode sample starts, but does not retire, the instruction");
    require(pc == 12'h002 && program_address == 12'h002 &&
            cycle_count == 32'd2,
            "first BANZ cycle advances to its target word");

    tick();
    require(phase == 2'd1 && bus_active && !men_n,
            "target word receives the ordinary active MEN phase");
    require(program_address == 12'h002 && !sample && !retired,
            "target address remains visible before its sample boundary");
    clock_enable = 1'b0;
    for (int unsigned index = 0; index < 3; index++) begin
      tick();
      require(phase == 2'd1 && program_address == 12'h002 &&
              !men_n && !sample && !retired &&
              pc == 12'h002 && cycle_count == 32'd2,
              "clock-enable stall holds the BANZ target read and state");
    end
    clock_enable = 1'b1;

    advance_to_sample();
    require(sample && retired && !illegal && pc == 12'h003 &&
            program_address == 12'h003 && cycle_count == 32'd3,
            "zero counter retires BANZ after the second normal read cycle");
    require(auxiliary_register_0 == 16'h01ff,
            "untaken BANZ wraps the low-nine counter");

    advance_to_sample();
    require(retired && pc == 12'h004 &&
            program_address == 12'h004 && cycle_count == 32'd4,
            "second setup LARK retires normally");
    require(auxiliary_register_0 == 16'h0001,
            "taken-path setup establishes a nonzero counter");

    advance_to_sample();
    require(sample && !retired && !illegal && pc == 12'h005 &&
            program_address == 12'h005 && cycle_count == 32'd5,
            "taken BANZ still fetches its following target word first");

    advance_to_sample();
    require(sample && retired && !illegal && pc == 12'h008 &&
            program_address == 12'h008 && cycle_count == 32'd6,
            "nonzero counter selects the fetched target at cycle two");
    require(auxiliary_register_0 == 16'h0000,
            "taken BANZ decrements after testing the old counter");

    advance_to_sample();
    require(retired && pc == 12'h009 &&
            program_address == 12'h009 && cycle_count == 32'd7,
            "target NOP retires after the branch");

    $display("PASS tb_banz_phase");
    $finish;
  end
endmodule

`default_nettype wire
