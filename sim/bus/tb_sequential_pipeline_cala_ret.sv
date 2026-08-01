`default_nettype none

module tb_sequential_pipeline_cala_ret;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic [15:0] program_data;
  logic [1:0]  phase;
  logic        clkout;
  logic [11:0] program_address;
  logic        men_n;
  logic        den_n;
  logic        we_n;
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
    .program_write_o               (),
    .program_write_data_o          (),
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
    .interrupt_mask_o               (),
    .interrupt_pending_o            (),
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
      require(clkout == phase[1], {name, " CLKOUT follows phase encoding"});
      if (sample) begin
        return;
      end
    end
    $fatal(1, "%s sample event did not arrive", name);
  endtask

  task automatic stall_active_read(
    input logic [11:0] expected_address,
    input logic [11:0] expected_pc,
    input logic [31:0] expected_cycles,
    input logic [11:0] expected_stack,
    input string       name
  );
    tick();
    require(phase == 2'd1 && !men_n && den_n && we_n,
            {name, " exposes program-read strobe"});
    require(program_address == expected_address,
            {name, " exposes expected program address"});
    clock_enable = 1'b0;
    repeat (3) begin
      tick();
      require(phase == 2'd1 && !men_n && !sample,
              {name, " stalls active phase"});
      require(program_address == expected_address && pc == expected_pc &&
              cycle_count == expected_cycles && stack_top == expected_stack &&
              !retired,
              {name, " holds address and architectural state"});
    end
    clock_enable = 1'b1;
  endtask

  task automatic require_program_only(input string name);
    require(bus_active && !data_read && !data_write &&
            !io_read && !io_write && den_n && we_n,
            {name, " has no data or I/O transfer"});
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7e06; // LACK 6
    program_memory[1] = 16'h7f8c; // CALA
    program_memory[2] = 16'h7eee; // discarded, later return address
    program_memory[6] = 16'h7e44; // LACK 0x44
    program_memory[7] = 16'h7f8d; // RET
    program_memory[8] = 16'h7edd; // discarded

    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;
    repeat (12) tick();
    rs = 1'b0;

    advance_to_sample("prime");
    require(execute_valid && execute_address == 12'h000 &&
            execute_word == 16'h7e06 && cycle_count == 32'd0,
            "first fetch primes LACK");
    advance_to_sample("CALA prefetch");
    require(retired && !illegal && accumulator == 32'h0000_0006 &&
            pc == 12'h001 && cycle_count == 32'd1 &&
            execute_address == 12'h001 && execute_word == 16'h7f8c &&
            program_address == 12'h002,
            "LACK retirement gives CALA execute ownership");

    stall_active_read(12'h002, 12'h001, 32'd1, 12'h000,
                      "CALA discarded prefetch");
    advance_to_sample("CALA discarded prefetch");
    require(!retired && !illegal && !pipeline_blocked &&
            execute_address == 12'h001 && execute_word == 16'h7f8c &&
            program_address == 12'h006 && pc == 12'h002 &&
            cycle_count == 32'd2 && stack_top == 12'h000 &&
            accumulator == 32'h0000_0006,
            "CALA discards sequential word and selects ACC target");
    require_program_only("CALA discarded prefetch");

    stall_active_read(12'h006, 12'h002, 32'd2, 12'h000,
                      "CALA target fetch");
    advance_to_sample("CALA target fetch");
    require(retired && !illegal && !pipeline_blocked &&
            execute_address == 12'h006 && execute_word == 16'h7e44 &&
            program_address == 12'h007 && pc == 12'h006 &&
            cycle_count == 32'd3,
            "CALA retires only when target word is captured");
    require({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
            48'h002_000_000_000,
            "CALA pushes opcode PC plus one at target retirement");
    require_program_only("CALA target fetch");

    advance_to_sample("RET prefetch");
    require(retired && accumulator == 32'h0000_0044 &&
            execute_address == 12'h007 && execute_word == 16'h7f8d &&
            program_address == 12'h008 && pc == 12'h007 &&
            cycle_count == 32'd4 && stack_top == 12'h002,
            "target LACK gives RET execute ownership");

    stall_active_read(12'h008, 12'h007, 32'd4, 12'h002,
                      "RET discarded prefetch");
    advance_to_sample("RET discarded prefetch");
    require(!retired && !illegal && !pipeline_blocked &&
            execute_address == 12'h007 && execute_word == 16'h7f8d &&
            program_address == 12'h002 && pc == 12'h008 &&
            cycle_count == 32'd5 && stack_top == 12'h002,
            "RET discards sequential word and selects old stack top");
    require_program_only("RET discarded prefetch");

    stall_active_read(12'h002, 12'h008, 32'd5, 12'h002,
                      "RET target fetch");
    advance_to_sample("RET target fetch");
    require(retired && !illegal && !pipeline_blocked &&
            execute_address == 12'h002 && execute_word == 16'h7eee &&
            program_address == 12'h003 && pc == 12'h002 &&
            cycle_count == 32'd6 && accumulator == 32'h0000_0044,
            "RET retires only when return word is captured");
    require({stack_top, stack_level_1, stack_level_2, stack_bottom} ==
            48'h000_000_000_000,
            "RET pops at target retirement");
    require_program_only("RET target fetch");

    advance_to_sample("returned word");
    require(retired && !illegal && accumulator == 32'h0000_00ee &&
            pc == 12'h003 && cycle_count == 32'd7,
            "discarded word executes only after RET returns to it");

    $display("PASS tb_sequential_pipeline_cala_ret");
    $finish;
  end
endmodule

`default_nettype wire
