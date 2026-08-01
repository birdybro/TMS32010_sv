`default_nettype none

module tb_interrupt_multicycle_arrivals;
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
  logic        reset;
  logic        clock_enable;
  logic        int_n;
  logic [11:0] program_address;
  logic [11:0] program_next_address;
  logic        program_read;
  logic        program_write;
  logic [15:0] program_write_data;
  logic [15:0] program_data;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic [15:0] io_write_data;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [7:0]  data_write_address;
  logic        data_write_address_valid;
  logic [15:0] data_read_data;
  logic [15:0] data_write_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] auxiliary_register_0;
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
    .program_write_data_o          (program_write_data),
    .program_data_i                (program_data),
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (io_write_data),
    .io_read_data_i                (16'hcafe),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (data_write_address),
    .data_write_address_valid_o    (data_write_address_valid),
    .data_read_data_o              (data_read_data),
    .data_write_data_o             (data_write_data),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
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

  task automatic clear_program;
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
  endtask

  task automatic initialize_core;
    initialize   = 1'b1;
    reset        = 1'b0;
    clock_enable = 1'b1;
    int_n        = 1'b1;
    tick();
    initialize = 1'b0;
    require(
      pc == 12'h000 && interrupt_mask && !interrupt_pending &&
      stack_top == 12'h000 && stack_level_1 == 12'h000 &&
      stack_level_2 == 12'h000 && stack_bottom == 12'h000,
      "initialization establishes deterministic matrix state"
    );
  endtask

  task automatic prepare_case(input int unsigned family);
    clear_program();
    program_memory[0] = 16'h7f82;  // EINT
    program_memory[1] = family_opcode(family);
    if (family_is_control(family)) begin
      program_memory[2]      = 16'h0010;  // canonical target operand
      program_memory[3]      = 16'h7e44;  // fall-through protected LACK
      program_memory[4]      = 16'h7f89;  // fall-through dummy ZAC
      program_memory[12'h010] = 16'h7e44;  // taken protected LACK
      program_memory[12'h011] = 16'h7f89;  // taken dummy ZAC
    end else begin
      program_memory[2] = 16'h7e44;  // protected LACK
      program_memory[3] = 16'h7f89;  // dummy ZAC
    end
  endtask

  task automatic check_idle_instruction_bus(
    input int unsigned family
  );
    require(
      instruction_valid && program_read && !program_write &&
      !io_read && !io_write && !data_read && !data_write &&
      program_address == 12'h001 && program_next_address == 12'h002,
      $sformatf("family %0d opcode cycle has an ordinary fetch", family)
    );
  endtask

  task automatic check_pending_bus(
    input int unsigned family,
    input int unsigned phase
  );
    if (family_is_control(family)) begin
      require(
        phase == 1 && instruction_valid && program_read && !program_write &&
        !io_read && !io_write && !data_read && !data_write &&
        program_address == 12'h002,
        $sformatf("family %0d control operand cycle shape", family)
      );
    end else if (family == FAMILY_IN) begin
      require(
        phase == 1 && instruction_valid && !program_read && !program_write &&
        io_read && !io_write && io_port == 3'd2,
        "IN external transfer strobe shape"
      );
      require(
        !data_read && data_write && data_address == 8'h03 &&
        data_address_valid && data_write_address == 8'h03 &&
        data_write_address_valid && data_write_data == 16'hcafe,
        "IN internal RAM transfer shape"
      );
    end else if (family == FAMILY_OUT) begin
      require(
        phase == 1 && instruction_valid && !program_read && !program_write &&
        !io_read && io_write && io_port == 3'd7,
        "OUT external transfer strobe shape"
      );
      require(
        data_read && !data_write && data_address == 8'h03 &&
        data_address_valid && io_write_data == data_read_data,
        "OUT internal RAM transfer shape"
      );
    end else if (phase == 1) begin
      require(
        instruction_valid && program_read && !program_write &&
        !io_read && !io_write && !data_read && !data_write &&
        program_address == 12'h002,
        $sformatf("family %0d discarded prefetch cycle shape", family)
      );
    end else if (family == FAMILY_TBLR) begin
      require(
        phase == 2 && instruction_valid && program_read && !program_write &&
        !io_read && !io_write && !data_read && data_write &&
        program_address == 12'h000 && data_address == 8'h00 &&
        data_address_valid && data_write_address == 8'h00 &&
        data_write_address_valid && data_write_data == 16'h7f82,
        "TBLR transfer cycle shape"
      );
    end else begin
      require(
        family == FAMILY_TBLW && phase == 2 &&
        instruction_valid && !program_read && program_write &&
        program_write_data == data_read_data &&
        !io_read && !io_write && data_read && !data_write &&
        program_address == 12'h000 && data_address == 8'h00 &&
        data_address_valid,
        "TBLW transfer cycle shape"
      );
    end
  endtask

  task automatic run_case(
    input int unsigned family,
    input int unsigned arrival_phase
  );
    int unsigned machine_cycles;
    logic [11:0] following_pc;
    logic [11:0] return_pc;

    machine_cycles = family_cycles(family);
    following_pc =
      family_is_control(family) && family_is_taken(family)
        ? 12'h010
        : (family_is_control(family) ? 12'h003 : 12'h002);
    return_pc = following_pc + 12'h001;

    prepare_case(family);
    initialize_core();

    tick();
    require(
      retired && !illegal && pc == 12'h001 &&
      !interrupt_mask && !interrupt_pending && cycle_count == 32'd1,
      $sformatf("family %0d request-free EINT retires", family)
    );

    for (int unsigned phase = 0; phase < machine_cycles; phase++) begin
      if (phase == 0) begin
        check_idle_instruction_bus(family);
      end else begin
        check_pending_bus(family, phase);
      end

      int_n = (phase == arrival_phase) ? 1'b0 : 1'b1;
      tick();
      int_n = 1'b1;

      require(
        !illegal &&
        (interrupt_pending == (phase >= arrival_phase)) &&
        !interrupt_mask &&
        cycle_count == (32'd2 + phase),
        $sformatf(
          "family %0d arrival %0d has expected latch state after phase %0d",
          family,
          arrival_phase,
          phase
        )
      );
      if ((phase + 1) < machine_cycles) begin
        require(
          !retired && stack_top == 12'h000,
          $sformatf(
            "family %0d arrival %0d cannot enter midinstruction",
            family,
            arrival_phase
          )
        );
      end else begin
        require(
          retired && pc == following_pc,
          $sformatf(
            "family %0d arrival %0d completes before deferral",
            family,
            arrival_phase
          )
        );
      end
    end

    if (family == FAMILY_BANZ) begin
      require(
        auxiliary_register_0 == 16'h01ff,
        "BANZ decrements low nine AR0 bits before interrupt entry"
      );
    end
    if (family == FAMILY_CALL) begin
      require(
        stack_top == 12'h003 && stack_level_1 == 12'h000,
        "CALL pushes its own return address before interrupt entry"
      );
    end else begin
      require(
        stack_top == 12'h000,
        $sformatf("family %0d has not entered during execution", family)
      );
    end

    require(
      instruction_valid && program_read && !program_write &&
      !io_read && !io_write && !data_read && !data_write &&
      program_address == following_pc,
      $sformatf("family %0d presents exactly one protected instruction", family)
    );
    tick();
    require(
      retired && !illegal && pc == return_pc &&
      accumulator == 32'h0000_0044 && interrupt_pending &&
      !interrupt_mask && !instruction_valid &&
      cycle_count == (32'd2 + machine_cycles),
      $sformatf(
        "family %0d arrival %0d retires one protected instruction",
        family,
        arrival_phase
      )
    );
    require(
      program_read && !program_write && !io_read && !io_write &&
      !data_read && !data_write &&
      program_address == return_pc && program_next_address == 12'h002,
      $sformatf("family %0d presents a nonretiring dummy fetch", family)
    );

    tick();
    require(
      !retired && !illegal && pc == 12'h002 &&
      stack_top == return_pc && interrupt_mask && !interrupt_pending &&
      accumulator == 32'h0000_0044 &&
      cycle_count == (32'd3 + machine_cycles),
      $sformatf(
        "family %0d arrival %0d stacks resolved PC and selects vector 2",
        family,
        arrival_phase
      )
    );
    if (family == FAMILY_CALL) begin
      require(
        stack_level_1 == 12'h003 && stack_level_2 == 12'h000 &&
        stack_bottom == 12'h000,
        "interrupt entry preserves CALL return below interrupt return"
      );
    end else begin
      require(
        stack_level_1 == 12'h000 && stack_level_2 == 12'h000 &&
        stack_bottom == 12'h000,
        $sformatf("family %0d entry shifts the initialized stack", family)
      );
    end
  endtask

  initial begin
    initialize   = 1'b0;
    reset        = 1'b0;
    clock_enable = 1'b1;
    int_n        = 1'b1;

    for (int unsigned family = 0; family < FAMILY_COUNT; family++) begin
      for (
        int unsigned arrival_phase = 0;
        arrival_phase < family_cycles(family);
        arrival_phase++
      ) begin
        run_case(family, arrival_phase);
      end
    end

    $display("PASS tb_interrupt_multicycle_arrivals (32 arrival cases)");
    $finish;
  end
endmodule

`default_nettype wire
