`default_nettype none

module tb_sequential_pipeline_io;
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
  logic [11:0] native_address;
  logic        men_n;
  logic        den_n;
  logic        we_n;
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
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic [15:0] io_write_data;
  logic [11:0] pc;
  logic [15:0] auxiliary_register_0;
  logic        auxiliary_register_pointer;
  logic        data_page_pointer;
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
    .program_address_o             (native_address),
    .men_n_o                       (men_n),
    .den_n_o                       (den_n),
    .we_n_o                        (we_n),
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
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (io_write_data),
    .pc_o                          (pc),
    .accumulator_o                 (),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (data_page_pointer),
    .stack_top_o                    (),
    .stack_level_1_o               (),
    .stack_level_2_o               (),
    .stack_bottom_o                (),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (),
    .interrupt_pending_o           (),
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

  task automatic require_exclusive_strobes(input string name);
    require(clkout == phase[1], {name, " CLKOUT follows phase encoding"});
    require(
      !(
        (!men_n && !den_n) ||
        (!men_n && !we_n) ||
        (!den_n && !we_n)
      ),
      {name, " MEN, DEN, and WE are mutually exclusive"}
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

  task automatic reset_and_seed(
    input logic [7:0]  address,
    input logic [15:0] value,
    input string       name
  );
    initialize        = 1'b1;
    rs                = 1'b1;
    clock_enable      = 1'b1;
    debug_data_write  = 1'b1;
    debug_data_address = address;
    debug_data        = value;
    tick();
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    repeat (20) begin
      tick();
      require(
        !bus_active && men_n && den_n && we_n,
        {name, " reset keeps every native strobe inactive"}
      );
    end
    rs = 1'b0;
  endtask

  task automatic test_direct_in_out;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h4203;  // IN 3,PA2
    program_memory[1] = 16'h4f03;  // OUT 3,PA7
    program_memory[2] = 16'h7042;  // target/following effect
    program_memory[3] = 16'h7f80;  // NOP
    io_read_data = 16'h1111;
    reset_and_seed(8'h03, 16'hcafe, "direct I/O");

    advance_to_sample("direct I/O");
    require(
      execute_valid &&
      execute_address == 12'h000 &&
      execute_word == 16'h4203 &&
      !retired &&
      cycle_count == 32'd0 &&
      phase == 2'd0 &&
      native_address == 12'h002 &&
      men_n && den_n && we_n &&
      io_read && !io_write && io_port == 3'd2,
      "IN prefetch starts execution cycle 1 at port address two"
    );
    require(
      data_write && !data_read &&
      data_address_valid && data_address == 8'h03 &&
      data_write_data == 16'h1111 &&
      data_read_data == 16'hcafe,
      "IN exposes its live port word and old internal RAM contents"
    );

    tick();
    require(
      phase == 2'd1 &&
      native_address == 12'h002 &&
      men_n && !den_n && we_n &&
      io_read && !io_write,
      "IN execution cycle 1 asserts DEN alone"
    );
    clock_enable = 1'b0;
    io_read_data = 16'hbeef;
    repeat (3) begin
      tick();
      require_exclusive_strobes("stalled IN");
      require(
        phase == 2'd1 &&
        native_address == 12'h002 &&
        men_n && !den_n && we_n &&
        io_read && !io_write &&
        data_write && data_write_data == 16'hbeef &&
        data_read_data == 16'hcafe &&
        !sample && !retired &&
        cycle_count == 32'd0,
        "stalled IN holds phase/address while input data remains live"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("direct IN transfer");
    require(
      !retired &&
      !illegal &&
      execute_address == 12'h000 &&
      execute_word == 16'h4203 &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      native_address == 12'h001 &&
      men_n && den_n && we_n &&
      !io_read && !io_write &&
      !data_read && !data_write &&
      data_read_data == 16'hcafe &&
      !pipeline_blocked,
      "IN transfer sample starts execution cycle 2 without early RAM write"
    );

    tick();
    require(
      phase == 2'd1 &&
      native_address == 12'h001 &&
      !men_n && den_n && we_n &&
      execute_address == 12'h000,
      "IN execution cycle 2 fetches the following instruction"
    );
    clock_enable = 1'b0;
    io_read_data = 16'h1234;
    repeat (2) begin
      tick();
      require(
        phase == 2'd1 &&
        native_address == 12'h001 &&
        !men_n && den_n && we_n &&
        execute_address == 12'h000 &&
        pc == 12'h001 &&
        cycle_count == 32'd1 &&
        !sample && !retired,
        "following-prefetch stall retains IN ownership and sampled input"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("direct IN following prefetch");
    require(
      retired &&
      !illegal &&
      execute_address == 12'h001 &&
      execute_word == 16'h4f03 &&
      pc == 12'h001 &&
      cycle_count == 32'd2 &&
      phase == 2'd0 &&
      native_address == 12'h007 &&
      io_write && !io_read && io_port == 3'd7 &&
      data_read && !data_write &&
      data_address_valid && data_address == 8'h03 &&
      data_read_data == 16'hbeef &&
      io_write_data == 16'hbeef &&
      !pipeline_blocked,
      "IN retirement captures OUT and commits the sampled input word"
    );

    tick();
    require(
      phase == 2'd1 &&
      native_address == 12'h007 &&
      men_n && den_n && !we_n &&
      io_write && !io_read &&
      io_write_data == 16'hbeef,
      "OUT execution cycle 1 asserts WE with the IN-written word"
    );
    clock_enable = 1'b0;
    repeat (3) begin
      tick();
      require_exclusive_strobes("stalled OUT");
      require(
        phase == 2'd1 &&
        native_address == 12'h007 &&
        men_n && den_n && !we_n &&
        io_write && !io_read &&
        data_read && !data_write &&
        data_read_data == 16'hbeef &&
        io_write_data == 16'hbeef &&
        !sample && !retired &&
        cycle_count == 32'd2,
        "stalled OUT holds port, WE, and write data"
      );
    end
    clock_enable = 1'b1;

    advance_to_sample("direct OUT transfer");
    require(
      !retired &&
      !illegal &&
      execute_address == 12'h001 &&
      execute_word == 16'h4f03 &&
      pc == 12'h002 &&
      cycle_count == 32'd3 &&
      native_address == 12'h002 &&
      men_n && den_n && we_n &&
      !io_read && !io_write &&
      !data_read && !data_write &&
      !pipeline_blocked,
      "OUT transfer sample starts its following-prefetch interval"
    );

    advance_to_sample("direct OUT following prefetch");
    require(
      retired &&
      !illegal &&
      execute_address == 12'h002 &&
      execute_word == 16'h7042 &&
      pc == 12'h002 &&
      cycle_count == 32'd4 &&
      auxiliary_register_0 == 16'h0000 &&
      native_address == 12'h003 &&
      !pipeline_blocked,
      "following prefetch retires OUT without executing the fetched word"
    );

    advance_to_sample("following instruction");
    require(
      retired &&
      !illegal &&
      execute_address == 12'h003 &&
      pc == 12'h003 &&
      cycle_count == 32'd5 &&
      auxiliary_register_0 == 16'h0042,
      "instruction after OUT executes only in the following interval"
    );
  endtask

  task automatic test_indirect_update_at_prefetch_retirement;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7003;  // LARK AR0,3
    program_memory[1] = 16'h41a1;  // IN *+,PA1,AR1
    program_memory[2] = 16'h4d03;  // OUT 3,PA5 observes the IN result
    io_read_data = 16'habcd;
    reset_and_seed(8'h03, 16'hcafe, "indirect IN");

    advance_to_sample("indirect IN prime");
    advance_to_sample("indirect IN setup");
    require(
      retired &&
      execute_address == 12'h001 &&
      execute_word == 16'h41a1 &&
      auxiliary_register_0 == 16'h0003 &&
      !auxiliary_register_pointer &&
      data_address == 8'h03 &&
      data_write && data_write_data == 16'habcd &&
      data_read_data == 16'hcafe,
      "indirect IN transfer uses the old selected AR address"
    );

    advance_to_sample("indirect IN transfer");
    require(
      !retired &&
      pc == 12'h002 &&
      cycle_count == 32'd2 &&
      execute_address == 12'h001 &&
      auxiliary_register_0 == 16'h0003 &&
      !auxiliary_register_pointer &&
      data_read_data == 16'hcafe &&
      native_address == 12'h002 &&
      men_n && den_n && we_n &&
      !io_read && !io_write,
      "indirect IN transfer sample defers RAM, AR, and ARP mutation"
    );

    advance_to_sample("indirect IN following prefetch");
    require(
      retired &&
      pc == 12'h002 &&
      cycle_count == 32'd3 &&
      execute_address == 12'h002 &&
      execute_word == 16'h4d03 &&
      auxiliary_register_0 == 16'h0004 &&
      auxiliary_register_pointer &&
      io_write && io_port == 3'd5 &&
      data_address == 8'h03 &&
      data_read_data == 16'habcd &&
      io_write_data == 16'habcd,
      "following prefetch commits old-address IN then applies AR and ARP update"
    );
  endtask

  task automatic test_invalid_data_address;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h6e01;  // LDPK 1
    program_memory[1] = 16'h4220;  // IN 0x20,PA2 -> physical 0xa0
    io_read_data = 16'h5678;
    reset_and_seed(8'h03, 16'hcafe, "invalid IN");

    advance_to_sample("invalid IN");
    advance_to_sample("invalid IN");
    require(
      retired &&
      !illegal &&
      data_page_pointer &&
      execute_address == 12'h001 &&
      execute_word == 16'h4220 &&
      pc == 12'h001 &&
      cycle_count == 32'd1 &&
      pipeline_blocked &&
      native_address == 12'h002 &&
      men_n && den_n && we_n &&
      !io_read && !io_write &&
      !data_read && !data_write && !data_address_valid,
      "invalid IN parks before any external or internal transfer"
    );
    repeat (4) begin
      tick();
      require(
        phase == 2'd0 &&
        pipeline_blocked &&
        native_address == 12'h002 &&
        men_n && den_n && we_n &&
        !io_read && !io_write &&
        !sample && !retired &&
        cycle_count == 32'd1,
        "invalid IN remains visibly parked with all strobes inactive"
      );
    end
  endtask

  initial begin
    initialize         = 1'b1;
    rs                 = 1'b1;
    clock_enable       = 1'b1;
    io_read_data       = 16'h0000;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;

    test_direct_in_out();
    test_indirect_update_at_prefetch_retirement();
    test_invalid_data_address();

    $display("PASS tb_sequential_pipeline_io");
    $finish;
  end
endmodule

`default_nettype wire
