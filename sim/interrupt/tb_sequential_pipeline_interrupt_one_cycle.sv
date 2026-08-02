`default_nettype none

module tb_sequential_pipeline_interrupt_one_cycle;
  localparam int unsigned FAMILY_COUNT = 39;

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
  logic [15:0] auxiliary_register_1;
  logic [11:0] pc;
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
    .program_write_data_o          (),
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
    .data_write_data_o             (),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .io_write_data_o               (),
    .pc_o                          (pc),
    .accumulator_o                 (),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (auxiliary_register_1),
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

  function automatic logic [15:0] family_opcode(
    input int unsigned family
  );
    case (family)
      0:  family_opcode = 16'h7e11;  // LACK 0x11
      1:  family_opcode = 16'h7f80;  // NOP
      2:  family_opcode = 16'h7f89;  // ZAC
      3:  family_opcode = 16'h7f8a;  // ROVM
      4:  family_opcode = 16'h7f8b;  // SOVM
      5:  family_opcode = 16'h7012;  // LARK AR0,0x12
      6:  family_opcode = 16'h6880;  // LARP 0
      7:  family_opcode = 16'h6e00;  // LDPK 0
      8:  family_opcode = 16'h2000;  // LAC 0,0
      9:  family_opcode = 16'h5000;  // SACL 0
      10: family_opcode = 16'h5800;  // SACH 0,0
      11: family_opcode = 16'h6500;  // ZALH 0
      12: family_opcode = 16'h6600;  // ZALS 0
      13: family_opcode = 16'h6100;  // ADDS 0
      14: family_opcode = 16'h7800;  // XOR 0
      15: family_opcode = 16'h7900;  // AND 0
      16: family_opcode = 16'h7a00;  // OR 0
      17: family_opcode = 16'h0000;  // ADD 0,0
      18: family_opcode = 16'h1000;  // SUB 0,0
      19: family_opcode = 16'h6300;  // SUBS 0
      20: family_opcode = 16'h3800;  // LAR AR0,0
      21: family_opcode = 16'h3000;  // SAR AR0,0
      22: family_opcode = 16'h6800;  // MAR 0
      23: family_opcode = 16'h6f00;  // LDP 0
      24: family_opcode = 16'h6a00;  // LT 0
      25: family_opcode = 16'h6d00;  // MPY 0
      26: family_opcode = 16'h8002;  // MPYK 2
      27: family_opcode = 16'h7f8e;  // PAC
      28: family_opcode = 16'h7f8f;  // APAC
      29: family_opcode = 16'h7f90;  // SPAC
      30: family_opcode = 16'h6c00;  // LTA 0
      31: family_opcode = 16'h6b00;  // LTD 0
      32: family_opcode = 16'h6900;  // DMOV 0
      33: family_opcode = 16'h7b00;  // LST 0
      34: family_opcode = 16'h6400;  // SUBC 0
      35: family_opcode = 16'h6200;  // SUBH 0
      36: family_opcode = 16'h7f88;  // ABS
      37: family_opcode = 16'h7c00;  // SST 0
      38: family_opcode = 16'h6000;  // ADDH 0
      default: family_opcode = 16'hffff;
    endcase
  endfunction

  function automatic logic family_reads_data(input int unsigned family);
    case (family)
      8,
      11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
      23, 24, 25,
      30, 31, 32, 33, 34, 35,
      38: family_reads_data = 1'b1;
      default: family_reads_data = 1'b0;
    endcase
  endfunction

  function automatic logic family_writes_data(input int unsigned family);
    case (family)
      9, 10, 21, 31, 32, 37: family_writes_data = 1'b1;
      default: family_writes_data = 1'b0;
    endcase
  endfunction

  function automatic logic [7:0] family_data_address(
    input int unsigned family
  );
    family_data_address = (family == 37) ? 8'h80 : 8'h00;
  endfunction

  function automatic logic [7:0] family_write_address(
    input int unsigned family
  );
    if ((family == 31) || (family == 32)) begin
      family_write_address = 8'h01;
    end else begin
      family_write_address = family_data_address(family);
    end
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

  task automatic require_exclusive_strobes(input int unsigned family);
    require(
      clkout == phase[1],
      $sformatf("family %0d CLKOUT follows phase", family)
    );
    require(
      !(
        (!men_n && !den_n) ||
        (!men_n && !we_n) ||
        (!den_n && !we_n)
      ),
      $sformatf("family %0d native strobes are exclusive", family)
    );
  endtask

  task automatic advance_to_sample(
    input int unsigned family,
    input string interval_name
  );
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require_exclusive_strobes(family);
      if (sample) begin
        return;
      end
    end
    $fatal(
      1,
      "family %0d %s sample did not arrive",
      family,
      interval_name
    );
  endtask

  task automatic clear_program;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
  endtask

  task automatic initialize_pipeline(input int unsigned family);
    initialize         = 1'b1;
    rs                 = 1'b1;
    clock_enable       = 1'b1;
    int_n              = 1'b1;
    debug_data_write   = 1'b0;
    debug_data_address = 8'h00;
    debug_data         = 16'h0000;
    tick();
    initialize = 1'b0;

    debug_data_write = 1'b1;
    debug_data        = 16'h0003;
    tick();
    debug_data_address = 8'h01;
    debug_data         = 16'h0005;
    tick();
    debug_data_write = 1'b0;

    repeat (20) begin
      tick();
      require(
        !bus_active && men_n && den_n && we_n && !program_write,
        $sformatf("family %0d reset keeps the native bus inactive", family)
      );
    end
    rs = 1'b0;
  endtask

  task automatic check_family_ownership(input int unsigned family);
    logic expected_read;
    logic expected_write;

    expected_read  = family_reads_data(family);
    expected_write = family_writes_data(family);
    require(
      phase == 2'd1 && bus_active &&
      !men_n && den_n && we_n && !program_write &&
      program_address == 12'h002 &&
      execute_valid && execute_address == 12'h001 &&
      execute_word == family_opcode(family) && !pipeline_blocked,
      $sformatf("family %0d overlaps its program fetch under MEN", family)
    );
    require(
      (data_read == expected_read) &&
      (data_write == expected_write) &&
      (data_address_valid == (expected_read || expected_write)),
      $sformatf("family %0d has exact logical RAM direction", family)
    );
    if (expected_read || expected_write) begin
      require(
        data_address == family_data_address(family),
        $sformatf("family %0d has the expected logical RAM address", family)
      );
    end
    if (expected_read) begin
      require(
        data_read_data == 16'h0003,
        $sformatf("family %0d sees the registered RAM source", family)
      );
    end
    require(
      data_write_address_valid == expected_write,
      $sformatf("family %0d has exact RAM-write validity", family)
    );
    if (expected_write) begin
      require(
        data_write_address == family_write_address(family),
        $sformatf("family %0d has the expected RAM-write address", family)
      );
    end
  endtask

  task automatic run_case(input int unsigned family);
    clear_program();
    program_memory[12'h000] = 16'h7f82;  // EINT
    program_memory[12'h001] = family_opcode(family);
    program_memory[12'h002] = 16'h7155;  // protected LARK AR1,0x55
    program_memory[12'h003] = 16'h7f89;  // nonexecuting dummy ZAC
    initialize_pipeline(family);

    advance_to_sample(family, "EINT prefetch");
    require(
      execute_valid && execute_address == 12'h000 &&
      execute_word == 16'h7f82 && !retired &&
      cycle_count == 32'd0 && program_address == 12'h001,
      $sformatf("family %0d first fetch primes EINT", family)
    );

    advance_to_sample(family, "EINT execution");
    require(
      retired && !illegal && execute_valid &&
      execute_address == 12'h001 &&
      execute_word == family_opcode(family) &&
      pc == 12'h001 && !interrupt_mask && !interrupt_pending &&
      cycle_count == 32'd1 && program_address == 12'h002,
      $sformatf("family %0d EINT captures the family word", family)
    );

    int_n = 1'b0;
    tick();
    require_exclusive_strobes(family);
    check_family_ownership(family);
    advance_to_sample(family, "family execution");
    int_n = 1'b1;
    require(
      retired && !illegal && execute_valid &&
      execute_address == 12'h002 && execute_word == 16'h7155 &&
      pc == 12'h002 && !interrupt_mask && interrupt_pending &&
      stack_top == 12'h000 && cycle_count == 32'd2 &&
      program_address == 12'h003 && !pipeline_blocked,
      $sformatf("family %0d retires before pending service", family)
    );

    tick();
    require_exclusive_strobes(family);
    require(
      phase == 2'd1 && !men_n && den_n && we_n && !program_write &&
      program_address == 12'h003 && execute_address == 12'h002 &&
      !data_read && !data_write && !data_address_valid,
      $sformatf("family %0d protected word overlaps the dummy read", family)
    );
    advance_to_sample(family, "protected instruction");
    require(
      retired && !illegal && !execute_valid &&
      auxiliary_register_1 == 16'h0055 && pc == 12'h003 &&
      interrupt_pending && !interrupt_mask &&
      cycle_count == 32'd3 && program_address == 12'h002,
      $sformatf("family %0d retires exactly one protected word", family)
    );

    tick();
    require_exclusive_strobes(family);
    require(
      phase == 2'd1 && !men_n && den_n && we_n && !program_write &&
      program_address == 12'h002 && !execute_valid &&
      !data_read && !data_write && !data_address_valid,
      $sformatf("family %0d fetches the vector in an empty slot", family)
    );
    advance_to_sample(family, "vector fetch");
    require(
      !retired && !illegal && execute_valid &&
      execute_address == 12'h002 && execute_word == 16'h7155 &&
      pc == 12'h002 && stack_top == 12'h003 &&
      stack_level_1 == 12'h000 && stack_level_2 == 12'h000 &&
      stack_bottom == 12'h000 && !interrupt_pending && interrupt_mask &&
      auxiliary_register_1 == 16'h0055 && cycle_count == 32'd4,
      $sformatf("family %0d acknowledges only at vector capture", family)
    );
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
      require(
        (family_opcode(family) != 16'h7f81) &&
        (family_opcode(family) != 16'h7f82),
        $sformatf("family %0d is not a separately tested mask control", family)
      );
      for (int unsigned prior = 0; prior < family; prior++) begin
        require(
          family_opcode(family) != family_opcode(prior),
          $sformatf("families %0d and %0d have distinct opcodes", prior, family)
        );
      end
      run_case(family);
    end

    $display(
      "PASS tb_sequential_pipeline_interrupt_one_cycle (39 arrival cases)"
    );
    $finish;
  end
endmodule

`default_nettype wire
