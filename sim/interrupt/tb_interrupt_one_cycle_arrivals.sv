`default_nettype none

module tb_interrupt_one_cycle_arrivals;
  localparam int unsigned FAMILY_COUNT = 39;

  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic        int_n;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic        program_read;
  logic        program_write;
  logic [15:0] program_data;
  logic        io_read;
  logic        io_write;
  logic        data_read;
  logic        data_write;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic [11:0] pc;
  logic [15:0] auxiliary_register_1;
  logic [11:0] stack_top;
  logic [11:0] stack_level_1;
  logic [11:0] stack_level_2;
  logic [11:0] stack_bottom;
  logic        interrupt_mask;
  logic        interrupt_pending;
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_core dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .reset_i                       (reset),
    .clock_enable_i                (clock_enable),
    .internal_ram_read_enable_i    (clock_enable),
    .bio_i                         (1'b1),
    .int_i                         (int_n),
    .program_address_o             (program_address),
    .program_next_address_o        (program_next_address),
    .program_read_o                (program_read),
    .program_write_o               (program_write),
    .program_write_data_o          (),
    .program_data_i                (program_data),
    .io_port_o                     (),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (),
    .io_read_data_i                (16'h0000),
    .data_address_o                (),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
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
    .instruction_valid_o           (instruction_valid),
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

  task automatic tick;
    @(posedge clk);
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  task automatic clear_program;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
  endtask

  task automatic initialize_core;
    initialize        = 1'b1;
    reset             = 1'b0;
    clock_enable      = 1'b1;
    int_n             = 1'b1;
    debug_data_write  = 1'b0;
    debug_data_address = 8'h00;
    debug_data        = 16'h0000;
    tick();
    initialize   = 1'b0;
    clock_enable = 1'b0;
    debug_data_write = 1'b1;
    debug_data        = 16'h0003;
    tick();
    debug_data_address = 8'h01;
    debug_data         = 16'h0005;
    tick();
    debug_data_write = 1'b0;
    clock_enable     = 1'b1;
    require(
      pc == 12'h000 && interrupt_mask && !interrupt_pending &&
      stack_top == 12'h000 && stack_level_1 == 12'h000 &&
      stack_level_2 == 12'h000 && stack_bottom == 12'h000,
      "initialization establishes deterministic matrix state"
    );
  endtask

  task automatic run_case(input int unsigned family);
    clear_program();
    program_memory[0] = 16'h7f82;          // EINT
    program_memory[1] = family_opcode(family);
    program_memory[2] = 16'h7155;          // protected LARK AR1,0x55
    program_memory[3] = 16'h7f89;          // nonexecuting dummy ZAC
    initialize_core();

    tick();
    require(
      retired && !illegal && pc == 12'h001 && !interrupt_mask &&
      !interrupt_pending && cycle_count == 32'd1,
      $sformatf("family %0d request-free EINT retires", family)
    );
    require(
      instruction_valid && program_read && !program_write &&
      !io_read && !io_write && program_address == 12'h001 &&
      program_next_address == 12'h002,
      $sformatf("family %0d owns an ordinary one-cycle fetch", family)
    );

    int_n = 1'b0;
    tick();
    int_n = 1'b1;
    require(
      retired && !illegal && pc == 12'h002 && !interrupt_mask &&
      interrupt_pending && cycle_count == 32'd2 &&
      stack_top == 12'h000,
      $sformatf("family %0d retires while latching the request", family)
    );
    require(
      instruction_valid && program_read && !program_write &&
      !io_read && !io_write && !data_read && !data_write &&
      program_address == 12'h002 && program_next_address == 12'h003,
      $sformatf("family %0d presents one protected instruction", family)
    );

    tick();
    require(
      retired && !illegal && pc == 12'h003 &&
      auxiliary_register_1 == 16'h0055 && interrupt_pending &&
      !interrupt_mask && !instruction_valid && cycle_count == 32'd3,
      $sformatf("family %0d retires exactly one protected word", family)
    );
    require(
      program_read && !program_write && !io_read && !io_write &&
      !data_read && !data_write && program_address == 12'h003 &&
      program_next_address == 12'h002,
      $sformatf("family %0d presents the return-PC dummy fetch", family)
    );

    tick();
    require(
      !retired && !illegal && pc == 12'h002 && stack_top == 12'h003 &&
      stack_level_1 == 12'h000 && stack_level_2 == 12'h000 &&
      stack_bottom == 12'h000 && interrupt_mask &&
      !interrupt_pending && auxiliary_register_1 == 16'h0055 &&
      cycle_count == 32'd4,
      $sformatf("family %0d enters only after protected retirement", family)
    );
  endtask

  initial begin
    initialize         = 1'b0;
    reset              = 1'b0;
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

    $display("PASS tb_interrupt_one_cycle_arrivals (39 arrival cases)");
    $finish;
  end
endmodule

`default_nettype wire
