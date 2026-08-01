`default_nettype none

module tb_hard_drivin_main_dtack_decode;
  logic        main_address_strobe_n;
  logic [2:0]  main_function_code;
  logic        rva;
  logic        high_speed_bus_select_n;
  logic        duart_select_n;
  logic        rvas0_n;
  logic        rvas_n;
  logic        gsp_wait_n;
  logic        msp_wait_n;
  logic        duart_dtack_n;
  logic        vpa_n;
  logic        read_high_speed_bus_n;
  logic        read_duart_n;
  logic        default_dtack_term_n;
  logic        high_speed_dtack_term_n;
  logic        duart_dtack_term_n;
  logic        dtack_n;

  hard_drivin_main_dtack_decode dut (
    .main_address_strobe_n_i       (main_address_strobe_n),
    .main_function_code_i          (main_function_code),
    .rva_i                         (rva),
    .high_speed_bus_select_n_i     (high_speed_bus_select_n),
    .duart_select_n_i              (duart_select_n),
    .rvas0_n_i                     (rvas0_n),
    .rvas_n_i                      (rvas_n),
    .gsp_wait_n_i                  (gsp_wait_n),
    .msp_wait_n_i                  (msp_wait_n),
    .duart_dtack_n_i               (duart_dtack_n),
    .vpa_n_o                       (vpa_n),
    .read_high_speed_bus_n_o       (read_high_speed_bus_n),
    .read_duart_n_o                (read_duart_n),
    .default_dtack_term_n_o        (default_dtack_term_n),
    .high_speed_dtack_term_n_o     (high_speed_dtack_term_n),
    .duart_dtack_term_n_o          (duart_dtack_term_n),
    .dtack_n_o                     (dtack_n)
  );

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $error(
        "FAIL %s controls=%03h fc=%01h vpa_n=%0b rhsbus_n=%0b rduart_n=%0b terms=%0b%0b%0b dtack_n=%0b",
        message,
        {main_address_strobe_n, rva, high_speed_bus_select_n,
         duart_select_n, rvas0_n, rvas_n, gsp_wait_n, msp_wait_n,
         duart_dtack_n},
        main_function_code, vpa_n, read_high_speed_bus_n, read_duart_n,
        default_dtack_term_n, high_speed_dtack_term_n,
        duart_dtack_term_n, dtack_n
      );
      $fatal(1);
    end
  endtask

  initial begin
    // Exhaust all twelve raw input bits. This validates the drawing's gates,
    // not whether every electrical combination can occur on a running board.
    for (int unsigned raw = 0; raw < 4096; raw++) begin
      logic expected_vpa_n;
      logic expected_read_high_speed_bus_n;
      logic expected_read_duart_n;
      logic expected_default_term_n;
      logic expected_high_speed_term_n;
      logic expected_duart_term_n;

      main_address_strobe_n = raw[11];
      main_function_code = raw[10:8];
      rva = raw[7];
      high_speed_bus_select_n = raw[6];
      duart_select_n = raw[5];
      rvas0_n = raw[4];
      rvas_n = raw[3];
      gsp_wait_n = raw[2];
      msp_wait_n = raw[1];
      duart_dtack_n = raw[0];
      #1;

      expected_vpa_n =
        !(main_function_code == 3'b111 && !main_address_strobe_n);
      expected_read_high_speed_bus_n =
        high_speed_bus_select_n || rvas0_n;
      expected_read_duart_n = duart_select_n || rvas_n;
      expected_default_term_n =
        !(expected_vpa_n && rva && high_speed_bus_select_n &&
          duart_select_n);
      expected_high_speed_term_n =
        expected_read_high_speed_bus_n ||
        !(gsp_wait_n && msp_wait_n);
      expected_duart_term_n = expected_read_duart_n || duart_dtack_n;

      require(vpa_n == expected_vpa_n, "LS20 /VPA equation");
      require(read_high_speed_bus_n == expected_read_high_speed_bus_n,
              "ALS32 /RHSBUS equation");
      require(read_duart_n == expected_read_duart_n,
              "ALS32 /RDUART equation");
      require(default_dtack_term_n == expected_default_term_n,
              "ordinary LS20 acknowledgement term");
      require(high_speed_dtack_term_n == expected_high_speed_term_n,
              "AS00/AS32 high-speed-bus acknowledgement term");
      require(duart_dtack_term_n == expected_duart_term_n,
              "AS32 DUART acknowledgement term");
      require(dtack_n ==
              (expected_default_term_n && expected_high_speed_term_n &&
               expected_duart_term_n),
              "F11 final /DTACK merge");
    end

    // Ordinary non-CPU-space access acknowledges only while RVA is active.
    main_address_strobe_n = 1'b0;
    main_function_code = 3'b001;
    rva = 1'b0;
    high_speed_bus_select_n = 1'b1;
    duart_select_n = 1'b1;
    rvas0_n = 1'b1;
    rvas_n = 1'b1;
    gsp_wait_n = 1'b0;
    msp_wait_n = 1'b0;
    duart_dtack_n = 1'b1;
    #1;
    require(dtack_n, "ordinary access waits before RVA");
    rva = 1'b1;
    #1;
    require(!dtack_n, "ordinary access acknowledges during RVA");

    main_function_code = 3'b111;
    #1;
    require(!vpa_n && dtack_n,
            "CPU-space cycle asserts /VPA and suppresses ordinary /DTACK");

    // The HSBUS route acknowledges only after both TMS34010 HRDY-derived
    // active-low wait nets are high. An unselected TMS34010 drives HRDY high,
    // so either selected GSP/MSP may independently extend the shared cycle.
    main_function_code = 3'b001;
    high_speed_bus_select_n = 1'b0;
    rvas0_n = 1'b0;
    gsp_wait_n = 1'b1;
    msp_wait_n = 1'b1;
    #1;
    require(!dtack_n, "selected high-speed bus acknowledges with no wait");
    gsp_wait_n = 1'b0;
    #1;
    require(dtack_n, "asserted GSP HRDY-derived wait suppresses /DTACK");
    gsp_wait_n = 1'b1;
    msp_wait_n = 1'b0;
    #1;
    require(dtack_n, "asserted MSP HRDY-derived wait suppresses /DTACK");

    high_speed_bus_select_n = 1'b1;
    rvas0_n = 1'b1;
    duart_select_n = 1'b0;
    rvas_n = 1'b0;
    duart_dtack_n = 1'b1;
    #1;
    require(dtack_n, "selected DUART waits for its /DUDTACK");
    duart_dtack_n = 1'b0;
    #1;
    require(!dtack_n, "selected DUART propagates active /DUDTACK");

    $display("PASS tb_hard_drivin_main_dtack_decode");
    $finish;
  end
endmodule

`default_nettype wire
