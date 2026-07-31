`default_nettype none

module tb_mister_wrapper;
  logic        clk;
  logic        reset;
  logic        clock_enable;
  logic        program_read;
  logic        program_write;
  logic [11:0] program_address;
  logic [15:0] program_write_data;
  logic [15:0] program_read_data;
  logic        program_ready;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic [15:0] io_write_data;
  logic [15:0] io_read_data;
  logic        io_ready;
  logic        reset_active;
  logic        memory_wait;
  logic        phase_advance;
  logic [1:0]  phase;
  logic        clkout;
  logic        men_n;
  logic        den_n;
  logic        we_n;
  logic        sample;
  logic        bus_active;
  logic        execute_valid;
  logic [11:0] execute_address;
  logic [15:0] execute_word;
  logic        pipeline_blocked;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;

  logic [15:0] program_memory [0:4095];
  logic        program_pending;
  logic [11:0] pending_program_address;
  logic [2:0]  program_delay;
  logic        io_pending;
  logic [2:0]  pending_io_port;
  logic [2:0]  io_delay;
  integer      program_request_count;
  integer      program_write_count;
  integer      io_read_count;
  integer      io_write_count;
  logic [11:0] committed_program_address;
  logic [15:0] committed_program_data;
  logic [2:0]  committed_io_port;
  logic [15:0] committed_io_data;

  tms32010_mister dut (
    .clk_i                         (clk),
    .reset_i                       (reset),
    .clock_enable_i                (clock_enable),
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
    .program_address_o             (program_address),
    .program_read_o                (program_read),
    .program_write_o               (program_write),
    .program_write_data_o          (program_write_data),
    .program_read_data_i           (program_read_data),
    .program_ready_i               (program_ready),
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (io_write_data),
    .io_read_data_i                (io_read_data),
    .io_ready_i                    (io_ready),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
    .debug_data_address_o          (),
    .debug_data_read_o             (),
    .debug_data_write_o            (),
    .debug_data_address_valid_o    (),
    .debug_data_write_address_o    (),
    .debug_data_read_data_o        (),
    .debug_data_write_data_o       (),
    .reset_active_o                (reset_active),
    .memory_wait_o                 (memory_wait),
    .phase_advance_o               (phase_advance),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .native_men_n_o                (men_n),
    .native_den_n_o                (den_n),
    .native_we_n_o                 (we_n),
    .native_sample_o               (sample),
    .native_bus_active_o           (bus_active),
    .execute_valid_o               (execute_valid),
    .execute_address_o             (execute_address),
    .execute_word_o                (execute_word),
    .pipeline_blocked_o            (pipeline_blocked),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
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
    .interrupt_pending_o           (),
    .instruction_valid_o           (),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
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

  // Registered program response. Address zero is intentionally delayed long
  // enough to exercise the wrapper's registered phase-3 hold.
  always_ff @(posedge clk) begin
    if (reset) begin
      program_pending         <= 1'b0;
      pending_program_address <= 12'h000;
      program_delay           <= 3'd0;
      program_read_data       <= 16'h0000;
      program_ready           <= 1'b0;
      program_request_count   <= 0;
      program_write_count     <= 0;
      committed_program_address <= 12'h000;
      committed_program_data    <= 16'h0000;
    end else begin
      if (!(program_read || program_write)) begin
        program_pending <= 1'b0;
        program_ready   <= 1'b0;
      end else if (!program_pending) begin
        program_pending         <= 1'b1;
        pending_program_address <= program_address;
        program_delay           <=
          (program_address == 12'h000) ? 3'd4 : 3'd1;
        program_ready <= 1'b0;
        program_request_count <= program_request_count + 1;
      end else if (!program_ready) begin
        if (program_delay == 3'd0) begin
          program_read_data <= program_memory[pending_program_address];
          program_ready     <= 1'b1;
        end else begin
          program_delay <= program_delay - 3'd1;
        end
      end

      if (
        phase_advance &&
        (phase == 2'd3) &&
        program_ready &&
        program_write
      ) begin
        program_memory[program_address] <= program_write_data;
        program_write_count <= program_write_count + 1;
        committed_program_address <= program_address;
        committed_program_data <= program_write_data;
      end
    end
  end

  // Registered I/O response. Writes are committed exactly at the enabled
  // phase-3 transfer boundary, not once per host clock while request is held.
  always_ff @(posedge clk) begin
    if (reset) begin
      io_pending           <= 1'b0;
      pending_io_port      <= 3'd0;
      io_delay             <= 3'd0;
      io_read_data         <= 16'h0000;
      io_ready             <= 1'b0;
      io_read_count        <= 0;
      io_write_count       <= 0;
      committed_io_port    <= 3'd0;
      committed_io_data    <= 16'h0000;
    end else begin
      if (!(io_read || io_write)) begin
        io_pending <= 1'b0;
        io_ready   <= 1'b0;
      end else if (!io_pending) begin
        io_pending       <= 1'b1;
        pending_io_port  <= io_port;
        io_delay         <= 3'd2;
        io_ready         <= 1'b0;
      end else if (!io_ready) begin
        if (io_delay == 3'd0) begin
          io_read_data <=
            (pending_io_port == 3'd4) ? 16'h1234 : 16'h0000;
          io_ready <= 1'b1;
        end else begin
          io_delay <= io_delay - 3'd1;
        end
      end

      if (phase_advance && (phase == 2'd3) && io_ready) begin
        if (io_read) begin
          io_read_count <= io_read_count + 1;
        end
        if (io_write) begin
          io_write_count    <= io_write_count + 1;
          committed_io_port <= io_port;
          committed_io_data <= io_write_data;
        end
      end
    end
  end

  initial begin
    int unsigned reset_falling_boundaries;
    int unsigned retired_count;
    int unsigned wait_clocks;
    logic       previous_clkout;
    logic       previous_reset_active;
    logic       tested_global_pause;
    logic [1:0] held_phase;
    logic [11:0] held_address;

    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7e2a;  // LACK 0x2a
    program_memory[1] = 16'h5001;  // SACL 1
    program_memory[2] = 16'h4b01;  // OUT 1,PA3
    program_memory[3] = 16'h4402;  // IN 2,PA4
    program_memory[4] = 16'h2002;  // LAC 2
    program_memory[5] = 16'h7d01;  // TBLW 1 -> program[ACC[11:0]]
    program_memory[6] = 16'h7f80;  // NOP after repeated prefetch
    program_memory[7] = 16'h7f83;  // unsupported: must park

    reset        = 1'b1;
    clock_enable = 1'b1;
    tick();
    require(reset_active, "standard reset starts the stretched RS interval");
    require(!bus_active && men_n && den_n && we_n,
            "standard reset leaves every native strobe inactive");
    reset = 1'b0;

    reset_falling_boundaries = 0;
    for (int unsigned elapsed = 0; elapsed < 32; elapsed++) begin
      previous_clkout      = clkout;
      previous_reset_active = reset_active;
      tick();
      if (previous_reset_active && previous_clkout && !clkout) begin
        reset_falling_boundaries++;
      end
      require(!(program_read || program_write || io_read || io_write),
              "stretched reset suppresses every callback request");
      if (!reset_active) begin
        break;
      end
    end
    require(reset_falling_boundaries == 5,
            "wrapper holds modeled RS for exactly five machine cycles");

    retired_count      = 0;
    wait_clocks        = 0;
    tested_global_pause = 1'b0;
    for (int unsigned elapsed = 0; elapsed < 600; elapsed++) begin
      require(!(program_read && program_write),
              "program callbacks remain mutually exclusive");
      require(!(io_read && io_write),
              "I/O callbacks remain mutually exclusive");
      require(!((program_read || program_write) && (io_read || io_write)),
              "program and I/O callbacks never overlap");

      if (!tested_global_pause && program_read && (phase == 2'd1)) begin
        held_phase   = phase;
        held_address = program_address;
        clock_enable = 1'b0;
        repeat (3) begin
          tick();
          require(phase == held_phase && program_address == held_address,
                  "global clock enable holds phase and program address");
          require(!sample && !retired,
                  "global pause cannot sample or retire");
        end
        clock_enable       = 1'b1;
        tested_global_pause = 1'b1;
      end

      tick();
      require(clkout == phase[1], "CLKOUT follows the native phase encoding");
      if (memory_wait) begin
        wait_clocks++;
        require(phase == 2'd3 && !phase_advance,
                "late callback response holds only phase 3");
      end
      if (retired) begin
        retired_count++;
      end
      if (retired_count == 7) begin
        break;
      end
    end

    require(tested_global_pause, "test reached a callback launch phase");
    require(wait_clocks >= 4, "registered callbacks exercised phase-3 waits");
    require(program_request_count >= 10,
            "program callback serviced priming and execution fetches");
    require(program_write_count == 1 &&
            committed_program_address == 12'h234 &&
            committed_program_data == 16'h002a &&
            program_memory[12'h234] == 16'h002a,
            "TBLW committed exactly one program-memory write");
    require(io_write_count == 1 && committed_io_port == 3'd3,
            "OUT committed exactly once to port three");
    require(committed_io_data == 16'h002a,
            "OUT callback received the internal RAM value");
    require(io_read_count == 1,
            "IN sampled exactly one completed callback response");
    require(accumulator == 32'h0000_1234,
            "IN result returned through RAM and LAC into ACC");
    require(pc == 12'h007 && cycle_count == 32'd11,
            "seven instructions consumed documented 1/1/2/2/1/3/1 cycles");
    require(execute_valid && execute_address == 12'h007 &&
            execute_word == 16'h7f83 && pipeline_blocked && !illegal,
            "unsupported following word parks without invented behavior");

    reset = 1'b1;
    tick();
    require(reset_active && !pipeline_blocked && !execute_valid &&
            !bus_active && pc == 12'h000 && cycle_count == 32'd0,
            "standard reset recovers a callback-fed parked pipeline");

    $display("PASS tb_mister_wrapper");
    $finish;
  end
endmodule

`default_nettype wire
