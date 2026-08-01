`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_host_timing;
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
  logic [1:0]  select_quadrant;
  logic [7:0]  target_select;
  logic        cycle_complete;
  logic        read_complete;
  logic        write_complete;

  hard_drivin_sound_host_timing dut (
    .clk_i                       (clk),
    .initialize_i                (initialize),
    .host_8mhz_rise_i            (host_8mhz_rise),
    .host_8mhz_fall_i            (host_8mhz_fall),
    .address_strobe_assert_i     (address_strobe_assert),
    .address_strobe_deassert_i   (address_strobe_deassert),
    .function_code_i             (function_code),
    .address_i                   (address),
    .read_not_write_i            (read_not_write),
    .upper_data_strobe_n_i       (upper_data_strobe_n),
    .lower_data_strobe_n_i       (lower_data_strobe_n),
    .cycle_active_o              (cycle_active),
    .rva_o                       (rva),
    .vpa_n_o                     (vpa_n),
    .dtack_n_o                   (dtack_n),
    .rvas_n_o                    (rvas_n),
    .rvf_n_o                     (rvf_n),
    .read_write_strobe_n_o       (read_write_strobe_n),
    .upper_write_enable_n_o      (upper_write_enable_n),
    .lower_write_enable_n_o      (lower_write_enable_n),
    .read_select_valid_o         (read_select_valid),
    .write_select_valid_o        (write_select_valid),
    .latched_address_o           (latched_address),
    .select_quadrant_o           (select_quadrant),
    .target_select_o             (target_select),
    .cycle_complete_o            (cycle_complete),
    .read_complete_o             (read_complete),
    .write_complete_o            (write_complete)
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

  function automatic logic [7:0] expected_target(
    input logic       rw,
    input logic [1:0] quadrant
  );
    expected_target = 8'h01 << {rw, quadrant};
  endfunction

  task automatic initialize_idle;
    host_8mhz_rise = 1'b0;
    host_8mhz_fall = 1'b0;
    address_strobe_assert = 1'b0;
    address_strobe_deassert = 1'b0;
    function_code = 3'b101;
    address = '0;
    read_not_write = 1'b1;
    upper_data_strobe_n = 1'b1;
    lower_data_strobe_n = 1'b1;
    initialize = 1'b1;
    tick();
    initialize = 1'b0;
    tick();
  endtask

  task automatic start_cycle(
    input logic [23:1] cycle_address,
    input logic [2:0]  cycle_function_code,
    input logic        cycle_read_not_write,
    input logic        cycle_upper_strobe_n,
    input logic        cycle_lower_strobe_n
  );
    address = cycle_address;
    function_code = cycle_function_code;
    read_not_write = cycle_read_not_write;
    upper_data_strobe_n = cycle_upper_strobe_n;
    lower_data_strobe_n = cycle_lower_strobe_n;
    address_strobe_assert = 1'b1;
    tick();
    address_strobe_assert = 1'b0;
  endtask

  task automatic rising_edge;
    host_8mhz_rise = 1'b1;
    tick();
    host_8mhz_rise = 1'b0;
  endtask

  task automatic falling_edge(input logic deassert_strobe);
    host_8mhz_fall = 1'b1;
    address_strobe_deassert = deassert_strobe;
    tick();
    host_8mhz_fall = 1'b0;
    address_strobe_deassert = 1'b0;
  endtask

  task automatic finish_ordinary_cycle(input logic deassert_at_s7);
    falling_edge(1'b0); // S4 -> S5: accept /DTACK and retain /RVAS.
    require(rva && !dtack_n && !rvas_n,
            "S5 retains the asserted acknowledgement/select state");
    rising_edge();      // S5 -> S6: end RVA but keep /RVAS selected.
    require(!rva && dtack_n && !rvas_n,
            "S6 deasserts RVA/DTACK while the hold stage keeps /RVAS low");
    falling_edge(deassert_at_s7); // S6 -> S7: data latch and completion.
    require(cycle_complete && rvas_n,
            "S7 emits one completion and releases /RVAS");
  endtask

  initial begin
    initialize_idle();
    require(!cycle_active && !rva && vpa_n && dtack_n && rvas_n && rvf_n,
            "deterministic FPGA initialization selects the documented idle carrier");
    require(read_write_strobe_n && upper_write_enable_n &&
            lower_write_enable_n && target_select == 8'h00,
            "idle state asserts no write or low-I/O target");

    // Exhaust the complete LS138 30P evidence space that is visible here:
    // all ignored A22:A17 aliases, A23, A16:A14, read/write, and A13:A12.
    for (int unsigned alias_bits = 0; alias_bits < 64; alias_bits++) begin
      for (int unsigned a23 = 0; a23 < 2; a23++) begin
        for (int unsigned high_select = 0; high_select < 8; high_select++) begin
          for (int unsigned rw = 0; rw < 2; rw++) begin
            for (int unsigned quadrant = 0; quadrant < 4; quadrant++) begin
              logic [23:1] cycle_address;
              logic expected_rvf;
              cycle_address = '0;
              cycle_address[23] = a23[0];
              cycle_address[22:17] = alias_bits[5:0];
              cycle_address[16:14] = high_select[2:0];
              cycle_address[13:12] = quadrant[1:0];
              expected_rvf = a23[0] && (high_select[2:0] == 3'b100);

              start_cycle(cycle_address, 3'b101, rw[0], 1'b0, 1'b0);
              require(cycle_active && (rvf_n == !expected_rvf),
                      "LS138 30P qualification ignores only A22:A17");
              require(rvas_n && dtack_n && target_select == 8'h00,
                      "an armed /AS event does not select before S4");
              require(select_quadrant == quadrant[1:0],
                      "low-I/O quadrant is captured from A13:A12");
              require(latched_address == cycle_address,
                      "the adapter retains the complete stable bus address");

              rising_edge();
              require(rva && !dtack_n && !rvas_n,
                      "S4 asserts the one-period RVA/DTACK and /RVAS");
              require(read_select_valid == (expected_rvf && rw[0]) &&
                      write_select_valid == (expected_rvf && !rw[0]),
                      "read/write validity requires both /RVF and /RVAS");
              require(target_select ==
                        (expected_rvf
                           ? expected_target(rw[0], quadrant[1:0])
                           : 8'h00),
                      "LS138 30N selects the exact physical target order");
              require(read_write_strobe_n == rw[0],
                      "global /RWS follows RWN throughout active /RVAS");
              require(upper_write_enable_n == rw[0] &&
                      lower_write_enable_n == rw[0],
                      "both asserted byte strobes qualify only write cycles");

              finish_ordinary_cycle(1'b1);
              require(!cycle_active && target_select == 8'h00,
                      "coincident S7 /AS release ends all address selection");
              require(read_complete == (expected_rvf && rw[0]) &&
                      write_complete == (expected_rvf && !rw[0]),
                      "completion pulses retain low-I/O and direction qualification");
              tick();
              require(!cycle_complete && !read_complete && !write_complete,
                      "all completion indications are exactly one FPGA clock");
            end
          end
        end
      end
    end

    // Physical /WEU and /WEL are /UDS-/LDS-qualified even though LS138 30N's
    // low-I/O target outputs themselves are not byte qualified.
    for (int unsigned strobes = 0; strobes < 4; strobes++) begin
      logic [23:1] qualified_address;
      qualified_address = '0;
      qualified_address[23] = 1'b1;
      qualified_address[16:14] = 3'b100;
      qualified_address[13:12] = 2'b01;
      start_cycle(qualified_address, 3'b001, 1'b0,
                  strobes[1], strobes[0]);
      rising_edge();
      require(!read_write_strobe_n &&
              upper_write_enable_n == strobes[1] &&
              lower_write_enable_n == strobes[0],
              "upper/lower write enables preserve the two data strobes");
      require(target_select == 8'h02,
              "/LATCHES remains selected independently of byte strobes");
      finish_ordinary_cycle(1'b1);
      tick();
    end

    // CPU-space/VPA suppresses normal DTACK. The artificial qualified address
    // deliberately proves RVA and /RVAS remain separate physical logic; no
    // ordinary completion is emitted for the external VPA-owned cycle.
    begin
      logic [23:1] qualified_address;
      qualified_address = '0;
      qualified_address[23] = 1'b1;
      qualified_address[16:14] = 3'b100;
      qualified_address[13:12] = 2'b11;
      start_cycle(qualified_address, 3'b111, 1'b1, 1'b0, 1'b0);
      require(!vpa_n && !rvf_n,
              "CPU-space and high-address qualification remain independent");
      rising_edge();
      require(rva && dtack_n && !rvas_n && target_select == 8'h80,
              "/VPA blocks DTACK without erasing the separate RVA decode pulse");
      falling_edge(1'b0);
      rising_edge();
      require(!rva && dtack_n && rvas_n && !cycle_complete,
              "a VPA cycle never enters the normal /DTACK hold completion");
      falling_edge(1'b0);
      require(!cycle_complete && !read_complete && !write_complete,
              "CPU-space completion remains owned by the external VPA path");
      address_strobe_deassert = 1'b1;
      tick();
      address_strobe_deassert = 1'b0;
      require(!cycle_active && rvf_n,
              "external CPU-space /AS release ends high-address qualification");
    end

    // Holding /AS after the normal S7 boundary cannot re-arm the one-shot.
    begin
      logic [23:1] qualified_address;
      qualified_address = '0;
      qualified_address[23] = 1'b1;
      qualified_address[16:14] = 3'b100;
      start_cycle(qualified_address, 3'b010, 1'b1, 1'b0, 1'b0);
      rising_edge();
      finish_ordinary_cycle(1'b0);
      require(cycle_active && cycle_complete && rvas_n,
              "completion can precede modeled /AS propagation release");
      tick();
      rising_edge();
      falling_edge(1'b0);
      require(!cycle_complete && rvas_n && dtack_n,
              "held /AS supplies no READY-style retry or second completion");
      address_strobe_deassert = 1'b1;
      tick();
      address_strobe_deassert = 1'b0;
      require(!cycle_active,
              "a later modeled /AS release is accepted after completion");
    end

    // Initialization during an armed sequence returns only the explicitly
    // documented FPGA carrier, without claiming physical F74 reset behavior.
    begin
      logic [23:1] qualified_address;
      qualified_address = '0;
      qualified_address[23] = 1'b1;
      qualified_address[16:14] = 3'b100;
      start_cycle(qualified_address, 3'b000, 1'b0, 1'b0, 1'b0);
      rising_edge();
      require(!rvas_n && !dtack_n,
              "test establishes an active sequence before reinitialization");
      initialize = 1'b1;
      tick();
      initialize = 1'b0;
      tick();
      require(!cycle_active && !rva && vpa_n && dtack_n && rvas_n && rvf_n &&
              target_select == 8'h00,
              "FPGA initialization restores deterministic idle state");
    end

    $display("PASS tb_hard_drivin_sound_host_timing");
    $finish;
  end
endmodule

`default_nettype wire
