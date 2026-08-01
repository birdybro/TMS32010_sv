`default_nettype none

module tb_hard_drivin_main_sound_reset_decode;
  logic        main_address_strobe_n;
  logic        main_valid_address_strobe_n;
  logic        main_read_not_write;
  logic [23:14] main_address;
  logic        external_bus_select_n;
  logic        sound_reset_address_match;
  logic        sound_reset_n;

  hard_drivin_main_sound_reset_decode dut (
    .main_address_strobe_n_i       (main_address_strobe_n),
    .main_valid_address_strobe_n_i (main_valid_address_strobe_n),
    .main_read_not_write_i         (main_read_not_write),
    .main_address_i                (main_address),
    .external_bus_select_n_o       (external_bus_select_n),
    .sound_reset_address_match_o   (sound_reset_address_match),
    .sound_reset_n_o               (sound_reset_n)
  );

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $error(
        "FAIL %s address=%06h as_n=%0b rvas_n=%0b rnw=%0b extb_n=%0b match=%0b sres_n=%0b",
        message, {main_address, 14'h0000}, main_address_strobe_n,
        main_valid_address_strobe_n, main_read_not_write,
        external_bus_select_n, sound_reset_address_match, sound_reset_n
      );
      $fatal(1);
    end
  endtask

  initial begin
    main_address = 10'h000;
    main_address_strobe_n = 1'b1;
    main_valid_address_strobe_n = 1'b1;
    main_read_not_write = 1'b1;

    // Exhaust the ten decoded high address bits and all strobe/direction
    // combinations. A13:A1 remain outside the physical logic cone.
    for (int unsigned high_address = 0;
         high_address < 1024; high_address++) begin
      for (int unsigned controls = 0; controls < 8; controls++) begin
        logic expected_external_bus_n;
        logic expected_address_match;
        logic expected_sound_reset_n;
        main_address = high_address[9:0];
        main_address_strobe_n = controls[2];
        main_valid_address_strobe_n = controls[1];
        main_read_not_write = controls[0];
        #1;
        expected_external_bus_n =
          controls[2] || (high_address[9:7] != 3'b100);
        expected_address_match =
          high_address[6:0] == 7'b0010011;
        expected_sound_reset_n =
          expected_external_bus_n || controls[1] || controls[0] ||
          !expected_address_match;
        require(external_bus_select_n == expected_external_bus_n,
                "SP-327 /EXTBUS decode");
        require(sound_reset_address_match == expected_address_match,
                "A044427 /SRES address group");
        require(sound_reset_n == expected_sound_reset_n,
                "combined active-low /SRES decode");
      end
    end

    main_address_strobe_n = 1'b0;
    main_valid_address_strobe_n = 1'b0;
    main_read_not_write = 1'b0;
    main_address = 10'(24'h84c000 >> 14);
    #1;
    require(!sound_reset_n,
            "canonical 0x84c000 main write selects /SRES");

    main_address = 10'(24'h84fffe >> 14);
    #1;
    require(!sound_reset_n,
            "top even address in the physical 16 KiB mirror selects /SRES");

    main_read_not_write = 1'b1;
    #1;
    require(sound_reset_n,
            "reads through the matching address window do not select /SRES");

    main_read_not_write = 1'b0;
    main_address_strobe_n = 1'b1;
    #1;
    require(sound_reset_n,
            "inactive main /AS removes /EXTBUS and /SRES");

    main_address_strobe_n = 1'b0;
    main_valid_address_strobe_n = 1'b1;
    #1;
    require(sound_reset_n,
            "inactive main /RVAS removes /SRES");

    $display("PASS tb_hard_drivin_main_sound_reset_decode");
    $finish;
  end
endmodule

`default_nettype wire
