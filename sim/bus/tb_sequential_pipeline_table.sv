`default_nettype none

module tb_sequential_pipeline_table;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
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
  logic [15:0] data_read_data;
  logic [15:0] data_write_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
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
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (data_read_data),
    .data_write_data_o             (data_write_data),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .io_write_data_o               (),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (),
    .stack_top_o                    (stack_top),
    .stack_level_1_o                (stack_level_1),
    .stack_level_2_o                (stack_level_2),
    .stack_bottom_o                 (stack_bottom),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (),
    .interrupt_pending_o           (),
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
    require(clkout == phase[1], {name, " CLKOUT follows phase encoding"});
    require(
      !(
        (!men_n && !den_n) ||
        (!men_n && !we_n) ||
        (!den_n && !we_n)
      ),
      {name, " MEN, DEN, and WE remain mutually exclusive"}
    );
  endtask

  task automatic advance_to_sample(input string name);
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require_exclusive_strobes(name);
      if (sample) begin
        return;
      end
    end
    $fatal(1, "%s sample event did not arrive", name);
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end

    program_memory[12'h000] = 16'hf800;  // CALL 0x010
    program_memory[12'h001] = 16'h0010;
    program_memory[12'h010] = 16'hf800;  // CALL 0x030
    program_memory[12'h011] = 16'h0030;
    program_memory[12'h020] = 16'h7e44;  // table source: LACK 0x44
    program_memory[12'h030] = 16'hf800;  // CALL 0x050
    program_memory[12'h031] = 16'h0050;
    program_memory[12'h050] = 16'hf800;  // CALL 0x080
    program_memory[12'h051] = 16'h0080;
    program_memory[12'h080] = 16'h7005;  // LARK AR0,5
    program_memory[12'h081] = 16'h7109;  // LARK AR1,9
    program_memory[12'h082] = 16'h7e20;  // LACK 0x20
    program_memory[12'h083] = 16'h67a1;  // TBLR *+,AR1
    program_memory[12'h084] = 16'h7e86;  // refetched LACK 0x86
    program_memory[12'h085] = 16'h7d05;  // TBLW 5
    program_memory[12'h086] = 16'h7f89;  // discarded old ZAC
    program_memory[12'h087] = 16'h7f80;  // NOP

    initialize         = 1'b1;
    rs                 = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    tick();
    initialize = 1'b0;

    debug_data_write   = 1'b1;
    debug_data_address = 8'h05;
    debug_data         = 16'h0000;
    tick();
    debug_data_write = 1'b0;

    repeat (20) begin
      tick();
      require(
        !bus_active && men_n && den_n && we_n && !program_write,
        "reset keeps every native strobe inactive"
      );
    end
    rs = 1'b0;

    advance_to_sample("first CALL prefetch");
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'hf800 &&
      cycle_count == 32'd0,
      "first fetch primes CALL without execution"
    );

    for (int unsigned call_index = 0; call_index < 4; call_index++) begin
      advance_to_sample("CALL operand");
      require(
        !retired &&
        execute_word == 16'hf800,
        "CALL operand is nonexecutable"
      );
      advance_to_sample("CALL target");
      require(
        retired && !illegal,
        "CALL retires only when its selected target is captured"
      );
    end

    require(
      execute_valid &&
      execute_address == 12'h080 &&
      execute_word == 16'h7005 &&
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
        {12'h052, 12'h032, 12'h012, 12'h002} &&
      cycle_count == 32'd8,
      "four CALLs establish distinct stack entries before the table test"
    );

    advance_to_sample("LARK AR0");
    advance_to_sample("LARK AR1");
    advance_to_sample("LACK table address");
    require(
      retired &&
      execute_address == 12'h083 &&
      execute_word == 16'h67a1 &&
      accumulator == 32'h0000_0020 &&
      auxiliary_register_0 == 16'h0005 &&
      auxiliary_register_1 == 16'h0009 &&
      !auxiliary_register_pointer &&
      cycle_count == 32'd11 &&
      program_address == 12'h084,
      "setup captures indirect TBLR with old address and stack state"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n &&
      !program_write &&
      program_address == 12'h084 &&
      execute_address == 12'h083 &&
      !data_read && !data_write,
      "TBLR cycle 1 is the discarded PC+1 MEN prefetch"
    );
    clock_enable = 1'b0;
    repeat (3) begin
      tick();
      require(
        phase == 2'd1 &&
        !men_n && den_n && we_n &&
        program_address == 12'h084 &&
        execute_address == 12'h083 &&
        auxiliary_register_0 == 16'h0005 &&
        !auxiliary_register_pointer &&
        stack_bottom == 12'h002 &&
        cycle_count == 32'd11 &&
        !retired,
        "discarded-prefetch stall cannot advance TBLR or architectural state"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("TBLR discarded prefetch");
    require(
      !retired &&
      execute_address == 12'h083 &&
      execute_word == 16'h67a1 &&
      pc == 12'h084 &&
      cycle_count == 32'd12 &&
      program_address == 12'h020 &&
      auxiliary_register_0 == 16'h0005 &&
      !auxiliary_register_pointer &&
      stack_bottom == 12'h002,
      "TBLR retains execute ownership and selects the captured ACC address"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n &&
      !program_write &&
      program_address == 12'h020 &&
      data_write && !data_read &&
      data_address_valid && data_address == 8'h05 &&
      data_write_data == 16'h7e44,
      "TBLR cycle 2 reads program space and presents the sampled RAM write"
    );
    clock_enable = 1'b0;
    repeat (2) begin
      tick();
      require(
        program_address == 12'h020 &&
        !men_n && den_n && we_n &&
        data_write && !data_read &&
        data_write_data == 16'h7e44 &&
        auxiliary_register_0 == 16'h0005 &&
        !auxiliary_register_pointer &&
        stack_bottom == 12'h002 &&
        cycle_count == 32'd12 &&
        !retired,
        "table-read stall holds data and defers every TBLR effect"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("TBLR table read");
    require(
      !retired &&
      execute_address == 12'h083 &&
      execute_word == 16'h67a1 &&
      pc == 12'h084 &&
      cycle_count == 32'd13 &&
      program_address == 12'h084 &&
      auxiliary_register_0 == 16'h0005 &&
      !auxiliary_register_pointer &&
      stack_bottom == 12'h002,
      "TBLR samples table data but defers commit until repeated prefetch"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n &&
      !program_write &&
      program_address == 12'h084 &&
      !data_read && !data_write &&
      execute_address == 12'h083,
      "TBLR cycle 3 repeats the following instruction prefetch"
    );
    clock_enable = 1'b0;
    repeat (2) begin
      tick();
      require(
        program_address == 12'h084 &&
        execute_address == 12'h083 &&
        auxiliary_register_0 == 16'h0005 &&
        !auxiliary_register_pointer &&
        stack_bottom == 12'h002 &&
        cycle_count == 32'd13 &&
        !retired,
        "repeated-prefetch stall cannot commit TBLR early"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("TBLR repeated prefetch");
    require(
      retired &&
      !illegal &&
      execute_valid &&
      execute_address == 12'h084 &&
      execute_word == 16'h7e86 &&
      pc == 12'h084 &&
      cycle_count == 32'd14 &&
      program_address == 12'h085 &&
      auxiliary_register_0 == 16'h0006 &&
      auxiliary_register_1 == 16'h0009 &&
      auxiliary_register_pointer &&
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
        {12'h052, 12'h032, 12'h012, 12'h012},
      "TBLR commits AR/ARP/stack and captures only the repeated PC+1 word"
    );

    advance_to_sample("instruction following TBLR");
    require(
      retired &&
      accumulator == 32'h0000_0086 &&
      execute_address == 12'h085 &&
      execute_word == 16'h7d05 &&
      cycle_count == 32'd15 &&
      program_address == 12'h086,
      "refetched LACK executes before TBLW enters ownership"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n &&
      !program_write &&
      program_address == 12'h086 &&
      execute_address == 12'h085 &&
      program_memory[12'h086] == 16'h7f89,
      "TBLW cycle 1 discards the old following-word prefetch"
    );
    advance_to_sample("TBLW discarded prefetch");
    require(
      !retired &&
      execute_address == 12'h085 &&
      execute_word == 16'h7d05 &&
      pc == 12'h086 &&
      cycle_count == 32'd16 &&
      program_address == 12'h086,
      "TBLW retains ownership and selects captured ACC address"
    );

    tick();
    require(
      phase == 2'd1 &&
      men_n && den_n && !we_n &&
      program_write &&
      program_address == 12'h086 &&
      program_write_data == 16'h7e44 &&
      data_read && !data_write &&
      data_address_valid && data_address == 8'h05 &&
      data_read_data == 16'h7e44,
      "TBLW cycle 2 drives the captured RAM word under program WE"
    );
    clock_enable = 1'b0;
    repeat (3) begin
      tick();
      require(
        program_address == 12'h086 &&
        men_n && den_n && !we_n &&
        program_write &&
        program_write_data == 16'h7e44 &&
        program_memory[12'h086] == 16'h7f89 &&
        cycle_count == 32'd16 &&
        !retired,
        "table-write stall holds pins and cannot mutate program memory early"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("TBLW table write");
    require(
      !retired &&
      execute_address == 12'h085 &&
      execute_word == 16'h7d05 &&
      pc == 12'h086 &&
      cycle_count == 32'd17 &&
      program_memory[12'h086] == 16'h7e44 &&
      program_address == 12'h086,
      "TBLW transfer writes memory but defers retirement to the refetch"
    );

    tick();
    require(
      phase == 2'd1 &&
      !men_n && den_n && we_n &&
      !program_write &&
      !data_read && !data_write &&
      program_address == 12'h086 &&
      program_data == 16'h7e44,
      "TBLW cycle 3 refetches the newly written following word under MEN"
    );
    clock_enable = 1'b0;
    repeat (2) begin
      tick();
      require(
        program_address == 12'h086 &&
        execute_address == 12'h085 &&
        accumulator == 32'h0000_0086 &&
        cycle_count == 32'd17 &&
        !retired,
        "TBLW refetch stall cannot retire or execute the new word early"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("TBLW repeated prefetch");
    require(
      retired &&
      !illegal &&
      execute_valid &&
      execute_address == 12'h086 &&
      execute_word == 16'h7e44 &&
      accumulator == 32'h0000_0086 &&
      pc == 12'h086 &&
      cycle_count == 32'd18 &&
      program_address == 12'h087 &&
      stack_bottom == 12'h012,
      "TBLW retires only after capturing the rewritten PC+1 word"
    );

    advance_to_sample("rewritten instruction execution");
    require(
      retired &&
      !illegal &&
      accumulator == 32'h0000_0044 &&
      pc == 12'h087 &&
      cycle_count == 32'd19 &&
      stack_bottom == 12'h012 &&
      !pipeline_blocked,
      "only the repeated, rewritten word executes after TBLW"
    );

    $display("PASS tb_sequential_pipeline_table");
    $finish;
  end
endmodule

`default_nettype wire
