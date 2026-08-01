`default_nettype none

module tb_hard_drivin_main_address_decode;
  logic [23:1] address;
  logic        address_strobe_n;
  logic        rvas0_n;
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
  logic        read_high_speed_bus_n;
  logic        gsp_select_n;
  logic        msp_select_n;

  hard_drivin_main_address_decode dut (
    .address_i                    (address),
    .address_strobe_n_i           (address_strobe_n),
    .rvas0_n_i                    (rvas0_n),
    .primary_select_n_o           (primary_select_n),
    .ram_select_n_o               (ram_select_n),
    .high_speed_select_n_o        (high_speed_select_n),
    .rom_enable_n_o               (rom_enable_n),
    .n_bus_select_n_o             (n_bus_select_n),
    .external_bus_select_n_o      (external_bus_select_n),
    .low_speed_bus_select_n_o     (low_speed_bus_select_n),
    .high_speed_bus_select_n_o    (high_speed_bus_select_n),
    .ram_enable_n_o               (ram_enable_n),
    .duart_select_n_o             (duart_select_n),
    .zero_ram_select_n_o          (zero_ram_select_n),
    .ram0_select_n_o              (ram0_select_n),
    .ram1_select_n_o              (ram1_select_n),
    .read_high_speed_bus_n_o      (read_high_speed_bus_n),
    .gsp_select_n_o               (gsp_select_n),
    .msp_select_n_o               (msp_select_n)
  );

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $error(
        "FAIL %s address=%06h /AS=%0b /RVAS0=%0b primary=%08b ram=%04b high=%04b",
        message, {address, 1'b0}, address_strobe_n, rvas0_n,
        primary_select_n, ram_select_n, high_speed_select_n
      );
      $fatal(1);
    end
  endtask

  task automatic set_byte_address(input logic [23:0] byte_address);
    if (byte_address[0]) begin
      $error("FAIL test fixture requires an even MC68000 byte address");
      $fatal(1);
    end
    address = byte_address[23:1];
    #1;
  endtask

  initial begin
    address = '0;
    address_strobe_n = 1'b1;
    rvas0_n = 1'b1;
    #1;

    // Exhaust the ten address bits consumed across all three decoders and
    // both control levels. Expected vectors are built independently from the
    // LS138/LS139 function tables.
    for (int unsigned high_address = 0;
         high_address < 1024; high_address++) begin
      for (int unsigned controls = 0; controls < 4; controls++) begin
        logic [7:0] expected_primary_n;
        logic [3:0] expected_ram_n;
        logic [3:0] expected_high_speed_n;
        logic expected_read_high_speed_n;

        address = '0;
        address[23:14] = high_address[9:0];
        address_strobe_n = controls[1];
        rvas0_n = controls[0];
        #1;

        expected_primary_n = 8'hff;
        if (!controls[1]) begin
          expected_primary_n[high_address[9:7]] = 1'b0;
        end

        expected_ram_n = 4'hf;
        if (!expected_primary_n[7]) begin
          expected_ram_n[high_address[1:0]] = 1'b0;
        end

        expected_read_high_speed_n =
          expected_primary_n[6] || controls[0];
        expected_high_speed_n = 4'hf;
        if (!expected_read_high_speed_n) begin
          expected_high_speed_n[high_address[1:0]] = 1'b0;
        end

        require(primary_select_n == expected_primary_n,
                "LS138 160K primary decode");
        require(ram_select_n == expected_ram_n,
                "first LS139 180E RAM subdecode");
        require(high_speed_select_n == expected_high_speed_n,
                "second LS139 180E HSBUS subdecode");
        require(rom_enable_n == expected_primary_n[0] &&
                n_bus_select_n == expected_primary_n[3] &&
                external_bus_select_n == expected_primary_n[4] &&
                low_speed_bus_select_n == expected_primary_n[5] &&
                high_speed_bus_select_n == expected_primary_n[6] &&
                ram_enable_n == expected_primary_n[7],
                "named primary output aliases");
        require(duart_select_n == expected_ram_n[0] &&
                zero_ram_select_n == expected_ram_n[1] &&
                ram0_select_n == expected_ram_n[2] &&
                ram1_select_n == expected_ram_n[3],
                "named RAM output aliases");
        require(read_high_speed_bus_n == expected_read_high_speed_n &&
                gsp_select_n == expected_high_speed_n[0] &&
                msp_select_n == expected_high_speed_n[1],
                "qualified HSBUS output aliases");
      end
    end

    address_strobe_n = 1'b0;
    rvas0_n = 1'b0;

    set_byte_address(24'hff0000);
    require(!duart_select_n && zero_ram_select_n &&
            ram0_select_n && ram1_select_n,
            "canonical MAME DUART base selects physical Y0");
    set_byte_address(24'hfe2000);
    require(!duart_select_n,
            "DUART chip select ignores A20:A16 and A13:A1");
    set_byte_address(24'hff4000);
    require(!zero_ram_select_n, "canonical zero RAM base selects Y1");
    set_byte_address(24'hff8000);
    require(!ram0_select_n, "canonical RAM0 base selects Y2");
    set_byte_address(24'hffc000);
    require(!ram1_select_n, "canonical RAM1 base selects Y3");

    set_byte_address(24'hc00000);
    require(!gsp_select_n && msp_select_n,
            "canonical GSP host window selects Y0");
    set_byte_address(24'hd02000);
    require(!gsp_select_n,
            "GSP chip select ignores A20:A16 and A13:A1");
    set_byte_address(24'hc04000);
    require(gsp_select_n && !msp_select_n,
            "canonical MSP host window selects Y1");
    set_byte_address(24'hc08000);
    require(high_speed_select_n == 4'b1011,
            "unconnected HSBUS Y2 encoding remains observable");
    set_byte_address(24'hc0c000);
    require(high_speed_select_n == 4'b0111,
            "unconnected HSBUS Y3 encoding remains observable");

    rvas0_n = 1'b1;
    set_byte_address(24'hc00000);
    require(!high_speed_bus_select_n && read_high_speed_bus_n &&
            gsp_select_n && msp_select_n,
            "raw HSBUS waits for early /RVAS0 qualification");

    address_strobe_n = 1'b1;
    rvas0_n = 1'b0;
    #1;
    require(primary_select_n == 8'hff && ram_select_n == 4'hf &&
            high_speed_select_n == 4'hf,
            "inactive /AS removes every downstream selection");

    $display("PASS tb_hard_drivin_main_address_decode");
    $finish;
  end
endmodule

`default_nettype wire
