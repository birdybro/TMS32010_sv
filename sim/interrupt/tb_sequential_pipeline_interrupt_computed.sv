`default_nettype none

module tb_sequential_pipeline_interrupt_computed;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic        int_n;
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
  logic        data_read;
  logic        data_write;
  logic        io_read;
  logic        io_write;
  logic [11:0] pc;
  logic [31:0] accumulator;
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
    .io_read_data_i                (16'h0000),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
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
    .data_address_o                (),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .io_port_o                     (),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
    .overflow_flag_o                (),
    .overflow_mode_o                (),
    .interrupt_mask_o               (interrupt_mask),
    .interrupt_pending_o            (interrupt_pending),
    .instruction_valid_o            (),
    .retired_o                      (retired),
    .illegal_o                      (illegal),
    .cycle_count_o                  (cycle_count)
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

  task automatic advance_to_sample(input string name);
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require(clkout == phase[1], {name, " CLKOUT follows phase"});
      require(!((!men_n && !den_n) || (!men_n && !we_n) ||
                (!den_n && !we_n)),
              {name, " strobes remain exclusive"});
      if (sample) begin
        return;
      end
    end
    $fatal(1, "%s sample event did not arrive", name);
  endtask

  task automatic clear_program;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
  endtask

  task automatic initialize_pipeline(input string name);
    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    int_n        = 1'b1;
    tick();
    initialize = 1'b0;
    repeat (20) begin
      tick();
      require(!bus_active && men_n && den_n && we_n,
              {name, " reset holds the native bus inactive"});
    end
    rs = 1'b0;
  endtask

  task automatic pause_at_arrival(
    input int unsigned arrival_interval,
    input int unsigned arrival_phase,
    input string       name
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
    logic        saved_data_read;
    logic        saved_data_write;
    logic        saved_io_read;
    logic        saved_io_write;
    logic [11:0] saved_pc;
    logic [31:0] saved_accumulator;
    logic [11:0] saved_stack_top;
    logic [11:0] saved_stack_level_1;
    logic [11:0] saved_stack_level_2;
    logic [11:0] saved_stack_bottom;
    logic        saved_interrupt_mask;
    logic        saved_interrupt_pending;
    logic [31:0] saved_cycle_count;

    saved_phase              = phase;
    saved_program_address    = program_address;
    saved_men_n              = men_n;
    saved_den_n              = den_n;
    saved_we_n               = we_n;
    saved_program_write      = program_write;
    saved_program_write_data = program_write_data;
    saved_bus_active         = bus_active;
    saved_execute_valid      = execute_valid;
    saved_execute_address    = execute_address;
    saved_execute_word       = execute_word;
    saved_pipeline_blocked   = pipeline_blocked;
    saved_data_read          = data_read;
    saved_data_write         = data_write;
    saved_io_read            = io_read;
    saved_io_write           = io_write;
    saved_pc                 = pc;
    saved_accumulator        = accumulator;
    saved_stack_top          = stack_top;
    saved_stack_level_1      = stack_level_1;
    saved_stack_level_2      = stack_level_2;
    saved_stack_bottom       = stack_bottom;
    saved_interrupt_mask     = interrupt_mask;
    saved_interrupt_pending  = interrupt_pending;
    saved_cycle_count        = cycle_count;

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
      data_read == saved_data_read && data_write == saved_data_write &&
      io_read == saved_io_read && io_write == saved_io_write &&
      pc == saved_pc && accumulator == saved_accumulator &&
      stack_top == saved_stack_top &&
      stack_level_1 == saved_stack_level_1 &&
      stack_level_2 == saved_stack_level_2 &&
      stack_bottom == saved_stack_bottom &&
      interrupt_mask == saved_interrupt_mask &&
      interrupt_pending == saved_interrupt_pending &&
      cycle_count == saved_cycle_count,
      $sformatf(
        "%s arrival interval %0d phase %0d pause holds state and bus",
        name,
        arrival_interval,
        arrival_phase
      )
    );
    clock_enable = 1'b1;
  endtask

  task automatic computed_interval(
    input int unsigned interval,
    input int unsigned arrival_interval,
    input int unsigned arrival_phase,
    input logic [11:0] expected_address,
    input logic [11:0] expected_pc,
    input logic [11:0] expected_stack,
    input string       name
  );
    logic [11:0] saved_execute_address;
    logic [15:0] saved_execute_word;
    logic [31:0] before_cycles;

    saved_execute_address = execute_address;
    saved_execute_word    = execute_word;
    before_cycles         = cycle_count;

    require(
      phase == 2'd0 &&
      interrupt_pending == (interval > arrival_interval) &&
      !interrupt_mask,
      {name, " begins without early request recognition"}
    );

    if ((interval == arrival_interval) && (arrival_phase == 0)) begin
      int_n = 1'b0;
      pause_at_arrival(arrival_interval, arrival_phase, name);
    end

    for (int unsigned active_phase = 1; active_phase < 4; active_phase++) begin
      tick();
      require(
        phase == active_phase[1:0] &&
        !sample && !retired && !illegal &&
        !men_n && den_n && we_n && !program_write &&
        program_address == expected_address &&
        !data_read && !data_write && !io_read && !io_write &&
        execute_valid && execute_address == saved_execute_address &&
        execute_word == saved_execute_word &&
        interrupt_pending == (interval > arrival_interval) &&
        !interrupt_mask && cycle_count == before_cycles,
        $sformatf(
          "%s arrival interval %0d phase %0d has no pre-boundary recognition or retirement",
          name,
          arrival_interval,
          arrival_phase
        )
      );

      if (
        (interval == arrival_interval) &&
        (arrival_phase == active_phase)
      ) begin
        int_n = 1'b0;
        pause_at_arrival(arrival_interval, arrival_phase, name);
        require(
          interrupt_pending == (interval > arrival_interval) &&
          cycle_count == before_cycles,
          {name, " paused arrival cannot sample INT"}
        );
      end
    end

    tick();
    int_n = 1'b1;
    require(
      phase == 2'd0 && sample && !illegal && !pipeline_blocked &&
      interrupt_pending == (interval >= arrival_interval) &&
      cycle_count == before_cycles + 32'd1,
      {name, " interval latches request only at its enabled boundary"}
    );
    if (interval == 0) begin
      require(!retired && pc == expected_pc && stack_top == expected_stack,
              {name, " cannot retire or mutate stack midinstruction"});
    end
  endtask

  task automatic finish_interrupt(
    input logic [11:0] protected_pc,
    input logic [11:0] return_pc,
    input logic [11:0] prior_stack,
    input logic [31:0] completion_cycles,
    input string       name
  );
    require(retired && execute_valid && execute_address == protected_pc &&
            execute_word == 16'h7e44 && pc == protected_pc &&
            program_address == return_pc && interrupt_pending &&
            !interrupt_mask,
            {name, " completes before protected instruction"});

    tick();
    require(phase == 2'd1 && !men_n && program_address == return_pc &&
            execute_address == protected_pc,
            {name, " protected instruction overlaps dummy read"});
    advance_to_sample({name, " protected"});
    require(retired && !illegal && !execute_valid &&
            accumulator == 32'h0000_0044 && pc == return_pc &&
            cycle_count == completion_cycles + 32'd1 &&
            program_address == 12'h002,
            {name, " retires one protected instruction"});

    tick();
    require(phase == 2'd1 && !men_n && program_address == 12'h002 &&
            !execute_valid,
            {name, " vector fetch follows empty execute slot"});
    advance_to_sample({name, " vector"});
    require(!retired && !illegal && execute_valid &&
            execute_address == 12'h002 && pc == 12'h002 &&
            stack_top == return_pc && stack_level_1 == prior_stack &&
            stack_level_2 == 12'h000 && stack_bottom == 12'h000 &&
            interrupt_mask && !interrupt_pending &&
            cycle_count == completion_cycles + 32'd2,
            {name, " entry stacks resolved PC only after protection"});
  endtask

  task automatic run_cala(
    input int unsigned arrival_interval,
    input int unsigned arrival_phase
  );
    clear_program();
    program_memory[12'h000] = 16'h7e10; // LACK 0x10
    program_memory[12'h001] = 16'h7f82; // EINT
    program_memory[12'h002] = 16'h7f8c; // CALA
    program_memory[12'h003] = 16'h7f89; // discarded, then CALA return
    program_memory[12'h010] = 16'h7e44; // protected target instruction
    program_memory[12'h011] = 16'h7f89; // dummy fetch
    initialize_pipeline("CALA");

    advance_to_sample("CALA prime");
    advance_to_sample("CALA target setup");
    advance_to_sample("CALA EINT");
    require(execute_valid && execute_address == 12'h002 &&
            execute_word == 16'h7f8c && pc == 12'h002 &&
            accumulator == 32'h0000_0010 && !interrupt_mask &&
            cycle_count == 32'd2,
            "CALA begins after request-free EINT");

    computed_interval(0, arrival_interval, arrival_phase,
                      12'h003, 12'h003, 12'h000,
                      "CALA discarded prefetch");
    require(cycle_count == 32'd3, "CALA first interval counts once");
    computed_interval(1, arrival_interval, arrival_phase,
                      12'h010, 12'h003, 12'h000,
                      "CALA target fetch");
    require(pc == 12'h010 && stack_top == 12'h003 &&
            cycle_count == 32'd4,
            "CALA retires with its own return below interrupt entry");
    finish_interrupt(12'h010, 12'h011, 12'h003, 32'd4, "CALA");
  endtask

  task automatic run_ret(
    input int unsigned arrival_interval,
    input int unsigned arrival_phase
  );
    clear_program();
    program_memory[12'h000] = 16'hf800; // CALL setup
    program_memory[12'h001] = 16'h000a;
    program_memory[12'h002] = 16'h7e44; // protected RET target
    program_memory[12'h003] = 16'h7f89; // dummy fetch
    program_memory[12'h00a] = 16'h7f82; // EINT
    program_memory[12'h00b] = 16'h7f8d; // RET
    program_memory[12'h00c] = 16'h7f89; // discarded
    initialize_pipeline("RET");

    advance_to_sample("RET CALL prime");
    advance_to_sample("RET CALL operand");
    advance_to_sample("RET CALL target");
    advance_to_sample("RET EINT");
    require(execute_valid && execute_address == 12'h00b &&
            execute_word == 16'h7f8d && pc == 12'h00b &&
            stack_top == 12'h002 && !interrupt_mask &&
            cycle_count == 32'd3,
            "RET begins with a seeded stack after request-free EINT");

    computed_interval(0, arrival_interval, arrival_phase,
                      12'h00c, 12'h00c, 12'h002,
                      "RET discarded prefetch");
    require(cycle_count == 32'd4, "RET first interval counts once");
    computed_interval(1, arrival_interval, arrival_phase,
                      12'h002, 12'h00c, 12'h002,
                      "RET target fetch");
    require(pc == 12'h002 && stack_top == 12'h000 &&
            cycle_count == 32'd5,
            "RET pops only when its target is captured");
    finish_interrupt(12'h002, 12'h003, 12'h000, 32'd5, "RET");
  endtask

  initial begin
    initialize   = 1'b0;
    rs           = 1'b0;
    clock_enable = 1'b1;
    int_n        = 1'b1;

    for (int unsigned arrival_interval = 0;
         arrival_interval < 2;
         arrival_interval++) begin
      for (int unsigned arrival_phase = 0;
           arrival_phase < 4;
           arrival_phase++) begin
        run_cala(arrival_interval, arrival_phase);
        run_ret(arrival_interval, arrival_phase);
      end
    end

    $display(
      "PASS tb_sequential_pipeline_interrupt_computed (16 native-phase arrival cases)"
    );
    $finish;
  end
endmodule

`default_nettype wire
