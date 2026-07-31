`default_nettype none

module tb_table_transfer_phase;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic [15:0] program_data;
  logic [1:0]  phase;
  logic        clkout;
  logic [11:0] native_address;
  logic        men_n;
  logic        den_n;
  logic        we_n;
  logic        sample;
  logic        bus_active;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic [15:0] data_write_data;
  logic        program_write;
  logic [15:0] program_write_data;
  logic [11:0] pc;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_phase_slice dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .rs_i                          (rs),
    .clock_enable_i                (clock_enable),
    .bio_i                         (1'b1),
    .program_data_i                (program_data),
    .io_read_data_i                (16'h0000),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .program_address_o             (native_address),
    .men_n_o                       (men_n),
    .den_n_o                       (den_n),
    .we_n_o                        (we_n),
    .sample_o                      (sample),
    .bus_active_o                  (bus_active),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (data_write_data),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .io_write_data_o               (),
    .program_write_o               (program_write),
    .program_write_data_o          (program_write_data),
    .pc_o                          (pc),
    .accumulator_o                 (),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (),
    .instruction_valid_o           (),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
  );

  assign program_data = program_memory[native_address];

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

  task automatic check_exclusive_strobes;
    require(clkout == phase[1], "CLKOUT follows native phase encoding");
    require(
      !(
        (!men_n && !den_n) ||
        (!men_n && !we_n) ||
        (!den_n && !we_n)
      ),
      "MEN, DEN, and WE are mutually exclusive"
    );
  endtask

  task automatic advance_to_sample;
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      check_exclusive_strobes();
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
    program_memory[0]  = 16'h7e20;
    program_memory[1]  = 16'h6703;
    program_memory[2]  = 16'h7e21;
    program_memory[3]  = 16'h7d03;
    program_memory[4]  = 16'h7f80;
    program_memory[32] = 16'hbeef;
    program_memory[33] = 16'haaaa;

    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;
    repeat (20) begin
      tick();
      require(!bus_active && men_n && den_n && we_n,
              "reset keeps every native strobe inactive");
    end

    rs = 1'b0;
    advance_to_sample();
    require(retired && pc == 12'd1 && cycle_count == 32'd1 &&
            native_address == 12'd1,
            "LACK establishes the first table address");

    advance_to_sample();
    require(sample && !retired && !illegal && pc == 12'd2 &&
            cycle_count == 32'd2 && phase == 2'd0 &&
            native_address == 12'd2 &&
            men_n && den_n && we_n && !program_write,
            "TBLR opcode sample starts discarded-prefetch address setup");
    tick();
    require(phase == 2'd1 && native_address == 12'd2 &&
            !men_n && den_n && we_n,
            "discarded prefetch asserts MEN at the following instruction");

    clock_enable = 1'b0;
    repeat (2) begin
      tick();
      require(phase == 2'd1 && native_address == 12'd2 &&
              !men_n && den_n && we_n && !sample && !retired,
              "stalled discarded prefetch holds address and MEN");
    end
    clock_enable = 1'b1;
    advance_to_sample();
    require(sample && !retired && cycle_count == 32'd3 &&
            phase == 2'd0 && native_address == 12'h020 &&
            men_n && den_n && we_n && data_write &&
            !data_read && data_address == 8'd3 &&
            data_write_data == 16'hbeef,
            "TBLR table address replaces the discarded prefetch");

    tick();
    require(phase == 2'd1 && native_address == 12'h020 &&
            !men_n && den_n && we_n && data_write,
            "TBLR asserts MEN alone for its table read");
    tick();
    require(phase == 2'd2 && !men_n && den_n && we_n,
            "TBLR holds MEN through phase two");
    tick();
    require(phase == 2'd3 && !men_n && den_n && we_n,
            "TBLR holds MEN through its sample boundary");
    tick();
    require(sample && retired && !illegal && pc == 12'd2 &&
            cycle_count == 32'd4 && phase == 2'd0 &&
            native_address == 12'd2 && men_n && den_n && we_n,
            "TBLR retires after exactly three native machine cycles");

    advance_to_sample();
    require(retired && pc == 12'd3 && cycle_count == 32'd5,
            "discarded following LACK is fetched and executed again");
    advance_to_sample();
    require(sample && !retired && pc == 12'd4 &&
            cycle_count == 32'd6 && native_address == 12'd4,
            "TBLW opcode also begins with a discarded prefetch");
    tick();
    require(phase == 2'd1 && !men_n && den_n && we_n &&
            native_address == 12'd4,
            "TBLW discarded prefetch uses MEN");
    advance_to_sample();
    require(sample && !retired && cycle_count == 32'd7 &&
            phase == 2'd0 && native_address == 12'h021 &&
            men_n && den_n && we_n && program_write &&
            program_write_data == 16'hbeef &&
            data_read && !data_write && data_address == 8'd3,
            "TBLW table phase drives ACC address and selected RAM word");

    tick();
    require(phase == 2'd1 && native_address == 12'h021 &&
            men_n && den_n && !we_n && program_write &&
            program_write_data == 16'hbeef,
            "TBLW asserts WE alone after address setup");
    clock_enable = 1'b0;
    repeat (2) begin
      tick();
      require(phase == 2'd1 && native_address == 12'h021 &&
              men_n && den_n && !we_n &&
              program_write_data == 16'hbeef && !retired,
              "stalled TBLW holds address, WE, and write data");
    end
    clock_enable = 1'b1;
    tick();
    require(phase == 2'd2 && men_n && den_n && !we_n,
            "TBLW holds WE through phase two");
    tick();
    require(phase == 2'd3 && men_n && den_n && !we_n,
            "TBLW holds WE through its sample boundary");
    program_memory[33] = program_write_data;
    tick();
    require(sample && retired && !illegal && pc == 12'd4 &&
            cycle_count == 32'd8 && phase == 2'd0 &&
            native_address == 12'd4 && men_n && den_n && we_n &&
            program_memory[33] == 16'hbeef,
            "TBLW retires after three cycles and repeated fetch resumes");

    tick();
    require(phase == 2'd1 && native_address == 12'd4 &&
            !men_n && den_n && we_n,
            "normal MEN fetch repeats the discarded following address");

    $display("PASS tb_table_transfer_phase");
    $finish;
  end
endmodule

`default_nettype wire
