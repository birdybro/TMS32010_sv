`default_nettype none

// TIMING-002 verifies the portable synchronous phase-pause adaptation. The
// original TMS32010 has no READY input; clock_enable is not a native pin.
module tb_wait_states;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic [15:0] program_data;
  logic [15:0] io_read_data;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic [1:0]  phase;
  logic        clkout;
  logic [11:0] program_address;
  logic        men_n;
  logic        den_n;
  logic        we_n;
  logic        program_write;
  logic [15:0] program_write_data;
  logic        sample;
  logic        bus_active;
  logic        execute_valid;
  logic [11:0] execute_address;
  logic [15:0] execute_word;
  logic        pipeline_blocked;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [7:0]  data_write_address;
  logic        data_write_address_valid;
  logic [15:0] data_read_data;
  logic [15:0] data_write_data;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic [15:0] io_write_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] t_register;
  logic [31:0] product_register;
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
  logic        data_page_pointer;
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        overflow_flag;
  logic        overflow_mode;
  logic        interrupt_mask;
  logic        interrupt_pending;
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_sequential_pipeline_slice dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .rs_i                          (rs),
    .clock_enable_i                (clock_enable),
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
    .program_data_i                (program_data),
    .io_read_data_i                (io_read_data),
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .program_address_o             (program_address),
    .men_n_o                       (men_n),
    .den_n_o                       (den_n),
    .we_n_o                        (we_n),
    .program_write_o               (program_write),
    .program_write_data_o          (program_write_data),
    .sample_o                      (sample),
    .bus_active_o                  (bus_active),
    .execute_valid_o               (execute_valid),
    .execute_address_o             (execute_address),
    .execute_word_o                (execute_word),
    .pipeline_blocked_o            (pipeline_blocked),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (data_write_address),
    .data_write_address_valid_o    (data_write_address_valid),
    .data_read_data_o              (data_read_data),
    .data_write_data_o             (data_write_data),
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (io_write_data),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (t_register),
    .product_register_o            (product_register),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (data_page_pointer),
    .stack_top_o                    (stack_top),
    .stack_level_1_o               (stack_level_1),
    .stack_level_2_o               (stack_level_2),
    .stack_bottom_o                (stack_bottom),
    .overflow_flag_o               (overflow_flag),
    .overflow_mode_o               (overflow_mode),
    .interrupt_mask_o              (interrupt_mask),
    .interrupt_pending_o           (interrupt_pending),
    .instruction_valid_o           (instruction_valid),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
  );

  assign program_data = program_memory[program_address];

  initial clk = 1'b0;
  always #5 clk = ~clk;

  always_ff @(posedge clk) begin
    if (
      !initialize &&
      !rs &&
      clock_enable &&
      bus_active &&
      (phase == 2'd3) &&
      program_write
    ) begin
      program_memory[program_address] <= program_write_data;
    end
  end

  task automatic tick;
    @(posedge clk);
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  task automatic require_exclusive_strobes(input string name);
    require(clkout == phase[1], {name, " CLKOUT follows held phase"});
    require(
      !(
        (!men_n && !den_n) ||
        (!men_n && !we_n) ||
        (!den_n && !we_n)
      ),
      {name, " MEN, DEN, and WE remain mutually exclusive"}
    );
  endtask

  task automatic hold_current_phase(
    input int unsigned hold_clocks,
    input string       name,
    inout int unsigned host_ticks
  );
    logic [1:0]   held_phase;
    logic [11:0]  held_program_address;
    logic [15:0]  held_program_write_data;
    logic [15:0]  held_io_write_data;
    logic [11:0]  held_execute_address;
    logic [15:0]  held_execute_word;
    logic [7:0]   held_data_address;
    logic [7:0]   held_data_write_address;
    logic [15:0]  held_data_read_data;
    logic [15:0]  held_data_write_data;
    logic [11:0]  held_pc;
    logic [31:0]  held_accumulator;
    logic [15:0]  held_t_register;
    logic [31:0]  held_product_register;
    logic [15:0]  held_ar0;
    logic [15:0]  held_ar1;
    logic [11:0]  held_stack_top;
    logic [11:0]  held_stack_level_1;
    logic [11:0]  held_stack_level_2;
    logic [11:0]  held_stack_bottom;
    logic [15:0]  held_ram [0:143];
    logic [15:0]  held_program20;
    logic [31:0]  held_cycle_count;
    logic [24:0]  held_control;
    begin
      held_phase              = phase;
      held_program_address    = program_address;
      held_program_write_data = program_write_data;
      held_io_write_data      = io_write_data;
      held_execute_address    = execute_address;
      held_execute_word       = execute_word;
      held_data_address       = data_address;
      held_data_write_address = data_write_address;
      held_data_read_data     = data_read_data;
      held_data_write_data    = data_write_data;
      held_pc                 = pc;
      held_accumulator        = accumulator;
      held_t_register         = t_register;
      held_product_register   = product_register;
      held_ar0                = auxiliary_register_0;
      held_ar1                = auxiliary_register_1;
      held_stack_top          = stack_top;
      held_stack_level_1      = stack_level_1;
      held_stack_level_2      = stack_level_2;
      held_stack_bottom       = stack_bottom;
      for (int unsigned index = 0; index < 144; index++) begin
        held_ram[index] = dut.core.data_ram.memory[index];
      end
      held_program20          = program_memory[12'h020];
      held_cycle_count        = cycle_count;
      held_control = {
        clkout,
        men_n,
        den_n,
        we_n,
        program_write,
        bus_active,
        execute_valid,
        pipeline_blocked,
        data_read,
        data_write,
        data_address_valid,
        data_write_address_valid,
        io_read,
        io_write,
        io_port,
        auxiliary_register_pointer,
        data_page_pointer,
        overflow_flag,
        overflow_mode,
        interrupt_mask,
        interrupt_pending,
        instruction_valid,
        illegal
      };

      clock_enable = 1'b0;
      repeat (hold_clocks) begin
        tick();
        host_ticks++;
        require_exclusive_strobes(name);
        require(
          phase == held_phase &&
          program_address == held_program_address &&
          program_write_data == held_program_write_data &&
          io_write_data == held_io_write_data &&
          execute_address == held_execute_address &&
          execute_word == held_execute_word &&
          data_address == held_data_address &&
          data_write_address == held_data_write_address &&
          data_read_data == held_data_read_data &&
          data_write_data == held_data_write_data &&
          pc == held_pc &&
          accumulator == held_accumulator &&
          t_register == held_t_register &&
          product_register == held_product_register &&
          auxiliary_register_0 == held_ar0 &&
          auxiliary_register_1 == held_ar1 &&
          stack_top == held_stack_top &&
          stack_level_1 == held_stack_level_1 &&
          stack_level_2 == held_stack_level_2 &&
          stack_bottom == held_stack_bottom &&
          cycle_count == held_cycle_count &&
          {
            clkout,
            men_n,
            den_n,
            we_n,
            program_write,
            bus_active,
            execute_valid,
            pipeline_blocked,
            data_read,
            data_write,
            data_address_valid,
            data_write_address_valid,
            io_read,
            io_write,
            io_port,
            auxiliary_register_pointer,
            data_page_pointer,
            overflow_flag,
            overflow_mode,
            interrupt_mask,
            interrupt_pending,
            instruction_valid,
            illegal
          } == held_control,
          {name, " holds all native outputs and architectural state"}
        );
        for (int unsigned index = 0; index < 144; index++) begin
          require(
            dut.core.data_ram.memory[index] == held_ram[index],
            {name, " cannot mutate internal RAM while paused"}
          );
        end
        require(
          program_memory[12'h020] == held_program20,
          {name, " cannot complete a program write while paused"}
        );
        require(!sample && !retired,
                {name, " cannot sample or retire while paused"});
      end
      clock_enable = 1'b1;
    end
  endtask

  task automatic seed_case;
    begin
      for (int unsigned index = 0; index < 4096; index++) begin
        program_memory[index] = 16'h7f80;
      end
      program_memory[12'h000] = 16'h7e20;  // LACK 0x20
      program_memory[12'h001] = 16'h4100;  // IN 0,PA1
      program_memory[12'h002] = 16'h4a00;  // OUT 0,PA2
      program_memory[12'h003] = 16'h6701;  // TBLR 1
      program_memory[12'h004] = 16'h7d02;  // TBLW 2
      program_memory[12'h005] = 16'h7f80;  // NOP
      program_memory[12'h020] = 16'h1234;  // TBLR source

      initialize         = 1'b1;
      rs                 = 1'b1;
      clock_enable       = 1'b1;
      io_read_data       = 16'ha55a;
      debug_data_write   = 1'b1;
      debug_data_address = 8'h00;
      debug_data         = 16'hcafe;
      tick();
      debug_data_address = 8'h01;
      debug_data         = 16'h0000;
      tick();
      debug_data_address = 8'h02;
      debug_data         = 16'hbeef;
      tick();
      debug_data_write = 1'b0;
      initialize       = 1'b0;

      repeat (20) begin
        tick();
        require(!bus_active && men_n && den_n && we_n,
                "reset keeps every native strobe inactive");
      end
      rs = 1'b0;
    end
  endtask

  task automatic run_case(
    input  logic        enable_holds,
    output int unsigned host_ticks,
    output logic [11:0] final_pc,
    output logic [31:0] final_accumulator,
    output logic [15:0] final_ram0,
    output logic [15:0] final_ram1,
    output logic [15:0] final_program20
  );
    logic held_program;
    logic held_in;
    logic held_out;
    logic held_tblr;
    logic held_tblw;
    logic saw_out;
    begin
      seed_case();
      host_ticks  = 0;
      held_program = 1'b0;
      held_in      = 1'b0;
      held_out     = 1'b0;
      held_tblr    = 1'b0;
      held_tblw    = 1'b0;
      saw_out      = 1'b0;

      while (!(
        cycle_count == 32'd11 &&
        execute_valid &&
        execute_address == 12'h005
      )) begin
        if (enable_holds) begin
          if (
            !held_program &&
            bus_active &&
            !execute_valid &&
            program_address == 12'h000 &&
            phase == 2'd1 &&
            !men_n
          ) begin
            held_program = 1'b1;
            hold_current_phase(2, "ordinary MEN pause", host_ticks);
          end else if (
            !held_in &&
            execute_word == 16'h4100 &&
            io_read &&
            phase == 2'd1 &&
            !den_n
          ) begin
            held_in = 1'b1;
            hold_current_phase(3, "IN DEN pause", host_ticks);
          end else if (
            !held_out &&
            execute_word == 16'h4a00 &&
            io_write &&
            phase == 2'd1 &&
            !we_n
          ) begin
            held_out = 1'b1;
            require(io_write_data == 16'ha55a,
                    "OUT observes the completed IN value");
            hold_current_phase(4, "OUT WE pause", host_ticks);
          end else if (
            !held_tblr &&
            execute_word == 16'h6701 &&
            program_address == 12'h020 &&
            phase == 2'd1 &&
            !men_n &&
            !program_write
          ) begin
            held_tblr = 1'b1;
            hold_current_phase(2, "TBLR MEN pause", host_ticks);
          end else if (
            !held_tblw &&
            execute_word == 16'h7d02 &&
            program_address == 12'h020 &&
            phase == 2'd1 &&
            program_write &&
            !we_n
          ) begin
            held_tblw = 1'b1;
            require(program_write_data == 16'hbeef,
                    "TBLW presents the selected RAM word");
            hold_current_phase(5, "TBLW WE pause", host_ticks);
          end
        end

        tick();
        host_ticks++;
        require_exclusive_strobes("running phase stream");
        require(!illegal && !pipeline_blocked,
                "synthetic wait-state stream stays supported");
        if (io_write && !we_n) begin
          require(io_port == 3'd2 && io_write_data == 16'ha55a,
                  "OUT holds the expected port and data");
          saw_out = 1'b1;
        end
        if (host_ticks > 256) begin
          $fatal(1, "phase stream failed to resume within its finite bound");
        end
      end

      require(saw_out, "zero/multiple-pause runs both complete OUT");
      if (enable_holds) begin
        require(
          held_program && held_in && held_out && held_tblr && held_tblw,
          "every external transaction class received a multi-clock pause"
        );
      end
      require(retired, "NOP retirement terminates the stream");
      require(execute_word == 16'h7f80, "terminal execute word is NOP");
      require(pc == 12'h005, "terminal architectural PC is NOP address");
      require(
        accumulator == 32'h0000_0020,
        "LACK accumulator result survives the bus sequence"
      );
      require(
        dut.core.data_ram.memory[0] == 16'ha55a,
        "IN stores the sampled I/O word in RAM 0"
      );
      require(
        dut.core.data_ram.memory[1] == 16'h1234,
        "TBLR stores the program word in RAM 1"
      );
      require(
        program_memory[12'h020] == 16'hbeef,
        "TBLW stores RAM 2 into program memory"
      );

      final_pc          = pc;
      final_accumulator = accumulator;
      final_ram0        = dut.core.data_ram.memory[0];
      final_ram1        = dut.core.data_ram.memory[1];
      final_program20   = program_memory[12'h020];
    end
  endtask

  initial begin
    int unsigned baseline_ticks;
    int unsigned paused_ticks;
    logic [11:0] baseline_pc;
    logic [11:0] paused_pc;
    logic [31:0] baseline_accumulator;
    logic [31:0] paused_accumulator;
    logic [15:0] baseline_ram0;
    logic [15:0] paused_ram0;
    logic [15:0] baseline_ram1;
    logic [15:0] paused_ram1;
    logic [15:0] baseline_program20;
    logic [15:0] paused_program20;

    run_case(
      1'b0,
      baseline_ticks,
      baseline_pc,
      baseline_accumulator,
      baseline_ram0,
      baseline_ram1,
      baseline_program20
    );
    run_case(
      1'b1,
      paused_ticks,
      paused_pc,
      paused_accumulator,
      paused_ram0,
      paused_ram1,
      paused_program20
    );

    require(paused_ticks == baseline_ticks + 16,
            "only the sixteen requested FPGA pause clocks extend execution");
    require(
      {
        paused_pc,
        paused_accumulator,
        paused_ram0,
        paused_ram1,
        paused_program20
      } == {
        baseline_pc,
        baseline_accumulator,
        baseline_ram0,
        baseline_ram1,
        baseline_program20
      },
      "zero-pause and multiple-pause executions are architecturally equal"
    );
    require(
      paused_ram0 == 16'ha55a &&
      paused_ram1 == 16'h1234 &&
      paused_program20 == 16'hbeef,
      "IN, TBLR, and TBLW final data agree after pause adaptation"
    );

    $display("PASS tb_wait_states");
    $finish;
  end
endmodule

`default_nettype wire
