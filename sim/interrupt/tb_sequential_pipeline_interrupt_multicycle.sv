`default_nettype none

module tb_sequential_pipeline_interrupt_multicycle;
  localparam int unsigned FAMILY_B     = 0;
  localparam int unsigned FAMILY_BANZ  = 1;
  localparam int unsigned FAMILY_BV    = 2;
  localparam int unsigned FAMILY_BIOZ  = 3;
  localparam int unsigned FAMILY_CALL  = 4;
  localparam int unsigned FAMILY_BGEZ  = 5;
  localparam int unsigned FAMILY_BGZ   = 6;
  localparam int unsigned FAMILY_BLEZ  = 7;
  localparam int unsigned FAMILY_BLZ   = 8;
  localparam int unsigned FAMILY_BNZ   = 9;
  localparam int unsigned FAMILY_BZ    = 10;
  localparam int unsigned FAMILY_IN    = 11;
  localparam int unsigned FAMILY_OUT   = 12;
  localparam int unsigned FAMILY_TBLR  = 13;
  localparam int unsigned FAMILY_TBLW  = 14;
  localparam int unsigned FAMILY_COUNT = 15;

  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic        int_n;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic [15:0] program_data;
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
  logic [15:0] auxiliary_register_0;
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        interrupt_mask;
  logic        interrupt_pending;
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
    .int_i                         (int_n),
    .program_data_i                (program_data),
    .io_read_data_i                (16'hcafe),
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
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (interrupt_mask),
    .interrupt_pending_o           (interrupt_pending),
    .instruction_valid_o           (),
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

  function automatic logic [15:0] family_opcode(
    input int unsigned family
  );
    case (family)
      FAMILY_B:    family_opcode = 16'hf900;
      FAMILY_BANZ: family_opcode = 16'hf400;
      FAMILY_BV:   family_opcode = 16'hf500;
      FAMILY_BIOZ: family_opcode = 16'hf600;
      FAMILY_CALL: family_opcode = 16'hf800;
      FAMILY_BGEZ: family_opcode = 16'hfd00;
      FAMILY_BGZ:  family_opcode = 16'hfc00;
      FAMILY_BLEZ: family_opcode = 16'hfb00;
      FAMILY_BLZ:  family_opcode = 16'hfa00;
      FAMILY_BNZ:  family_opcode = 16'hfe00;
      FAMILY_BZ:   family_opcode = 16'hff00;
      FAMILY_IN:   family_opcode = 16'h4203;
      FAMILY_OUT:  family_opcode = 16'h4f03;
      FAMILY_TBLR: family_opcode = 16'h6700;
      FAMILY_TBLW: family_opcode = 16'h7d00;
      default:     family_opcode = 16'h0000;
    endcase
  endfunction

  function automatic int unsigned family_cycles(
    input int unsigned family
  );
    if ((family == FAMILY_TBLR) || (family == FAMILY_TBLW)) begin
      family_cycles = 3;
    end else begin
      family_cycles = 2;
    end
  endfunction

  function automatic logic family_is_control(
    input int unsigned family
  );
    family_is_control = family <= FAMILY_BZ;
  endfunction

  function automatic logic family_is_taken(
    input int unsigned family
  );
    case (family)
      FAMILY_B,
      FAMILY_CALL,
      FAMILY_BGEZ,
      FAMILY_BLEZ,
      FAMILY_BZ: family_is_taken = 1'b1;
      default:   family_is_taken = 1'b0;
    endcase
  endfunction

  task automatic tick;
    @(posedge clk);
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  task automatic require_exclusive_strobes(
    input int unsigned family,
    input int unsigned arrival_interval,
    input int unsigned arrival_phase,
    input string interval_name
  );
    require(
      clkout == phase[1],
      $sformatf(
        "family %0d arrival interval %0d phase %0d %s CLKOUT follows phase",
        family,
        arrival_interval,
        arrival_phase,
        interval_name
      )
    );
    require(
      !(
        (!men_n && !den_n) ||
        (!men_n && !we_n) ||
        (!den_n && !we_n)
      ),
      $sformatf(
        "family %0d arrival interval %0d phase %0d %s strobes are exclusive",
        family,
        arrival_interval,
        arrival_phase,
        interval_name
      )
    );
  endtask

  task automatic advance_to_sample(
    input int unsigned family,
    input int unsigned arrival_interval,
    input int unsigned arrival_phase,
    input string interval_name
  );
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require_exclusive_strobes(
        family,
        arrival_interval,
        arrival_phase,
        interval_name
      );
      if (sample) begin
        return;
      end
    end
    $fatal(
      1,
      "family %0d arrival interval %0d phase %0d %s sample did not arrive",
      family,
      arrival_interval,
      arrival_phase,
      interval_name
    );
  endtask

  task automatic pause_at_arrival(
    input int unsigned family,
    input int unsigned arrival_interval,
    input int unsigned arrival_phase
  );
    logic [1:0]  saved_phase;
    logic [11:0] saved_program_address;
    logic        saved_men_n;
    logic        saved_den_n;
    logic        saved_we_n;
    logic        saved_program_write;
    logic [15:0] saved_program_write_data;
    logic        saved_bus_active;
    logic        saved_execute_valid;
    logic [11:0] saved_execute_address;
    logic [15:0] saved_execute_word;
    logic        saved_pipeline_blocked;
    logic [7:0]  saved_data_address;
    logic        saved_data_read;
    logic        saved_data_write;
    logic        saved_data_address_valid;
    logic [7:0]  saved_data_write_address;
    logic        saved_data_write_address_valid;
    logic [15:0] saved_data_read_data;
    logic [15:0] saved_data_write_data;
    logic [2:0]  saved_io_port;
    logic        saved_io_read;
    logic        saved_io_write;
    logic [15:0] saved_io_write_data;
    logic [11:0] saved_pc;
    logic [31:0] saved_accumulator;
    logic [15:0] saved_auxiliary_register_0;
    logic [11:0] saved_stack_top;
    logic [11:0] saved_stack_level_1;
    logic [11:0] saved_stack_level_2;
    logic [11:0] saved_stack_bottom;
    logic        saved_interrupt_mask;
    logic        saved_interrupt_pending;
    logic [31:0] saved_cycle_count;

    saved_phase                    = phase;
    saved_program_address          = program_address;
    saved_men_n                    = men_n;
    saved_den_n                    = den_n;
    saved_we_n                     = we_n;
    saved_program_write            = program_write;
    saved_program_write_data       = program_write_data;
    saved_bus_active               = bus_active;
    saved_execute_valid            = execute_valid;
    saved_execute_address          = execute_address;
    saved_execute_word             = execute_word;
    saved_pipeline_blocked         = pipeline_blocked;
    saved_data_address             = data_address;
    saved_data_read                = data_read;
    saved_data_write               = data_write;
    saved_data_address_valid       = data_address_valid;
    saved_data_write_address       = data_write_address;
    saved_data_write_address_valid = data_write_address_valid;
    saved_data_read_data           = data_read_data;
    saved_data_write_data          = data_write_data;
    saved_io_port                  = io_port;
    saved_io_read                  = io_read;
    saved_io_write                 = io_write;
    saved_io_write_data            = io_write_data;
    saved_pc                       = pc;
    saved_accumulator              = accumulator;
    saved_auxiliary_register_0     = auxiliary_register_0;
    saved_stack_top                = stack_top;
    saved_stack_level_1            = stack_level_1;
    saved_stack_level_2            = stack_level_2;
    saved_stack_bottom             = stack_bottom;
    saved_interrupt_mask           = interrupt_mask;
    saved_interrupt_pending        = interrupt_pending;
    saved_cycle_count              = cycle_count;

    clock_enable = 1'b0;
    tick();
    require(
      phase == saved_phase &&
      program_address == saved_program_address &&
      men_n == saved_men_n && den_n == saved_den_n &&
      we_n == saved_we_n && program_write == saved_program_write &&
      program_write_data == saved_program_write_data &&
      bus_active == saved_bus_active &&
      execute_valid == saved_execute_valid &&
      execute_address == saved_execute_address &&
      execute_word == saved_execute_word &&
      pipeline_blocked == saved_pipeline_blocked &&
      data_address == saved_data_address &&
      data_read == saved_data_read && data_write == saved_data_write &&
      data_address_valid == saved_data_address_valid &&
      data_write_address == saved_data_write_address &&
      data_write_address_valid == saved_data_write_address_valid &&
      data_read_data == saved_data_read_data &&
      data_write_data == saved_data_write_data &&
      io_port == saved_io_port && io_read == saved_io_read &&
      io_write == saved_io_write &&
      io_write_data == saved_io_write_data &&
      pc == saved_pc && accumulator == saved_accumulator &&
      auxiliary_register_0 == saved_auxiliary_register_0 &&
      stack_top == saved_stack_top &&
      stack_level_1 == saved_stack_level_1 &&
      stack_level_2 == saved_stack_level_2 &&
      stack_bottom == saved_stack_bottom &&
      interrupt_mask == saved_interrupt_mask &&
      interrupt_pending == saved_interrupt_pending &&
      cycle_count == saved_cycle_count,
      $sformatf(
        "family %0d arrival interval %0d phase %0d pause holds state and bus",
        family,
        arrival_interval,
        arrival_phase
      )
    );
    clock_enable = 1'b1;
  endtask

  task automatic clear_program;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
  endtask

  task automatic prepare_case(input int unsigned family);
    clear_program();
    program_memory[12'h000] = 16'h7f82;  // EINT
    program_memory[12'h001] = family_opcode(family);
    if (family_is_control(family)) begin
      program_memory[12'h002] = 16'h0010;  // canonical target operand
      program_memory[12'h003] = 16'h7e44;  // untaken protected LACK
      program_memory[12'h004] = 16'h7f89;  // untaken dummy ZAC
      program_memory[12'h010] = 16'h7e44;  // taken protected LACK
      program_memory[12'h011] = 16'h7f89;  // taken dummy ZAC
    end else begin
      program_memory[12'h002] = 16'h7e44;  // protected LACK
      program_memory[12'h003] = 16'h7f89;  // noncontrol dummy ZAC
    end
  endtask

  task automatic initialize_pipeline(
    input int unsigned family,
    input int unsigned arrival_interval,
    input int unsigned arrival_phase
  );
    initialize         = 1'b1;
    rs                 = 1'b1;
    clock_enable       = 1'b1;
    int_n              = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    tick();
    initialize = 1'b0;

    debug_data_write   = 1'b1;
    debug_data_address = 8'h00;
    debug_data         = 16'habcd;
    tick();
    debug_data_address = 8'h03;
    debug_data         = 16'h1234;
    tick();
    debug_data_write = 1'b0;

    repeat (20) begin
      tick();
      require(
        !bus_active && men_n && den_n && we_n && !program_write,
        $sformatf(
          "family %0d arrival interval %0d phase %0d reset keeps native bus inactive",
          family,
          arrival_interval,
          arrival_phase
        )
      );
    end
    rs = 1'b0;
  endtask

  task automatic check_family_interval(
    input int unsigned family,
    input int unsigned interval
  );
    if (family_is_control(family)) begin
      require(
        !men_n && den_n && we_n && !program_write &&
        !io_read && !io_write && !data_read && !data_write,
        $sformatf(
          "family %0d interval %0d is a program-only control read",
          family,
          interval
        )
      );
      require(
        program_address ==
          (
            interval == 0
              ? 12'h002
              : (family_is_taken(family) ? 12'h010 : 12'h003)
          ),
        $sformatf(
          "family %0d interval %0d selects its control address",
          family,
          interval
        )
      );
    end else if ((family == FAMILY_IN) && (interval == 0)) begin
      require(
        men_n && !den_n && we_n && !program_write &&
        io_read && !io_write && io_port == 3'd2 &&
        !data_read && data_write &&
        data_address_valid && data_address == 8'h03 &&
        data_write_address_valid && data_write_address == 8'h03 &&
        data_write_data == 16'hcafe,
        "IN interval 0 has exact DEN and logical RAM-write ownership"
      );
    end else if ((family == FAMILY_OUT) && (interval == 0)) begin
      require(
        men_n && den_n && !we_n && !program_write &&
        !io_read && io_write && io_port == 3'd7 &&
        data_read && !data_write &&
        data_address_valid && data_address == 8'h03 &&
        data_read_data == 16'h1234 && io_write_data == 16'h1234,
        "OUT interval 0 has exact WE and logical RAM-read ownership"
      );
    end else if (
      ((family == FAMILY_IN) || (family == FAMILY_OUT)) &&
      (interval == 1)
    ) begin
      require(
        !men_n && den_n && we_n && !program_write &&
        program_address == 12'h002 &&
        !io_read && !io_write && !data_read && !data_write,
        "I/O interval 1 fetches the protected PC+1 word under MEN"
      );
    end else if (
      ((family == FAMILY_TBLR) || (family == FAMILY_TBLW)) &&
      (interval == 0)
    ) begin
      require(
        !men_n && den_n && we_n && !program_write &&
        program_address == 12'h002 &&
        !io_read && !io_write && !data_read && !data_write,
        "table interval 0 discards PC+1 under MEN"
      );
    end else if ((family == FAMILY_TBLR) && (interval == 1)) begin
      require(
        !men_n && den_n && we_n && !program_write &&
        program_address == 12'h000 &&
        !io_read && !io_write && !data_read && data_write &&
        data_address_valid && data_address == 8'h00 &&
        data_write_address_valid && data_write_address == 8'h00 &&
        data_write_data == 16'h7f82,
        "TBLR interval 1 reads ACC address and presents RAM write"
      );
    end else if ((family == FAMILY_TBLW) && (interval == 1)) begin
      require(
        men_n && den_n && !we_n && program_write &&
        program_address == 12'h000 &&
        program_write_data == 16'habcd &&
        data_read_data == 16'habcd &&
        !io_read && !io_write && data_read && !data_write &&
        data_address_valid && data_address == 8'h00,
        "TBLW interval 1 writes ACC address from selected RAM"
      );
    end else begin
      require(
        ((family == FAMILY_TBLR) || (family == FAMILY_TBLW)) &&
        (interval == 2) &&
        !men_n && den_n && we_n && !program_write &&
        program_address == 12'h002 &&
        !io_read && !io_write && !data_read && !data_write,
        "table interval 2 repeats the protected PC+1 fetch under MEN"
      );
    end
  endtask

  task automatic run_case(
    input int unsigned family,
    input int unsigned arrival_interval,
    input int unsigned arrival_phase
  );
    int unsigned execution_cycles;
    logic [11:0] protected_pc;
    logic [11:0] return_pc;

    execution_cycles = family_cycles(family);
    protected_pc =
      family_is_control(family)
        ? (family_is_taken(family) ? 12'h010 : 12'h003)
        : 12'h002;
    return_pc = protected_pc + 12'h001;

    prepare_case(family);
    initialize_pipeline(family, arrival_interval, arrival_phase);

    advance_to_sample(
      family,
      arrival_interval,
      arrival_phase,
      "EINT prefetch"
    );
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'h7f82 &&
      !retired && cycle_count == 32'd0 &&
      program_address == 12'h001,
      $sformatf(
        "family %0d arrival interval %0d phase %0d first fetch primes EINT",
        family,
        arrival_interval,
        arrival_phase
      )
    );

    advance_to_sample(
      family,
      arrival_interval,
      arrival_phase,
      "EINT execution"
    );
    require(
      retired && !illegal &&
      execute_valid &&
      execute_address == 12'h001 &&
      execute_word == family_opcode(family) &&
      pc == 12'h001 &&
      !interrupt_mask && !interrupt_pending &&
      cycle_count == 32'd1,
      $sformatf(
        "family %0d arrival interval %0d phase %0d EINT captures the family opcode",
        family,
        arrival_interval,
        arrival_phase
      )
    );

    for (
      int unsigned interval = 0;
      interval < execution_cycles;
      interval++
    ) begin
      require(
        phase == 2'd0 &&
        interrupt_pending == (interval > arrival_interval) &&
        !interrupt_mask &&
        cycle_count == (32'd1 + interval),
        $sformatf(
          "family %0d arrival interval %0d phase %0d starts interval %0d without early recognition",
          family,
          arrival_interval,
          arrival_phase,
          interval
        )
      );

      if (
        (interval == arrival_interval) &&
        (arrival_phase == 0)
      ) begin
        int_n = 1'b0;
        pause_at_arrival(family, arrival_interval, arrival_phase);
      end

      for (int unsigned active_phase = 1; active_phase < 4; active_phase++) begin
        tick();
        require(
          phase == active_phase[1:0] &&
          !sample && !retired && !illegal &&
          execute_valid && execute_address == 12'h001 &&
          execute_word == family_opcode(family) &&
          interrupt_pending == (interval > arrival_interval) &&
          !interrupt_mask &&
          cycle_count == (32'd1 + interval),
          $sformatf(
            "family %0d arrival interval %0d phase %0d has no pre-boundary recognition or retirement in interval %0d",
            family,
            arrival_interval,
            arrival_phase,
            interval
          )
        );
        require_exclusive_strobes(
          family,
          arrival_interval,
          arrival_phase,
          $sformatf("family interval %0d", interval)
        );
        check_family_interval(family, interval);

        if (
          (interval == arrival_interval) &&
          (arrival_phase == active_phase)
        ) begin
          int_n = 1'b0;
          pause_at_arrival(family, arrival_interval, arrival_phase);
          require(
            interrupt_pending == (interval > arrival_interval) &&
            cycle_count == (32'd1 + interval),
            $sformatf(
              "family %0d arrival interval %0d phase %0d pause cannot sample INT",
              family,
              arrival_interval,
              arrival_phase
            )
          );
        end
      end

      tick();
      require(
        phase == 2'd0 && sample,
        $sformatf(
          "family %0d arrival interval %0d phase %0d interval %0d reaches sample",
          family,
          arrival_interval,
          arrival_phase,
          interval
        )
      );
      int_n = 1'b1;

      require(
        !illegal &&
        interrupt_pending == (interval >= arrival_interval) &&
        !interrupt_mask &&
        cycle_count == (32'd2 + interval),
        $sformatf(
          "family %0d arrival interval %0d phase %0d interval %0d latches only at its boundary",
          family,
          arrival_interval,
          arrival_phase,
          interval
        )
      );
      if ((interval + 1) < execution_cycles) begin
        require(
          !retired &&
          execute_valid &&
          execute_address == 12'h001 &&
          execute_word == family_opcode(family) &&
          stack_top == 12'h000,
          $sformatf(
            "family %0d arrival interval %0d phase %0d cannot retire or enter midinstruction",
            family,
            arrival_interval,
            arrival_phase
          )
        );
      end else begin
        require(
          retired &&
          execute_valid &&
          execute_address == protected_pc &&
          execute_word == 16'h7e44 &&
          pc == protected_pc &&
          program_address == return_pc &&
          !pipeline_blocked,
          $sformatf(
            "family %0d arrival interval %0d phase %0d completes before service",
            family,
            arrival_interval,
            arrival_phase
          )
        );
      end
    end

    if (family == FAMILY_BANZ) begin
      require(
        auxiliary_register_0 == 16'h01ff,
        "BANZ decrements the old zero counter before service"
      );
    end
    if (family == FAMILY_CALL) begin
      require(
        stack_top == 12'h003 &&
        stack_level_1 == 12'h000 &&
        stack_level_2 == 12'h000 &&
        stack_bottom == 12'h000,
        "CALL pushes its return address before interrupt service"
      );
    end else begin
      require(
        stack_top == 12'h000,
        $sformatf("family %0d has not entered interrupt service", family)
      );
    end

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n && !program_write &&
      program_address == return_pc &&
      execute_address == protected_pc,
      $sformatf(
        "family %0d arrival interval %0d phase %0d protected word overlaps dummy read",
        family,
        arrival_interval,
        arrival_phase
      )
    );
    advance_to_sample(
      family,
      arrival_interval,
      arrival_phase,
      "protected instruction"
    );
    require(
      retired && !illegal &&
      !execute_valid &&
      accumulator == 32'h0000_0044 &&
      pc == return_pc &&
      interrupt_pending && !interrupt_mask &&
      cycle_count == (32'd2 + execution_cycles) &&
      program_address == 12'h002,
      $sformatf(
        "family %0d arrival interval %0d phase %0d retires exactly one protected word",
        family,
        arrival_interval,
        arrival_phase
      )
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n && !program_write &&
      program_address == 12'h002 &&
      !execute_valid,
      $sformatf(
        "family %0d arrival interval %0d phase %0d entry fetches vector in an empty slot",
        family,
        arrival_interval,
        arrival_phase
      )
    );
    advance_to_sample(
      family,
      arrival_interval,
      arrival_phase,
      "vector fetch"
    );
    require(
      !retired && !illegal &&
      execute_valid &&
      execute_address == 12'h002 &&
      execute_word == program_memory[12'h002] &&
      pc == 12'h002 &&
      stack_top == return_pc &&
      !interrupt_pending && interrupt_mask &&
      cycle_count == (32'd3 + execution_cycles),
      $sformatf(
        "family %0d arrival interval %0d phase %0d acknowledges only at vector capture",
        family,
        arrival_interval,
        arrival_phase
      )
    );
    if (family == FAMILY_CALL) begin
      require(
        stack_level_1 == 12'h003 &&
        stack_level_2 == 12'h000 &&
        stack_bottom == 12'h000,
        "entry preserves the CALL return below interrupt return"
      );
    end else begin
      require(
        stack_level_1 == 12'h000 &&
        stack_level_2 == 12'h000,
        $sformatf("family %0d entry shifts the initialized stack", family)
      );
    end
  endtask

  initial begin
    initialize         = 1'b0;
    rs                 = 1'b0;
    clock_enable       = 1'b1;
    int_n              = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;

    for (int unsigned family = 0; family < FAMILY_COUNT; family++) begin
      for (
        int unsigned arrival_interval = 0;
        arrival_interval < family_cycles(family);
        arrival_interval++
      ) begin
        for (
          int unsigned arrival_phase = 0;
          arrival_phase < 4;
          arrival_phase++
        ) begin
          run_case(family, arrival_interval, arrival_phase);
        end
      end
    end

    $display(
      "PASS tb_sequential_pipeline_interrupt_multicycle (128 native-phase arrival cases)"
    );
    $finish;
  end
endmodule

`default_nettype wire
