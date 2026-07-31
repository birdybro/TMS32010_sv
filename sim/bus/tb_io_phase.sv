`default_nettype none

module tb_io_phase;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic [15:0] program_data;
  logic [15:0] io_read_data;
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
  logic        data_address_valid;
  logic [15:0] data_read_data;
  logic [15:0] data_write_data;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic [15:0] io_write_data;
  logic [11:0] pc;
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
    .bio_i                         (1'b1),
    .program_data_i                (program_data),
    .io_read_data_i                (io_read_data),
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
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (data_read_data),
    .data_write_data_o             (data_write_data),
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (io_write_data),
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
    .instruction_valid_o           (instruction_valid),
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
    program_memory[0] = 16'h4203;  // IN 3,PA2
    program_memory[1] = 16'h4f03;  // OUT 3,PA7
    program_memory[2] = 16'h7f80;  // NOP

    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    io_read_data = 16'h1111;
    tick();
    initialize = 1'b0;
    repeat (20) begin
      tick();
      require(!bus_active && men_n && den_n && we_n,
              "reset keeps every native strobe inactive");
    end

    rs = 1'b0;
    advance_to_sample();
    require(sample && instruction_valid && !retired && !illegal &&
            pc == 12'h001 &&
            cycle_count == 32'd1,
            "IN opcode sample starts its second machine cycle");
    require(phase == 2'd0 && native_address == 12'h002 &&
            men_n && den_n && we_n,
            "I/O address replaces the prefetched PC during phase zero");
    require(io_read && !io_write && io_port == 3'd2 &&
            data_write && !data_read && data_address == 8'd3 &&
            data_address_valid && data_write_data == 16'h1111,
            "logical IN transfer is visible throughout its port cycle");

    tick();
    require(phase == 2'd1 && native_address == 12'h002 &&
            men_n && !den_n && we_n,
            "IN asserts DEN alone after address setup");
    require(io_read && data_write && data_write_data == 16'h1111,
            "IN port and RAM side remain active in phase one");

    clock_enable = 1'b0;
    io_read_data = 16'hbeef;
    repeat (3) begin
      tick();
      require(phase == 2'd1 && native_address == 12'h002 &&
              men_n && !den_n && we_n && !sample && !retired,
              "stalled IN holds address, DEN, and phase");
      require(data_write_data == 16'hbeef,
              "stalled IN retains a live external data input");
    end
    clock_enable = 1'b1;

    tick();
    require(phase == 2'd2 && men_n && !den_n && we_n,
            "IN holds DEN through phase two");
    tick();
    require(phase == 2'd3 && men_n && !den_n && we_n,
            "IN holds DEN through the falling-boundary setup phase");
    tick();
    require(sample && retired && !illegal && phase == 2'd0 &&
            pc == 12'h001 && native_address == 12'h001 &&
            cycle_count == 32'd2 && men_n && den_n && we_n,
            "IN samples data and returns to next program address");

    advance_to_sample();
    require(sample && instruction_valid && !retired && !illegal &&
            phase == 2'd0 &&
            pc == 12'h002 && native_address == 12'h007 &&
            cycle_count == 32'd3 && men_n && den_n && we_n,
            "OUT opcode sample starts port-address setup");
    require(!io_read && io_write && io_port == 3'd7 &&
            data_read && !data_write && data_address == 8'd3 &&
            data_address_valid && data_read_data == 16'hbeef &&
            io_write_data == 16'hbeef,
            "OUT reads internal RAM and presents the complete word");

    tick();
    require(phase == 2'd1 && native_address == 12'h007 &&
            men_n && den_n && !we_n,
            "OUT asserts WE alone after address setup");
    require(io_write && io_write_data == 16'hbeef,
            "OUT data stays driven in its active write phase");

    clock_enable = 1'b0;
    repeat (2) begin
      tick();
      require(phase == 2'd1 && native_address == 12'h007 &&
              men_n && den_n && !we_n && !sample && !retired,
              "stalled OUT holds address, WE, and phase");
      require(io_write && io_write_data == 16'hbeef,
              "stalled OUT holds its write data");
    end
    clock_enable = 1'b1;

    tick();
    require(phase == 2'd2 && men_n && den_n && !we_n &&
            io_write_data == 16'hbeef,
            "OUT holds WE and write data through phase two");
    tick();
    require(phase == 2'd3 && men_n && den_n && !we_n &&
            io_write_data == 16'hbeef,
            "OUT holds WE and write data through its sample boundary");
    tick();
    require(sample && retired && !illegal && phase == 2'd0 &&
            pc == 12'h002 && native_address == 12'h002 &&
            cycle_count == 32'd4 && men_n && den_n && we_n,
            "OUT retires after exactly two machine cycles");

    tick();
    require(phase == 2'd1 && !men_n && den_n && we_n &&
            native_address == 12'h002,
            "normal MEN fetch resumes on the following phase");

    $display("PASS tb_io_phase");
    $finish;
  end
endmodule

`default_nettype wire
