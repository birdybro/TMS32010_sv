`default_nettype none

module tb_sequential_pipeline_differential;
  localparam int unsigned ARCH_WIDTH = 210;

  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic [15:0] program_memory [0:4095];

  logic [11:0] legacy_program_address;
  logic [15:0] legacy_program_data;
  logic        legacy_sample;
  logic [11:0] legacy_pc;
  logic [31:0] legacy_accumulator;
  logic [15:0] legacy_t;
  logic [31:0] legacy_product;
  logic [15:0] legacy_ar0;
  logic [15:0] legacy_ar1;
  logic        legacy_arp;
  logic        legacy_dp;
  logic [11:0] legacy_stack_top;
  logic [11:0] legacy_stack_1;
  logic [11:0] legacy_stack_2;
  logic [11:0] legacy_stack_bottom;
  logic        legacy_ov;
  logic        legacy_ovm;
  logic        legacy_intm;
  logic        legacy_retired;
  logic        legacy_illegal;
  logic [31:0] legacy_cycle_count;

  logic [11:0] pipeline_program_address;
  logic [15:0] pipeline_program_data;
  logic        pipeline_sample;
  logic        pipeline_execute_valid;
  logic [11:0] pipeline_execute_address;
  logic [15:0] pipeline_execute_word;
  logic        pipeline_blocked;
  logic [11:0] pipeline_pc;
  logic [31:0] pipeline_accumulator;
  logic [15:0] pipeline_t;
  logic [31:0] pipeline_product;
  logic [15:0] pipeline_ar0;
  logic [15:0] pipeline_ar1;
  logic        pipeline_arp;
  logic        pipeline_dp;
  logic [11:0] pipeline_stack_top;
  logic [11:0] pipeline_stack_1;
  logic [11:0] pipeline_stack_2;
  logic [11:0] pipeline_stack_bottom;
  logic        pipeline_ov;
  logic        pipeline_ovm;
  logic        pipeline_intm;
  logic        pipeline_retired;
  logic        pipeline_illegal;
  logic [31:0] pipeline_cycle_count;

  logic [ARCH_WIDTH-1:0] legacy_architecture;
  logic [ARCH_WIDTH-1:0] pipeline_architecture;
  logic [ARCH_WIDTH-1:0] saved_legacy_architecture;

  assign legacy_program_data = program_memory[legacy_program_address];
  assign pipeline_program_data = program_memory[pipeline_program_address];
  assign legacy_architecture = {
    legacy_pc,
    legacy_accumulator,
    legacy_t,
    legacy_product,
    legacy_ar0,
    legacy_ar1,
    legacy_arp,
    legacy_dp,
    legacy_stack_top,
    legacy_stack_1,
    legacy_stack_2,
    legacy_stack_bottom,
    legacy_ov,
    legacy_ovm,
    legacy_intm,
    legacy_cycle_count,
    legacy_illegal
  };
  assign pipeline_architecture = {
    pipeline_pc,
    pipeline_accumulator,
    pipeline_t,
    pipeline_product,
    pipeline_ar0,
    pipeline_ar1,
    pipeline_arp,
    pipeline_dp,
    pipeline_stack_top,
    pipeline_stack_1,
    pipeline_stack_2,
    pipeline_stack_bottom,
    pipeline_ov,
    pipeline_ovm,
    pipeline_intm,
    pipeline_cycle_count,
    pipeline_illegal
  };

  tms32010_phase_slice legacy (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .rs_i                          (rs),
    .clock_enable_i                (clock_enable),
    .bio_i                         (1'b1),
    .int_i                         (1'b1),
    .program_data_i                (legacy_program_data),
    .io_read_data_i                (16'h0000),
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
    .phase_o                       (),
    .clkout_o                      (),
    .program_address_o             (legacy_program_address),
    .men_n_o                       (),
    .den_n_o                       (),
    .we_n_o                        (),
    .sample_o                      (legacy_sample),
    .bus_active_o                  (),
    .data_address_o                (),
    .data_read_o                   (),
    .data_write_o                  (),
    .data_address_valid_o          (),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .io_write_data_o               (),
    .program_write_o               (),
    .program_write_data_o          (),
    .pc_o                          (legacy_pc),
    .accumulator_o                 (legacy_accumulator),
    .t_register_o                  (legacy_t),
    .product_register_o            (legacy_product),
    .auxiliary_register_0_o        (legacy_ar0),
    .auxiliary_register_1_o        (legacy_ar1),
    .auxiliary_register_pointer_o  (legacy_arp),
    .data_page_pointer_o           (legacy_dp),
    .stack_top_o                    (legacy_stack_top),
    .stack_level_1_o                (legacy_stack_1),
    .stack_level_2_o                (legacy_stack_2),
    .stack_bottom_o                 (legacy_stack_bottom),
    .overflow_flag_o               (legacy_ov),
    .overflow_mode_o               (legacy_ovm),
    .interrupt_mask_o              (legacy_intm),
    .interrupt_pending_o           (),
    .instruction_valid_o           (),
    .retired_o                     (legacy_retired),
    .illegal_o                     (legacy_illegal),
    .cycle_count_o                 (legacy_cycle_count)
  );

  tms32010_sequential_pipeline_slice pipeline (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .rs_i                          (rs),
    .clock_enable_i                (clock_enable),
    .bio_i                         (1'b1),
    .program_data_i                (pipeline_program_data),
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
    .phase_o                       (),
    .clkout_o                      (),
    .program_address_o             (pipeline_program_address),
    .men_n_o                       (),
    .sample_o                      (pipeline_sample),
    .bus_active_o                  (),
    .execute_valid_o               (pipeline_execute_valid),
    .execute_address_o             (pipeline_execute_address),
    .execute_word_o                (pipeline_execute_word),
    .pipeline_blocked_o            (pipeline_blocked),
    .data_address_o                (),
    .data_read_o                   (),
    .data_write_o                  (),
    .data_address_valid_o          (),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (),
    .pc_o                          (pipeline_pc),
    .accumulator_o                 (pipeline_accumulator),
    .t_register_o                  (pipeline_t),
    .product_register_o            (pipeline_product),
    .auxiliary_register_0_o        (pipeline_ar0),
    .auxiliary_register_1_o        (pipeline_ar1),
    .auxiliary_register_pointer_o  (pipeline_arp),
    .data_page_pointer_o           (pipeline_dp),
    .stack_top_o                    (pipeline_stack_top),
    .stack_level_1_o                (pipeline_stack_1),
    .stack_level_2_o                (pipeline_stack_2),
    .stack_bottom_o                 (pipeline_stack_bottom),
    .overflow_flag_o               (pipeline_ov),
    .overflow_mode_o               (pipeline_ovm),
    .interrupt_mask_o              (pipeline_intm),
    .instruction_valid_o           (),
    .retired_o                     (pipeline_retired),
    .illegal_o                     (pipeline_illegal),
    .cycle_count_o                 (pipeline_cycle_count)
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

  task automatic advance_to_shared_sample;
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require(
        legacy_sample == pipeline_sample,
        "legacy and pipelined buses retain the same sample phase"
      );
      if (legacy_sample) begin
        return;
      end
    end
    $fatal(1, "shared sample event did not arrive");
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h7012;  // LARK AR0,0x12
    program_memory[1]  = 16'h7134;  // LARK AR1,0x34
    program_memory[2]  = 16'h6881;  // LARP 1
    program_memory[3]  = 16'h6e01;  // LDPK 1
    program_memory[4]  = 16'h7f8b;  // SOVM
    program_memory[5]  = 16'h7f8a;  // ROVM
    program_memory[6]  = 16'h7f8b;  // SOVM
    program_memory[7]  = 16'h7ea5;  // LACK 0xa5
    program_memory[8]  = 16'h7f89;  // ZAC
    program_memory[9]  = 16'h7f80;  // NOP
    program_memory[10] = 16'h2403;  // LAC 3,4
    program_memory[11] = 16'h5004;  // SACL 4
    program_memory[12] = 16'h5c05;  // SACH 5,4
    program_memory[13] = 16'h6503;  // ZALH 3
    program_memory[14] = 16'h6603;  // ZALS 3
    program_memory[15] = 16'h6103;  // ADDS 3
    program_memory[16] = 16'h7803;  // XOR 3
    program_memory[17] = 16'h7903;  // AND 3
    program_memory[18] = 16'h7a03;  // OR 3
    program_memory[19] = 16'h0003;  // ADD 3,0
    program_memory[20] = 16'h1003;  // SUB 3,0
    program_memory[21] = 16'h6303;  // SUBS 3
    program_memory[22] = 16'h3803;  // LAR AR0,3
    program_memory[23] = 16'h3004;  // SAR AR0,4
    program_memory[24] = 16'h6890;  // MAR *-,AR0
    program_memory[25] = 16'h6f03;  // LDP 3
    program_memory[26] = 16'h6a03;  // LT 3
    program_memory[27] = 16'h6d04;  // MPY 4
    program_memory[28] = 16'h9ff7;  // MPYK -9
    program_memory[29] = 16'h7f8e;  // PAC
    program_memory[30] = 16'h7f8f;  // APAC
    program_memory[31] = 16'h7f90;  // SPAC
    program_memory[32] = 16'h6c03;  // LTA 3
    program_memory[33] = 16'h6b03;  // LTD 3
    program_memory[34] = 16'h6904;  // DMOV 4
    program_memory[35] = 16'h7f82;  // EINT
    program_memory[36] = 16'h7f80;  // instruction following EINT
    program_memory[37] = 16'h7f81;  // DINT
    program_memory[38] = 16'h7b03;  // LST 3
    program_memory[39] = 16'h6e00;  // LDPK 0
    program_memory[40] = 16'h6400;  // SUBC 0
    program_memory[41] = 16'h7f80;  // required ACC-free instruction
    program_memory[42] = 16'h6203;  // SUBH 3
    program_memory[43] = 16'hf800;  // unsupported CALL boundary

    initialize         = 1'b1;
    rs                 = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'h83;
    debug_data         = 16'hff80;
    tick();
    debug_data_address = 8'h03;
    debug_data         = 16'hbeef;
    tick();
    debug_data_address = 8'h00;
    debug_data         = 16'h0007;
    tick();
    debug_data_address = 8'h04;
    debug_data         = 16'h0002;
    tick();
    debug_data_write = 1'b0;
    initialize = 1'b0;

    repeat (20) begin
      tick();
    end
    rs = 1'b0;

    advance_to_shared_sample();
    require(
      legacy_retired &&
      !pipeline_retired &&
      pipeline_execute_valid &&
      pipeline_execute_address == 12'h000 &&
      pipeline_program_address == 12'h001,
      "first shared fetch retires legacy word zero and primes pipeline word zero"
    );
    saved_legacy_architecture = legacy_architecture;

    for (int unsigned retirement = 1; retirement <= 43; retirement++) begin
      advance_to_shared_sample();
      require(pipeline_retired, "each qualified pipeline word retires");
      require(
        pipeline_architecture == saved_legacy_architecture,
        "pipelined state matches the prior qualified legacy retirement"
      );
      require(
        pipeline_cycle_count == retirement &&
        pipeline_pc == retirement[11:0],
        "pipeline retirement count and execute PC remain aligned"
      );
      require(
        pipeline_execute_address == retirement[11:0] &&
        pipeline_program_address == (retirement[11:0] + 12'h001),
        "execute and fetch addresses remain one word apart"
      );

      if (retirement < 43) begin
        require(legacy_retired, "legacy oracle retires the next qualified word");
        saved_legacy_architecture = legacy_architecture;
      end
    end

    require(
      pipeline_blocked &&
      pipeline_execute_word == 16'hf800 &&
      !pipeline_illegal,
      "pipeline parks on unsupported CALL without executing it"
    );
    require(
      !legacy_illegal &&
      !legacy_retired &&
      legacy_cycle_count == 32'd44,
      "legacy slice enters qualified branch cycle one without retirement"
    );

    $display("PASS tb_sequential_pipeline_differential");
    $finish;
  end
endmodule

`default_nettype wire
