`default_nettype none

module tb_phase_slice_integration;
  logic        clk;
  logic        initialize;
  logic        rs;
  logic        clock_enable;
  logic [15:0] program_data;
  logic [1:0]  phase;
  logic        clkout;
  logic [11:0] program_address;
  logic        men_n;
  logic        sample;
  logic        bus_active;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [15:0] data_read_data;
  logic [15:0] data_write_data;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic [15:0] t_register;
  logic [31:0] product_register;
  logic [15:0] auxiliary_register_0;
  logic [15:0] auxiliary_register_1;
  logic        auxiliary_register_pointer;
  logic        data_page_pointer;
  logic        overflow_flag;
  logic        overflow_mode;
  logic        interrupt_mask;
  logic        instruction_valid;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;
  logic [15:0] program_memory [0:4095];

  tms32010_phase_slice dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .rs_i                          (rs),
    .clock_enable_i                (clock_enable),
    .program_data_i                (program_data),
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .program_address_o             (program_address),
    .men_n_o                       (men_n),
    .sample_o                      (sample),
    .bus_active_o                  (bus_active),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_read_data_o              (data_read_data),
    .data_write_data_o             (data_write_data),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (t_register),
    .product_register_o            (product_register),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (data_page_pointer),
    .overflow_flag_o               (overflow_flag),
    .overflow_mode_o               (overflow_mode),
    .interrupt_mask_o              (interrupt_mask),
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

  task automatic advance_to_sample;
    for (int unsigned elapsed = 0; elapsed < 16; elapsed++) begin
      tick();
      require(clkout == phase[1], "CLKOUT follows native phase encoding");
      if (sample) begin
        return;
      end
    end
    $fatal(1, "sample event did not arrive");
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0] = 16'h7012;  // LARK AR0,0x12
    program_memory[1] = 16'h7134;  // LARK AR1,0x34
    program_memory[2] = 16'h6881;  // LARP 1
    program_memory[3] = 16'h6e01;  // LDPK 1
    program_memory[4] = 16'h7f8b;  // SOVM
    program_memory[5] = 16'h7f8a;  // ROVM
    program_memory[6] = 16'h7f8b;  // SOVM
    program_memory[7] = 16'h7ea5;  // LACK 0xa5
    program_memory[8] = 16'h7f89;  // ZAC
    program_memory[9] = 16'h7f80;  // NOP
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
    program_memory[30] = 16'h7f81;  // unsupported and not a silent NOP

    initialize   = 1'b1;
    rs           = 1'b1;
    clock_enable = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'h83;
    debug_data         = 16'hff80;
    tick();
    debug_data_address = 8'h03;
    debug_data         = 16'hbeef;
    tick();
    debug_data_address = 8'h04;
    debug_data         = 16'h0002;
    tick();
    debug_data_write = 1'b0;
    initialize = 1'b0;
    require(!overflow_flag, "explicit initialization clears OV");

    for (int unsigned index = 0; index < 20; index++) begin
      tick();
      require(!bus_active && men_n, "reset keeps native bus inactive");
    end
    require(pc == 12'h000 && interrupt_mask, "reset establishes control state");

    rs = 1'b0;
    advance_to_sample();
    require(sample && retired, "first falling boundary retires LARK");
    require(program_address == 12'h001, "native bus advances from 0 to 1");
    require(pc == 12'h001, "architectural PC advances with native address");
    require(auxiliary_register_0 == 16'h0012, "sampled LARK updates AR0");
    require(cycle_count == 32'd1, "one native cycle retires one instruction");

    // Stop in the active MEN phase. All bus pins and architectural state hold.
    tick();
    require(phase == 2'd1 && !men_n && !retired, "entered active read phase");
    clock_enable = 1'b0;
    logic_stall_check: begin
      logic [1:0] saved_phase;
      logic [11:0] saved_address;
      saved_phase   = phase;
      saved_address = program_address;
      for (int unsigned index = 0; index < 3; index++) begin
        tick();
        require(phase == saved_phase, "clock enable holds native phase");
        require(program_address == saved_address, "clock enable holds address");
        require(!retired && !sample, "stall cannot retire or sample");
      end
    end

    clock_enable = 1'b1;
    advance_to_sample();
    require(retired && auxiliary_register_1 == 16'h0034,
            "second LARK updates AR1");
    require(pc == 12'h002 && program_address == 12'h002,
            "second sample advances PC and bus together");

    advance_to_sample();
    require(retired && auxiliary_register_pointer, "LARP selects AR1");
    require(pc == 12'h003, "LARP sample advances PC");

    advance_to_sample();
    require(retired && data_page_pointer, "LDPK selects page one");
    require(pc == 12'h004, "LDPK sample advances PC");

    advance_to_sample();
    require(retired && overflow_mode, "SOVM sets overflow mode");
    require(pc == 12'h005, "SOVM sample advances PC");

    advance_to_sample();
    require(retired && !overflow_mode, "ROVM clears overflow mode");
    require(pc == 12'h006, "ROVM sample advances PC");

    advance_to_sample();
    require(retired && overflow_mode, "second SOVM restores overflow mode");
    require(pc == 12'h007, "second SOVM sample advances PC");

    advance_to_sample();
    require(retired, "LACK retires on eighth sample");
    require(accumulator == 32'h0000_00a5, "LACK consumes sampled program word");
    require(pc == 12'h008 && cycle_count == 32'd8,
            "eight samples retire eight instructions");

    advance_to_sample();
    require(retired && accumulator == 32'h0000_0000,
            "ZAC retires and clears the accumulator");
    require(pc == 12'h009, "ZAC sample advances PC");

    advance_to_sample();
    require(retired && accumulator == 32'h0000_0000,
            "NOP retires without changing the accumulator");
    require(pc == 12'h00a && cycle_count == 32'd10,
            "NOP consumes one native instruction cycle");
    require(data_read && data_address_valid && data_address == 8'h83,
            "LAC concatenates DP with its direct address");
    require(data_read_data == 16'hff80, "LAC sees preloaded internal word");

    advance_to_sample();
    require(retired, "LAC retires on eleventh sample");
    require(accumulator == 32'hffff_f800, "LAC sign extends and shifts");
    require(pc == 12'h00b && cycle_count == 32'd11,
            "LAC consumes one native instruction cycle");
    require(data_write && data_address_valid && data_address == 8'h84,
            "SACL exposes its internal write during a normal program read");
    require(data_write_data == 16'hf800, "SACL exposes ACC low write data");
    tick();
    require(phase == 2'd1 && !men_n && data_write,
            "SACL logical write overlaps an ordinary active MEN phase");

    advance_to_sample();
    require(retired && accumulator == 32'hffff_f800,
            "SACL retires without modifying the accumulator");
    require(pc == 12'h00c && cycle_count == 32'd12,
            "SACL consumes one native instruction cycle");
    require(data_write && data_address_valid && data_address == 8'h85,
            "SACH exposes its internal write during a normal program read");
    require(data_write_data == 16'hffff,
            "SACH output shifter feeds logical write data");

    advance_to_sample();
    require(retired && accumulator == 32'hffff_f800,
            "SACH retires without modifying the accumulator");
    require(pc == 12'h00d && cycle_count == 32'd13,
            "SACH consumes one native instruction cycle");
    require(data_read && !data_write && data_address_valid &&
            data_address == 8'h83 && data_read_data == 16'hff80,
            "ZALH exposes the page-one logical read beside program phases");

    advance_to_sample();
    require(retired && accumulator == 32'hff80_0000,
            "ZALH transfers the sampled word to the accumulator high half");
    require(pc == 12'h00e && cycle_count == 32'd14,
            "ZALH consumes one native instruction cycle");
    require(data_read && !data_write && data_address == 8'h83,
            "ZALS exposes a logical read without changing MEN sequencing");

    advance_to_sample();
    require(retired && accumulator == 32'h0000_ff80,
            "ZALS zero-extends the sampled word in the low half");
    require(pc == 12'h00f && cycle_count == 32'd15,
            "ZALS consumes one native instruction cycle");
    require(data_read && !data_write && data_address_valid &&
            data_address == 8'h83 && data_read_data == 16'hff80,
            "ADDS presents its unsigned internal operand beside program phases");

    advance_to_sample();
    require(retired && accumulator == 32'h0001_ff00,
            "ADDS adds an unsigned word to the full accumulator");
    require(!overflow_flag,
            "nonoverflowing ADDS preserves the initialized clear OV flag");
    require(pc == 12'h010 && cycle_count == 32'd16,
            "ADDS consumes one native instruction cycle");
    require(data_read && !data_write && data_address_valid &&
            data_address == 8'h83 && data_read_data == 16'hff80,
            "XOR presents its internal operand beside program phases");

    advance_to_sample();
    require(retired && accumulator == 32'h0001_0080,
            "XOR changes only the low accumulator half");
    require(!overflow_flag && overflow_mode,
            "XOR preserves arithmetic status");
    require(pc == 12'h011 && cycle_count == 32'd17,
            "XOR consumes one native instruction cycle");
    require(data_read && !data_write && data_address == 8'h83,
            "AND presents its internal operand beside program phases");

    advance_to_sample();
    require(retired && accumulator == 32'h0000_0080,
            "AND clears the high half while masking the low half");
    require(!overflow_flag && overflow_mode,
            "AND preserves arithmetic status");
    require(pc == 12'h012 && cycle_count == 32'd18,
            "AND consumes one native instruction cycle");
    require(data_read && !data_write && data_address == 8'h83,
            "OR presents its internal operand beside program phases");

    advance_to_sample();
    require(retired && accumulator == 32'h0000_ff80,
            "OR preserves the high half while combining the low half");
    require(!overflow_flag && overflow_mode,
            "OR preserves arithmetic status");
    require(pc == 12'h013 && cycle_count == 32'd19,
            "OR consumes one native instruction cycle");
    require(data_read && !data_write && data_address == 8'h83,
            "ADD presents its internal operand beside program phases");

    advance_to_sample();
    require(retired && accumulator == 32'h0000_ff00,
            "ADD sign extends its data word before accumulation");
    require(!overflow_flag && overflow_mode,
            "nonoverflowing ADD preserves arithmetic status");
    require(pc == 12'h014 && cycle_count == 32'd20,
            "ADD consumes one native instruction cycle");
    require(data_read && !data_write && data_address == 8'h83,
            "SUB presents its internal operand beside program phases");

    advance_to_sample();
    require(retired && accumulator == 32'h0000_ff80,
            "SUB sign extends its data word before subtraction");
    require(!overflow_flag && overflow_mode,
            "nonoverflowing SUB preserves arithmetic status");
    require(pc == 12'h015 && cycle_count == 32'd21,
            "SUB consumes one native instruction cycle");
    require(data_read && !data_write && data_address == 8'h83,
            "SUBS presents its internal operand beside program phases");

    advance_to_sample();
    require(retired && accumulator == 32'h0000_0000,
            "SUBS treats its data word as unsigned");
    require(!overflow_flag && overflow_mode,
            "nonoverflowing SUBS preserves arithmetic status");
    require(pc == 12'h016 && cycle_count == 32'd22,
            "SUBS consumes one native instruction cycle");
    require(data_read && !data_write && data_address == 8'h83,
            "LAR presents its internal operand beside program phases");

    advance_to_sample();
    require(retired && auxiliary_register_0 == 16'hff80,
            "LAR loads the complete internal word into AR0");
    require(!overflow_flag && overflow_mode,
            "LAR preserves arithmetic status");
    require(pc == 12'h017 && cycle_count == 32'd23,
            "LAR consumes one native instruction cycle");
    require(!data_read && data_write && data_address == 8'h84 &&
            data_write_data == 16'hff80,
            "SAR presents its internal write beside program phases");

    advance_to_sample();
    require(retired && auxiliary_register_0 == 16'hff80,
            "direct SAR preserves its auxiliary-register source");
    require(!overflow_flag && overflow_mode,
            "SAR preserves arithmetic status");
    require(pc == 12'h018 && cycle_count == 32'd24,
            "SAR consumes one native instruction cycle");
    require(!data_read && !data_write && !data_address_valid,
            "MAR performs no logical data-memory transaction");

    advance_to_sample();
    require(retired && auxiliary_register_1 == 16'h0033 &&
            !auxiliary_register_pointer,
            "MAR updates the selected AR before replacing ARP");
    require(!overflow_flag && overflow_mode,
            "MAR preserves arithmetic status");
    require(pc == 12'h019 && cycle_count == 32'd25,
            "MAR consumes one native instruction cycle");
    require(data_read && !data_write && data_address_valid &&
            data_address == 8'h83 && data_read_data == 16'hff80,
            "LDP presents an internal read beside normal program phases");

    advance_to_sample();
    require(retired && !data_page_pointer,
            "LDP loads the selected data-word LSB into DP");
    require(!overflow_flag && overflow_mode,
            "LDP preserves arithmetic status");
    require(pc == 12'h01a && cycle_count == 32'd26,
            "LDP consumes one native instruction cycle");
    require(data_read && !data_write && data_address_valid &&
            data_address == 8'h03 && data_read_data == 16'hbeef,
            "LT presents its internal read beside normal program phases");

    advance_to_sample();
    require(retired && t_register == 16'hbeef,
            "LT loads the complete selected data word into T");
    require(!overflow_flag && overflow_mode,
            "LT preserves arithmetic status");
    require(pc == 12'h01b && cycle_count == 32'd27,
            "LT consumes one native instruction cycle");
    require(data_read && !data_write && data_address_valid &&
            data_address == 8'h04 && data_read_data == 16'h0002,
            "MPY presents its internal operand beside normal program phases");

    advance_to_sample();
    require(retired && product_register == 32'hffff_7dde,
            "MPY stores the signed product in P");
    require(t_register == 16'hbeef &&
            !overflow_flag && overflow_mode,
            "MPY preserves T and arithmetic status");
    require(pc == 12'h01c && cycle_count == 32'd28,
            "MPY consumes one native instruction cycle");
    require(!data_read && !data_write && !data_address_valid,
            "MPYK has only its normal program-memory transaction");

    advance_to_sample();
    require(retired && product_register == 32'h0002_4999,
            "MPYK sign-extends its immediate and stores the signed product");
    require(t_register == 16'hbeef &&
            !overflow_flag && overflow_mode,
            "MPYK preserves T and arithmetic status");
    require(pc == 12'h01d && cycle_count == 32'd29,
            "MPYK consumes one native instruction cycle");
    require(!data_read && !data_write && !data_address_valid,
            "PAC has only its normal program-memory transaction");

    advance_to_sample();
    require(retired && accumulator == 32'h0002_4999,
            "PAC copies the complete P register into the accumulator");
    require(product_register == 32'h0002_4999 &&
            t_register == 16'hbeef &&
            !overflow_flag && overflow_mode,
            "PAC preserves P, T, and arithmetic status");
    require(pc == 12'h01e && cycle_count == 32'd30,
            "PAC consumes one native instruction cycle");

    advance_to_sample();
    require(sample && !retired && illegal, "unsupported word traps at sample");
    require(!instruction_valid, "unsupported word remains visibly invalid");
    require(pc == 12'h01e, "trap holds architectural PC");
    require(program_address == 12'h01e, "trap holds native program address");
    require(cycle_count == 32'd30, "trap does not count as retired cycle");

    // Assertion is recognized at the next falling boundary, after the current
    // machine cycle, and resets the architectural PC with the native address.
    rs = 1'b1;
    for (int unsigned index = 0; index < 4; index++) begin
      tick();
    end
    require(!bus_active && men_n, "recognized reset disables native bus");
    require(pc == 12'h000 && program_address == 12'h000,
            "recognized reset aligns architectural and native address zero");

    $display("PASS tb_phase_slice_integration");
    $finish;
  end
endmodule

`default_nettype wire
