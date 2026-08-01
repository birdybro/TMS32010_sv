`default_nettype none

module tb_sst_rtl;
  logic        clk;
  logic        initialize;
  logic        reset;
  logic        clock_enable;
  logic [11:0] program_address;
  logic        program_read;
  logic [15:0] program_data;
  logic [7:0]  data_address;
  logic        data_read;
  logic        data_write;
  logic        data_address_valid;
  logic [7:0]  data_write_address;
  logic        data_write_address_valid;
  logic [15:0] data_write_data;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic [11:0] pc;
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
    .program_write_o               (),
    .program_write_data_o          (),
    .program_data_i                (program_data),
    .io_port_o                     (),
    .io_read_o                     (),
    .io_write_o                    (),
    .io_write_data_o               (),
    .io_read_data_i                (16'h0000),
    .data_address_o                (data_address),
    .data_read_o                   (data_read),
    .data_write_o                  (data_write),
    .data_address_valid_o          (data_address_valid),
    .data_write_address_o          (data_write_address),
    .data_write_address_valid_o    (data_write_address_valid),
    .data_read_data_o              (),
    .data_write_data_o             (data_write_data),
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
    .pc_o                          (pc),
    .accumulator_o                 (),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (auxiliary_register_0),
    .auxiliary_register_1_o        (auxiliary_register_1),
    .auxiliary_register_pointer_o  (auxiliary_register_pointer),
    .data_page_pointer_o           (data_page_pointer),
    .stack_top_o                   (),
    .stack_level_1_o               (),
    .stack_level_2_o               (),
    .stack_bottom_o                (),
    .overflow_flag_o               (overflow_flag),
    .overflow_mode_o               (overflow_mode),
    .interrupt_mask_o              (interrupt_mask),
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
    assert (!data_write_address_valid || (data_write_address < 8'd144));
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  task automatic execute_sst(
    input logic [7:0] expected_address,
    input logic [15:0] expected_data,
    input logic [31:0] expected_cycle
  );
    require(instruction_valid && program_read,
            "SST decodes at its program execution boundary");
    require(data_write && !data_read && data_address_valid,
            "SST exposes one logical internal-RAM write");
    require(data_address == expected_address &&
            data_write_address == expected_address &&
            data_write_address_valid,
            "SST exposes the expected internal-RAM destination");
    require(data_write_data == expected_data,
            "SST exposes the pre-update packed status word");
    require((data_write_data & 16'h1efe) == 16'h1efe,
            "SST stores all constant positions as ones");
    tick();
    require(retired && !illegal,
            "SST retires without an illegal indication");
    require(cycle_count == expected_cycle,
            "SST consumes exactly one instruction cycle");
  endtask

  initial begin
    for (int unsigned index = 0; index < 4096; index++) begin
      program_memory[index] = 16'h7f80;
    end
    program_memory[0]  = 16'h7b00;  // LST 0 -> OV/OVM/ARP/DP set
    program_memory[1]  = 16'h7c0f;  // SST 15 -> forced address 0x8f
    program_memory[2]  = 16'h7f82;  // EINT
    program_memory[3]  = 16'h7b00;  // page-one LST 0 -> clear status fields
    program_memory[4]  = 16'h7c00;  // SST 0 -> forced address 0x80
    program_memory[5]  = 16'h7f81;  // DINT
    program_memory[6]  = 16'h718e;  // LARK AR1,0x8e
    program_memory[7]  = 16'h6881;  // LARP 1
    program_memory[8]  = 16'h6e01;  // LDPK 1
    program_memory[9]  = 16'h7ca0;  // SST *+,0
    program_memory[10] = 16'h7081;  // LARK AR0,0x81
    program_memory[11] = 16'h7c88;  // SST *, preserve ARP
    program_memory[12] = 16'h7c10;  // nonexistent direct page-one location

    initialize         = 1'b1;
    reset              = 1'b1;
    clock_enable       = 1'b1;
    debug_data_write   = 1'b1;
    debug_data_address = 8'h00;
    debug_data         = 16'hc101;
    tick();
    debug_data_address = 8'h80;
    debug_data         = 16'h0000;
    tick();
    debug_data_write = 1'b0;
    initialize       = 1'b0;
    tick();
    require(!program_read && interrupt_mask,
            "reset suppresses fetch and establishes INTM");

    reset = 1'b0;
    tick();
    require(overflow_flag && overflow_mode && interrupt_mask &&
            auxiliary_register_pointer && data_page_pointer,
            "LST establishes all SST-defined state fields");
    execute_sst(8'h8f, 16'hffff, 32'd2);

    tick();
    require(!interrupt_mask, "EINT clears INTM before the second SST");
    tick();
    require(!overflow_flag && !overflow_mode && !interrupt_mask &&
            !auxiliary_register_pointer && !data_page_pointer,
            "page-one LST clears every modeled status field except INTM");
    execute_sst(8'h80, 16'h1efe, 32'd5);

    tick();
    tick();
    tick();
    tick();
    require(interrupt_mask && auxiliary_register_pointer && data_page_pointer,
            "setup selects AR1 with INTM and DP set");
    require(auxiliary_register_1 == 16'h008e,
            "LARK establishes the indirect SST address");
    execute_sst(8'h8e, 16'h3fff, 32'd10);
    require(auxiliary_register_1 == 16'h008f,
            "indirect SST increments the selected AR after capturing status");
    require(!auxiliary_register_pointer,
            "indirect SST installs next ARP after storing old ARP");

    tick();
    require(auxiliary_register_0 == 16'h0081,
            "LARK establishes the preserving indirect address");
    execute_sst(8'h81, 16'h3eff, 32'd12);
    require(auxiliary_register_0 == 16'h0081 &&
            !auxiliary_register_pointer,
            "preserving SST leaves AR and ARP unchanged");

    require(!instruction_valid && !data_read && !data_write,
            "nonexistent direct SST encoding is rejected before access");
    tick();
    require(illegal && !retired && pc == 12'd12 && cycle_count == 32'd12,
            "invalid direct SST parks without retirement or timing drift");

    $display("PASS tb_sst_rtl");
    $finish;
  end
endmodule

`default_nettype wire
