`default_nettype none

module tb_table_transfers_rtl;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic [11:0] program_address;
  logic        program_read;
  logic        program_write;
  logic [15:0] program_write_data;
  logic [15:0] program_data;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
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
    .int_i                         (1'b1),
    .program_address_o             (program_address),
    .program_next_address_o        (),
    .program_read_o                (program_read),
    .program_write_o               (program_write),
    .program_write_data_o          (program_write_data),
    .program_data_i                (program_data),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .io_write_data_o               (),
    .io_read_data_i                (16'h0000),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (),
    .data_write_address_o          (),
    .data_write_address_valid_o    (),
    .data_read_data_o              (),
    .data_write_data_o             (data_write_data),
    .debug_data_write_i            (1'b0),
    .debug_data_address_i          (8'h00),
    .debug_data_i                  (16'h0000),
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
    .instruction_valid_o           (instruction_valid),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
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

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'hf800;
    program_memory[1]  = 16'h0002;
    program_memory[2]  = 16'hf800;
    program_memory[3]  = 16'h0004;
    program_memory[4]  = 16'hf800;
    program_memory[5]  = 16'h0006;
    program_memory[6]  = 16'hf800;
    program_memory[7]  = 16'h0008;
    program_memory[8]  = 16'h7e20;
    program_memory[9]  = 16'h6705;
    program_memory[10] = 16'h7e21;
    program_memory[11] = 16'h7d05;
    program_memory[12] = 16'h7006;
    program_memory[13] = 16'h6880;
    program_memory[14] = 16'h7e20;
    program_memory[15] = 16'h67a1;
    program_memory[16] = 16'h7f80;
    program_memory[17] = 16'h6e01;
    program_memory[18] = 16'h6710;
    program_memory[32] = 16'hbeef;
    program_memory[33] = 16'haaaa;

    initialize   = 1'b1;
    reset        = 1'b1;
    clock_enable = 1'b1;
    tick();
    initialize = 1'b0;
    tick();
    reset = 1'b0;

    repeat (8) tick();
    require(
      pc == 12'd8 && cycle_count == 32'd8 &&
      {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
        {12'd8, 12'd6, 12'd4, 12'd2},
      "four CALLs establish distinct stack entries"
    );
    tick();
    require(retired && accumulator == 32'h0000_0020 && pc == 12'd9,
            "LACK establishes the TBLR program address");

    tick();
    require(!retired && !illegal && pc == 12'd10 &&
            cycle_count == 32'd10 && program_read && !program_write &&
            program_address == 12'd10 && !data_read && !data_write,
            "TBLR opcode starts the documented discarded prefetch");

    clock_enable = 1'b0;
    repeat (2) begin
      tick();
      require(program_read && program_address == 12'd10 &&
              cycle_count == 32'd10 && !retired,
              "stalled TBLR holds its discarded-prefetch cycle");
    end
    clock_enable = 1'b1;
    tick();
    require(!retired && program_read && !program_write &&
            program_address == 12'h020 &&
            data_write && !data_read && data_address == 8'd5 &&
            data_write_data == 16'hbeef &&
            cycle_count == 32'd11,
            "TBLR third cycle reads ACC address and presents RAM write");

    clock_enable = 1'b0;
    tick();
    require(program_read && program_address == 12'h020 &&
            data_write && data_write_data == 16'hbeef && !retired,
            "stalled TBLR table phase holds address and sampled-data path");
    clock_enable = 1'b1;
    tick();
    require(retired && pc == 12'd10 && cycle_count == 32'd12 &&
            {stack_top, stack_level_1, stack_level_2, stack_bottom} ==
              {12'd8, 12'd6, 12'd4, 12'd4},
            "TBLR retires in three cycles and duplicates old stack level 2");

    tick();
    require(retired && pc == 12'd11 && accumulator == 32'h0000_0021,
            "discarded following word is fetched and executed again");
    tick();
    require(!retired && pc == 12'd12 && program_read &&
            program_address == 12'd12 && !program_write,
            "TBLW opcode starts the discarded prefetch");
    tick();
    require(!retired && !program_read && program_write &&
            program_address == 12'h021 &&
            program_write_data == 16'hbeef &&
            data_read && !data_write && data_address == 8'd5,
            "TBLW third cycle drives selected RAM word under program write");

    clock_enable = 1'b0;
    repeat (2) begin
      tick();
      require(program_write && program_address == 12'h021 &&
              program_write_data == 16'hbeef && !retired,
              "stalled TBLW holds address, write data, and operation");
    end
    clock_enable = 1'b1;
    program_memory[33] = program_write_data;
    tick();
    require(retired && pc == 12'd12 && cycle_count == 32'd16 &&
            program_memory[33] == 16'hbeef,
            "TBLW retires after three enabled cycles");

    repeat (3) tick();
    require(pc == 12'd15 && auxiliary_register_0 == 16'd6 &&
            !auxiliary_register_pointer &&
            accumulator == 32'h0000_0020,
            "following setup instructions execute after repeated prefetch");
    tick();
    require(!retired && program_address == 12'd16 && program_read,
            "indirect TBLR begins with old AR selected");
    tick();
    require(!retired && program_address == 12'h020 &&
            data_write && data_address == 8'd6,
            "indirect TBLR table cycle uses old AR address");
    tick();
    require(retired && auxiliary_register_0 == 16'd7 &&
            auxiliary_register_1 == 16'd0 &&
            auxiliary_register_pointer,
            "indirect TBLR post-increments old AR and selects next ARP");

    repeat (2) tick();
    require(pc == 12'd18 && cycle_count == 32'd24,
            "following NOP and LDPK retire normally");
    require(!instruction_valid && program_read && !program_write,
            "unresolved TBLR address cannot enter its discarded prefetch");
    tick();
    require(illegal && !retired && pc == 12'd18 &&
            cycle_count == 32'd24,
            "unresolved TBLR traps before external table or stack effects");

    $display("PASS tb_table_transfers_rtl");
    $finish;
  end
endmodule

`default_nettype wire
