`default_nettype none

module tb_hard_drivin_main_bus_control;
  logic        clk;
  logic        initialize;
  logic [23:1] main_address;
  logic        main_address_strobe_n;
  logic [2:0]  main_function_code;
  logic        main_8mhz_rise;
  logic        main_8mhz_fall;
  logic        main_8mhz_high;
  logic        address_strobe_assert;
  logic        gsp_wait_n;
  logic        msp_wait_n;
  logic        duart_dtack_n;
  logic [7:0]  primary_select_n;
  logic [3:0]  ram_select_n;
  logic [3:0]  high_speed_select_n;
  logic        rom_enable_n;
  logic        n_bus_select_n;
  logic        external_bus_select_n;
  logic        low_speed_bus_select_n;
  logic        high_speed_bus_select_n;
  logic        ram_enable_n;
  logic        duart_select_n;
  logic        zero_ram_select_n;
  logic        ram0_select_n;
  logic        ram1_select_n;
  logic        gsp_select_n;
  logic        msp_select_n;
  logic        read_high_speed_bus_n;
  logic        read_duart_n;
  logic        vpa_n;
  logic        rva;
  logic        sampled_dtack_n;
  logic        rvas0_n;
  logic        rvas_n;
  logic        dtack_n;
  logic        default_dtack_term_n;
  logic        high_speed_dtack_term_n;
  logic        duart_dtack_term_n;
  logic        rvas0_assert_event;
  logic        rvas0_release_event;
  logic        rvas_assert_event;
  logic        rvas_release_event;

  hard_drivin_main_bus_control dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .main_address_i                (main_address),
    .main_address_strobe_n_i       (main_address_strobe_n),
    .main_function_code_i          (main_function_code),
    .main_8mhz_rise_i              (main_8mhz_rise),
    .main_8mhz_fall_i              (main_8mhz_fall),
    .main_8mhz_high_i              (main_8mhz_high),
    .address_strobe_assert_i       (address_strobe_assert),
    .gsp_wait_n_i                  (gsp_wait_n),
    .msp_wait_n_i                  (msp_wait_n),
    .duart_dtack_n_i               (duart_dtack_n),
    .primary_select_n_o            (primary_select_n),
    .ram_select_n_o                (ram_select_n),
    .high_speed_select_n_o         (high_speed_select_n),
    .rom_enable_n_o                (rom_enable_n),
    .n_bus_select_n_o              (n_bus_select_n),
    .external_bus_select_n_o       (external_bus_select_n),
    .low_speed_bus_select_n_o      (low_speed_bus_select_n),
    .high_speed_bus_select_n_o     (high_speed_bus_select_n),
    .ram_enable_n_o                (ram_enable_n),
    .duart_select_n_o              (duart_select_n),
    .zero_ram_select_n_o           (zero_ram_select_n),
    .ram0_select_n_o               (ram0_select_n),
    .ram1_select_n_o               (ram1_select_n),
    .gsp_select_n_o                (gsp_select_n),
    .msp_select_n_o                (msp_select_n),
    .read_high_speed_bus_n_o       (read_high_speed_bus_n),
    .read_duart_n_o                (read_duart_n),
    .vpa_n_o                       (vpa_n),
    .rva_o                         (rva),
    .sampled_dtack_n_o             (sampled_dtack_n),
    .rvas0_n_o                     (rvas0_n),
    .rvas_n_o                      (rvas_n),
    .dtack_n_o                     (dtack_n),
    .default_dtack_term_n_o        (default_dtack_term_n),
    .high_speed_dtack_term_n_o     (high_speed_dtack_term_n),
    .duart_dtack_term_n_o          (duart_dtack_term_n),
    .rvas0_assert_event_o          (rvas0_assert_event),
    .rvas0_release_event_o         (rvas0_release_event),
    .rvas_assert_event_o           (rvas_assert_event),
    .rvas_release_event_o          (rvas_release_event)
  );

  always #5 clk = !clk;

  task automatic step(
    input logic high_level,
    input logic rise_event,
    input logic fall_event,
    input logic as_event
  );
    main_8mhz_high = high_level;
    main_8mhz_rise = rise_event;
    main_8mhz_fall = fall_event;
    address_strobe_assert = as_event;
    @(posedge clk);
    #1;
  endtask

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $error(
        "FAIL %s address=%06h high=%0b rise=%0b fall=%0b /AS=%0b primary=%08b ram=%04b high_select=%04b gsp=%0b msp=%0b duart=%0b rva=%0b sampled=%0b rvas0=%0b rvas=%0b dtack=%0b terms=%0b%0b%0b",
        message, {main_address, 1'b0}, main_8mhz_high, main_8mhz_rise,
        main_8mhz_fall, main_address_strobe_n, primary_select_n,
        ram_select_n, high_speed_select_n, gsp_select_n, msp_select_n,
        duart_select_n, rva, sampled_dtack_n, rvas0_n, rvas_n, dtack_n,
        default_dtack_term_n, high_speed_dtack_term_n,
        duart_dtack_term_n
      );
      $fatal(1);
    end
  endtask

  task automatic initialize_idle;
    initialize = 1'b1;
    main_address_strobe_n = 1'b1;
    main_8mhz_high = 1'b0;
    main_8mhz_rise = 1'b0;
    main_8mhz_fall = 1'b0;
    address_strobe_assert = 1'b0;
    gsp_wait_n = 1'b1;
    msp_wait_n = 1'b1;
    duart_dtack_n = 1'b1;
    step(1'b0, 1'b0, 1'b0, 1'b0);
    require(dtack_n && rvas0_n && rvas_n && vpa_n &&
            primary_select_n == 8'hff && ram_select_n == 4'hf &&
            high_speed_select_n == 4'hf && rom_enable_n &&
            n_bus_select_n && external_bus_select_n &&
            low_speed_bus_select_n && high_speed_bus_select_n &&
            ram_enable_n && duart_select_n && zero_ram_select_n &&
            ram0_select_n && ram1_select_n,
            "deterministic FPGA initialization is idle");
    initialize = 1'b0;
  endtask

  task automatic capture_address(input logic [23:0] byte_address);
    if (byte_address[0]) begin
      $error("FAIL fixture requires an even MC68000 byte address");
      $fatal(1);
    end
    step(1'b1, 1'b1, 1'b0, 1'b0);
    main_address = byte_address[23:1];
    main_address_strobe_n = 1'b0;
    step(1'b1, 1'b0, 1'b0, 1'b1);
    require(!rva && dtack_n && rvas0_n && rvas_n,
            "S2 address capture precedes every held-valid strobe");
  endtask

  task automatic finish_hsbus_cycle;
    // Enter with a selected HSBUS cycle after a falling edge sampled /DTACK
    // low. Retain the selection through S7, then remove /AS and sample the
    // resulting high level to release both held strobes.
    step(1'b1, 1'b1, 1'b0, 1'b0);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    main_address_strobe_n = 1'b1;
    step(1'b0, 1'b0, 1'b0, 1'b0);
    require(dtack_n && high_speed_bus_select_n && gsp_select_n &&
            msp_select_n && read_high_speed_bus_n,
            "raw /AS release removes HSBUS selection and acknowledge");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(sampled_dtack_n && rvas0_n && rvas_n &&
            rvas0_release_event && rvas_release_event,
            "sampled high /DTACK releases both HSBUS held strobes");
  endtask

  initial begin
    clk = 1'b0;
    main_address = '0;
    main_function_code = 3'b001;

    // A physical mirror exercises both ignored address bits and the GSP host
    // path. /RVAS0, not raw /HSBUS, asserts the TMS34010 HCS decode.
    initialize_idle();
    capture_address(24'hd02000);
    require(!high_speed_bus_select_n && gsp_select_n && msp_select_n &&
            read_high_speed_bus_n,
            "raw mirrored GSP address selects only the HSBUS region at S2");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!rvas0_n && !gsp_select_n && msp_select_n &&
            !read_high_speed_bus_n && !dtack_n &&
            !high_speed_dtack_term_n && rvas0_assert_event,
            "S3 qualifies mirrored GSP HCS and zero-wait acknowledge");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(rva && !rvas_n && !dtack_n && rvas_assert_event,
            "S4 asserts the second held strobe without disturbing GSP ACK");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!sampled_dtack_n && !dtack_n,
            "S5 records selected GSP acknowledgement");
    finish_hsbus_cycle();

    // The canonical MSP range reaches Y1, and only the externally owned MSP
    // HRDY level extends this access. No latency is synthesized here.
    initialize_idle();
    msp_wait_n = 1'b0;
    capture_address(24'hc04000);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!rvas0_n && gsp_select_n && !msp_select_n && dtack_n &&
            high_speed_dtack_term_n,
            "selected MSP HRDY low extends the address-driven HSBUS cycle");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(sampled_dtack_n && dtack_n && !rvas0_n && !rvas_n,
            "MSP wait leaves both held strobes active without false ACK");
    msp_wait_n = 1'b1;
    step(1'b1, 1'b0, 1'b0, 1'b0);
    require(!dtack_n && !high_speed_dtack_term_n,
            "external MSP ready release permits live acknowledgement");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!sampled_dtack_n,
            "falling 8 MHz records the late MSP acknowledgement");
    finish_hsbus_cycle();

    // The broad RAM-region LS139 mirror drives MC68681 CS only after /RVAS.
    // Its independently clocked open-drain acknowledgement stays external.
    initialize_idle();
    capture_address(24'hfe2000);
    require(!duart_select_n && read_duart_n,
            "mirrored raw DUART select waits for /RVAS qualification");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!rvas0_n && read_duart_n && dtack_n,
            "S3 /RVAS0 does not select or acknowledge the MC68681");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(rva && !rvas_n && !read_duart_n && dtack_n &&
            duart_dtack_term_n,
            "S4 /RVAS asserts MC68681 CS and preserves external wait");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(sampled_dtack_n && !rvas_n && dtack_n,
            "arbitrary DUART latency retains the held access");
    duart_dtack_n = 1'b0;
    step(1'b1, 1'b0, 1'b0, 1'b0);
    require(!dtack_n && !duart_dtack_term_n,
            "external MC68681 acknowledgement completes the live access");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!sampled_dtack_n,
            "falling 8 MHz records the late DUART acknowledgement");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    main_address_strobe_n = 1'b1;
    step(1'b0, 1'b0, 1'b0, 1'b0);
    require(dtack_n && duart_select_n && read_duart_n && !rvas_n,
            "raw DUART release suppresses a still-low open-drain pin");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(sampled_dtack_n && rvas0_n && rvas_n &&
            rvas0_release_event && rvas_release_event,
            "sampled release ends the address-driven DUART hold");

    // An ordinary expansion-bus address bypasses both peripheral terms. RVA
    // alone produces the one-period acknowledgement while /RVAS remains held
    // until the sampled low-to-high transition.
    initialize_idle();
    capture_address(24'h84c000);
    require(!external_bus_select_n && high_speed_bus_select_n &&
            duart_select_n,
            "ordinary expansion address selects no specialized peripheral");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!rvas0_n && dtack_n && default_dtack_term_n,
            "S3 early strobe does not acknowledge the ordinary bus path");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(rva && !rvas_n && !dtack_n && !default_dtack_term_n &&
            high_speed_dtack_term_n && duart_dtack_term_n,
            "S4 RVA acknowledges the address-driven ordinary bus path");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(!sampled_dtack_n && !dtack_n,
            "S5 records the ordinary RVA acknowledgement");
    step(1'b1, 1'b1, 1'b0, 1'b0);
    require(!rva && dtack_n && !rvas_n,
            "S6 removes ordinary /DTACK while retaining /RVAS");
    step(1'b0, 1'b0, 1'b1, 1'b0);
    require(sampled_dtack_n && rvas0_n && rvas_n &&
            rvas0_release_event && rvas_release_event,
            "S7 sampled release completes the ordinary expansion cycle");
    main_address_strobe_n = 1'b1;
    step(1'b0, 1'b0, 1'b0, 1'b0);
    require(external_bus_select_n && dtack_n,
            "raw /AS release returns the primary decoder to idle");

    $display("PASS tb_hard_drivin_main_bus_control");
    $finish;
  end
endmodule

`default_nettype wire
