`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_local_memory_bridge;
  logic        clk;
  logic        initialize;
  logic        host_8mhz_rise;
  logic        host_8mhz_fall;
  logic        address_strobe_assert;
  logic        address_strobe_deassert;
  logic [2:0]  function_code;
  logic [23:1] address;
  logic        read_not_write;
  logic        upper_data_strobe_n;
  logic        lower_data_strobe_n;
  logic [15:0] host_write_data;

  logic        cycle_active;
  logic        rva;
  logic        vpa_n;
  logic        dtack_n;
  logic        rvas_n;
  logic        rvf_n;
  logic        read_write_strobe_n;
  logic        upper_write_enable_n;
  logic        lower_write_enable_n;
  logic        read_select_valid;
  logic        write_select_valid;
  logic [23:1] latched_address;
  logic        latched_read_not_write;
  logic        latched_upper_data_strobe_n;
  logic        latched_lower_data_strobe_n;
  logic [1:0]  select_quadrant;
  logic [7:0]  target_select;
  logic        cycle_complete_event;
  logic        read_complete_event;
  logic        write_complete_event;
  logic        cycle_complete;
  logic        read_complete;
  logic        write_complete;

  logic        rom_read_request;
  logic [14:0] rom_word_address;
  logic [15:0] rom_read_data;
  logic        rom_read_data_valid;
  logic        local_ram_read_request;
  logic [12:0] local_ram_word_address;
  logic [15:0] local_ram_read_data;
  logic [15:0] local_ram_read_valid_mask;
  logic        local_ram_upper_write_commit;
  logic        local_ram_lower_write_commit;
  logic [15:0] local_ram_write_data;
  logic        host_program_select_n;
  logic        host_program_ram_select_n;
  logic        host_program_ram_read;
  logic        host_program_ram_write;
  logic        host_program_ram_write_commit;
  logic [11:0] host_program_word_address;
  logic        host_program_io_read;
  logic        host_program_io_write;
  logic        host_program_io_write_commit;
  logic        host_communication_select_n;
  logic        host_communication_read;
  logic        host_communication_write;
  logic        host_communication_write_commit;
  logic [8:0]  host_communication_word_address;
  logic [15:0] host_read_data;
  logic [15:0] host_read_driven_mask;
  logic [15:0] host_read_valid_mask;
  logic [1:0]  host_read_target_select;
  logic        host_read_response_missing_event;
  logic [7:0]  high_bank_select_n;
  logic        rvf_select_n;
  logic        local_ram_select_n;

  logic [15:0] local_words [0:8191];
  logic [1:0]  local_valid [0:8191];
  int unsigned upper_write_count;
  int unsigned lower_write_count;
  int unsigned program_write_count;
  int unsigned program_io_write_count;
  int unsigned communication_write_count;
  int unsigned missing_read_count;

  hard_drivin_sound_host_timing timing (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .host_8mhz_rise_i              (host_8mhz_rise),
    .host_8mhz_fall_i              (host_8mhz_fall),
    .address_strobe_assert_i       (address_strobe_assert),
    .address_strobe_deassert_i     (address_strobe_deassert),
    .function_code_i               (function_code),
    .address_i                     (address),
    .read_not_write_i              (read_not_write),
    .upper_data_strobe_n_i         (upper_data_strobe_n),
    .lower_data_strobe_n_i         (lower_data_strobe_n),
    .cycle_active_o                (cycle_active),
    .rva_o                         (rva),
    .vpa_n_o                       (vpa_n),
    .dtack_n_o                     (dtack_n),
    .rvas_n_o                      (rvas_n),
    .rvf_n_o                       (rvf_n),
    .read_write_strobe_n_o         (read_write_strobe_n),
    .upper_write_enable_n_o        (upper_write_enable_n),
    .lower_write_enable_n_o        (lower_write_enable_n),
    .read_select_valid_o           (read_select_valid),
    .write_select_valid_o          (write_select_valid),
    .latched_address_o             (latched_address),
    .latched_read_not_write_o      (latched_read_not_write),
    .latched_upper_data_strobe_n_o (
      latched_upper_data_strobe_n
    ),
    .latched_lower_data_strobe_n_o (
      latched_lower_data_strobe_n
    ),
    .select_quadrant_o             (select_quadrant),
    .target_select_o               (target_select),
    .cycle_complete_event_o        (cycle_complete_event),
    .read_complete_event_o         (read_complete_event),
    .write_complete_event_o        (write_complete_event),
    .cycle_complete_o              (cycle_complete),
    .read_complete_o               (read_complete),
    .write_complete_o              (write_complete)
  );

  hard_drivin_sound_local_memory_bridge dut (
    .host_8mhz_rise_i                    (host_8mhz_rise),
    .cycle_active_i                      (cycle_active),
    .rva_i                               (rva),
    .rvas_n_i                            (rvas_n),
    .cycle_complete_event_i              (cycle_complete_event),
    .latched_address_i                   (latched_address),
    .latched_read_not_write_i            (latched_read_not_write),
    .latched_upper_data_strobe_n_i       (
      latched_upper_data_strobe_n
    ),
    .latched_lower_data_strobe_n_i       (
      latched_lower_data_strobe_n
    ),
    .host_write_data_i                   (host_write_data),
    .rom_read_request_o                  (rom_read_request),
    .rom_word_address_o                  (rom_word_address),
    .rom_read_data_i                     (rom_read_data),
    .rom_read_data_valid_i               (rom_read_data_valid),
    .local_ram_read_request_o            (local_ram_read_request),
    .local_ram_word_address_o            (local_ram_word_address),
    .local_ram_read_data_i               (local_ram_read_data),
    .local_ram_read_valid_mask_i         (local_ram_read_valid_mask),
    .local_ram_upper_write_commit_o      (
      local_ram_upper_write_commit
    ),
    .local_ram_lower_write_commit_o      (
      local_ram_lower_write_commit
    ),
    .local_ram_write_data_o              (local_ram_write_data),
    .host_program_select_n_o             (host_program_select_n),
    .host_program_ram_select_n_o         (host_program_ram_select_n),
    .host_program_ram_read_o             (host_program_ram_read),
    .host_program_ram_write_o            (host_program_ram_write),
    .host_program_ram_write_commit_o     (
      host_program_ram_write_commit
    ),
    .host_program_word_address_o         (host_program_word_address),
    .host_program_io_read_o              (host_program_io_read),
    .host_program_io_write_o             (host_program_io_write),
    .host_program_io_write_commit_o      (
      host_program_io_write_commit
    ),
    .host_communication_select_n_o       (
      host_communication_select_n
    ),
    .host_communication_read_o           (host_communication_read),
    .host_communication_write_o          (host_communication_write),
    .host_communication_write_commit_o   (
      host_communication_write_commit
    ),
    .host_communication_word_address_o   (
      host_communication_word_address
    ),
    .host_read_data_o                    (host_read_data),
    .host_read_driven_mask_o             (host_read_driven_mask),
    .host_read_valid_mask_o              (host_read_valid_mask),
    .host_read_target_select_o           (host_read_target_select),
    .host_read_response_missing_event_o  (
      host_read_response_missing_event
    ),
    .high_bank_select_n_o                (high_bank_select_n),
    .rvf_select_n_o                      (rvf_select_n),
    .local_ram_select_n_o                (local_ram_select_n)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  always_comb begin
    rom_read_data = 16'h9000 ^ {1'b0, rom_word_address};
    local_ram_read_data = local_words[local_ram_word_address];
    local_ram_read_valid_mask = {
      {8{local_valid[local_ram_word_address][1]}},
      {8{local_valid[local_ram_word_address][0]}}
    };
  end

  always_ff @(posedge clk) begin
    if (initialize) begin
      upper_write_count <= 0;
      lower_write_count <= 0;
      program_write_count <= 0;
      program_io_write_count <= 0;
      communication_write_count <= 0;
      missing_read_count <= 0;
    end else begin
      if (local_ram_upper_write_commit) begin
        local_words[local_ram_word_address][15:8] <=
          local_ram_write_data[15:8];
        local_valid[local_ram_word_address][1] <= 1'b1;
        upper_write_count <= upper_write_count + 1;
      end
      if (local_ram_lower_write_commit) begin
        local_words[local_ram_word_address][7:0] <=
          local_ram_write_data[7:0];
        local_valid[local_ram_word_address][0] <= 1'b1;
        lower_write_count <= lower_write_count + 1;
      end
      if (host_program_ram_write_commit) begin
        program_write_count <= program_write_count + 1;
      end
      if (host_program_io_write_commit) begin
        program_io_write_count <= program_io_write_count + 1;
      end
      if (host_communication_write_commit) begin
        communication_write_count <= communication_write_count + 1;
      end
      if (host_read_response_missing_event) begin
        missing_read_count <= missing_read_count + 1;
      end
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

  task automatic start_cycle(
    input logic [23:0] byte_address,
    input logic        cycle_read_not_write,
    input logic        upper_strobe_n,
    input logic        lower_strobe_n,
    input logic [15:0] write_data
  );
    address = byte_address[23:1];
    read_not_write = cycle_read_not_write;
    upper_data_strobe_n = upper_strobe_n;
    lower_data_strobe_n = lower_strobe_n;
    host_write_data = write_data;
    address_strobe_assert = 1'b1;
    tick();
    address_strobe_assert = 1'b0;
    require(cycle_active && latched_address == byte_address[23:1] &&
            latched_read_not_write == cycle_read_not_write,
            "timing boundary captures address and direction");
  endtask

  task automatic rising_edge;
    host_8mhz_rise = 1'b1;
    tick();
    host_8mhz_rise = 1'b0;
    #1;
  endtask

  task automatic falling_edge;
    host_8mhz_fall = 1'b1;
    tick();
    host_8mhz_fall = 1'b0;
    #1;
  endtask

  task automatic advance_to_s6;
    rising_edge();
    require(rva && !dtack_n && !rvas_n,
            "S4 begins the fixed selected interval");
    falling_edge();
    require(rva && !dtack_n && !rvas_n,
            "S5 retains acknowledgement and decode");
    rising_edge();
    require(!rva && dtack_n && !rvas_n,
            "S6 ends RVA while retaining /RVAS");
  endtask

  task automatic finish_at_s7(
    input logic expect_upper_write,
    input logic expect_lower_write,
    input logic expect_program_write,
    input logic expect_communication_write
  );
    host_8mhz_fall = 1'b1;
    address_strobe_deassert = 1'b1;
    #1;
    require(cycle_complete_event,
            "ordinary S7 exposes the pre-edge completion event");
    require(local_ram_upper_write_commit == expect_upper_write &&
            local_ram_lower_write_commit == expect_lower_write &&
            host_program_ram_write_commit == expect_program_write &&
            host_communication_write_commit == expect_communication_write,
            "S7 commits exactly the selected SRAM write callbacks");
    tick();
    host_8mhz_fall = 1'b0;
    address_strobe_deassert = 1'b0;
    require(!cycle_active && rvas_n && cycle_complete,
            "S7 releases the selection and records completion");
    tick();
  endtask

  initial begin
    for (int unsigned word = 0; word < 8192; word++) begin
      local_words[word] = 16'h0000;
      local_valid[word] = 2'b00;
    end

    initialize = 1'b1;
    host_8mhz_rise = 1'b0;
    host_8mhz_fall = 1'b0;
    address_strobe_assert = 1'b0;
    address_strobe_deassert = 1'b0;
    function_code = 3'b001;
    address = '0;
    read_not_write = 1'b1;
    upper_data_strobe_n = 1'b1;
    lower_data_strobe_n = 1'b1;
    host_write_data = 16'h0000;
    rom_read_data_valid = 1'b1;
    tick();
    initialize = 1'b0;
    tick();

    require(!cycle_active && !rom_read_request &&
            !local_ram_read_request && host_read_target_select == 2'b00,
            "idle timing drives no local storage callback");

    // The populated 27256 callback starts directly from /AS and preserves the
    // physical A22:A16 mirrors. Valid synthetic data drives a complete word.
    start_cycle(24'h123456, 1'b1, 1'b0, 1'b0, 16'h0000);
    require(rom_read_request && rom_word_address == address[15:1] &&
            high_bank_select_n == 8'hff &&
            host_read_target_select == 2'b01 &&
            host_read_data == rom_read_data &&
            host_read_driven_mask == 16'hffff &&
            host_read_valid_mask == 16'hffff,
            "ROM callback carries a valid complete synthetic word before S4");
    advance_to_s6();
    finish_at_s7(1'b0, 1'b0, 1'b0, 1'b0);
    require(missing_read_count == 0,
            "valid ROM data emits no missing-response event");

    start_cycle(24'h523456, 1'b1, 1'b0, 1'b0, 16'h0000);
    require(rom_word_address == 15'h1a2b &&
            host_read_data == (16'h9000 ^ 16'h1a2b),
            "ROM callback preserves the populated A22:A16 mirror");
    advance_to_s6();
    finish_at_s7(1'b0, 1'b0, 1'b0, 1'b0);

    rom_read_data_valid = 1'b0;
    start_cycle(24'h003456, 1'b1, 1'b0, 1'b0, 16'h0000);
    require(host_read_data == 16'h0000 &&
            host_read_driven_mask == 16'hffff &&
            host_read_valid_mask == 16'h0000,
            "unavailable ROM data remains driven-but-invalid, not open bus");
    advance_to_s6();
    host_8mhz_fall = 1'b1;
    address_strobe_deassert = 1'b1;
    #1;
    require(host_read_response_missing_event,
            "invalid ROM response is reported at the fixed S7 boundary");
    tick();
    host_8mhz_fall = 1'b0;
    address_strobe_deassert = 1'b0;
    tick();
    require(missing_read_count == 1,
            "missing ROM response produces one diagnostic event");
    rom_read_data_valid = 1'b1;

    // Unwritten local SRAM is physically selected and driven but its carrier
    // remains invalid. A complete write qualifies both byte callbacks at S7.
    start_cycle(24'hffc246, 1'b1, 1'b0, 1'b0, 16'h0000);
    require(local_ram_read_request && local_ram_word_address == 13'h0123 &&
            !local_ram_select_n && !high_bank_select_n[7] &&
            host_read_target_select == 2'b10 &&
            host_read_driven_mask == 16'hffff &&
            host_read_valid_mask == 16'h0000,
            "unwritten local SRAM retains explicit invalid data state");
    advance_to_s6();
    finish_at_s7(1'b0, 1'b0, 1'b0, 1'b0);
    require(missing_read_count == 2,
            "unwritten local SRAM reports one missing response");

    start_cycle(24'hffc246, 1'b0, 1'b0, 1'b0, 16'hcafe);
    require(!local_ram_read_request && !local_ram_upper_write_commit &&
            !local_ram_lower_write_commit,
            "local SRAM write has no callback before /RVAS and S7");
    advance_to_s6();
    finish_at_s7(1'b1, 1'b1, 1'b0, 1'b0);
    require(upper_write_count == 1 && lower_write_count == 1,
            "complete local SRAM write commits both physical slices once");

    start_cycle(24'h81c246, 1'b1, 1'b0, 1'b0, 16'h0000);
    require(local_ram_read_request && local_ram_word_address == 13'h0123 &&
            host_read_data == 16'hcafe &&
            host_read_valid_mask == 16'hffff,
            "high-bank alias reads the same valid local SRAM word");
    advance_to_s6();
    finish_at_s7(1'b0, 1'b0, 1'b0, 1'b0);

    start_cycle(24'hffc246, 1'b0, 1'b0, 1'b1, 16'h12aa);
    advance_to_s6();
    finish_at_s7(1'b1, 1'b0, 1'b0, 1'b0);
    require(upper_write_count == 2 && lower_write_count == 1,
            "upper-only local SRAM write preserves independent byte enables");
    start_cycle(24'hffc246, 1'b1, 1'b0, 1'b0, 16'h0000);
    require(host_read_data == 16'h12fe &&
            host_read_valid_mask == 16'hffff,
            "upper-only callback preserves the lower stored byte");
    advance_to_s6();
    finish_at_s7(1'b0, 1'b0, 1'b0, 1'b0);

    // Y5 lower-half and Y6 writes use whole-word S7 callbacks and their exact
    // physical word-address projections. Neither enters the local read mux.
    start_cycle(24'hff4246, 1'b0, 1'b0, 1'b0, 16'h3456);
    rising_edge();
    require(!host_program_select_n && !host_program_ram_select_n &&
            host_program_ram_write &&
            host_program_word_address == 12'h123 &&
            host_read_target_select == 2'b00,
            "Y5 lower half exposes the whole-word program-RAM write path");
    falling_edge();
    rising_edge();
    finish_at_s7(1'b0, 1'b0, 1'b1, 1'b0);
    require(program_write_count == 1,
            "program-RAM callback commits once at S7");
    start_cycle(24'hff4246, 1'b1, 1'b0, 1'b0, 16'h0000);
    rising_edge();
    require(!host_program_ram_select_n && host_program_ram_read &&
            !host_program_ram_write &&
            !host_program_io_read && !host_program_io_write,
            "Y5 lower-half read remains distinct from direct TMS I/O");
    falling_edge();
    rising_edge();
    finish_at_s7(1'b0, 1'b0, 1'b0, 1'b0);

    start_cycle(24'hff8246, 1'b0, 1'b0, 1'b0, 16'h789a);
    rising_edge();
    require(!host_communication_select_n && host_communication_write &&
            host_communication_word_address == 9'h123,
            "Y6 exposes the exact communication-RAM write callback");
    falling_edge();
    rising_edge();
    finish_at_s7(1'b0, 1'b0, 1'b0, 1'b1);
    require(communication_write_count == 1,
            "communication-RAM callback commits once at S7");
    start_cycle(24'hff8246, 1'b1, 1'b0, 1'b0, 16'h0000);
    rising_edge();
    require(host_communication_read && !host_communication_write,
            "Y6 read callback retains the captured transfer direction");
    falling_edge();
    rising_edge();
    finish_at_s7(1'b0, 1'b0, 1'b0, 1'b0);

    // Y5 upper-half /PWE ends at S6 with RVA, not at the SRAM S7 boundary.
    start_cycle(24'hff6246, 1'b0, 1'b0, 1'b0, 16'hbcde);
    rising_edge();
    require(host_program_io_write && !host_program_io_write_commit,
            "Y5 upper-half write asserts the RVA-width /PWE level at S4");
    falling_edge();
    require(program_io_write_count == 0,
            "direct program/I/O write has not completed at S5");
    rising_edge();
    require(program_io_write_count == 1 && !host_program_io_write,
            "the /PWE rising edge produces the direct write callback at S6");
    finish_at_s7(1'b0, 1'b0, 1'b0, 1'b0);
    start_cycle(24'hff6246, 1'b1, 1'b0, 1'b0, 16'h0000);
    rising_edge();
    require(host_program_io_read && !host_program_io_write &&
            !host_program_ram_read && !host_program_ram_write,
            "Y5 upper-half read exposes only the held /PDEN callback");
    falling_edge();
    rising_edge();
    finish_at_s7(1'b0, 1'b0, 1'b0, 1'b0);

    // Y4 remains owned by the separate low-I/O adapter.
    start_cycle(24'hff0000, 1'b1, 1'b0, 1'b0, 16'h0000);
    rising_edge();
    require(read_select_valid && !rvf_select_n &&
            host_read_target_select == 2'b00 &&
            !rom_read_request && !local_ram_read_request,
            "Y4 low I/O remains outside the ROM/local-RAM carrier");
    falling_edge();
    rising_edge();
    finish_at_s7(1'b0, 1'b0, 1'b0, 1'b0);

    $display("PASS tb_hard_drivin_sound_local_memory_bridge");
    $finish;
  end
endmodule

`default_nettype wire
