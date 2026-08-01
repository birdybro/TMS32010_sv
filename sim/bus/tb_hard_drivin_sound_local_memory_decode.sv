`default_nettype none

module tb_hard_drivin_sound_local_memory_decode;
  logic [23:1] address;
  logic        address_strobe_n;
  logic        rva;
  logic        rvas_n;
  logic        read_not_write;
  logic        upper_data_strobe_n;
  logic        lower_data_strobe_n;

  logic [7:0]  high_bank_select_n;
  logic        rom_select_n;
  logic        rvf_select_n;
  logic        program_bank_select_n;
  logic        communication_bank_select_n;
  logic        local_ram_select_n;
  logic        host_program_select_n;
  logic        host_communication_select_n;
  logic        host_program_ram_chip_enable_n;
  logic        host_program_ram_write_n;
  logic        host_program_io_write_enable_n;
  logic        host_program_io_data_enable_n;
  logic        host_program_ram_read;
  logic        host_program_ram_write;
  logic        host_program_io_read;
  logic        host_program_io_write;
  logic        read_output_enable_n;
  logic        read_write_strobe_n;
  logic        upper_write_enable_n;
  logic        lower_write_enable_n;
  logic        rom_read;
  logic        local_ram_read;
  logic        local_ram_upper_write;
  logic        local_ram_lower_write;
  logic [15:0] rom_read_driven_mask;
  logic [15:0] local_ram_read_driven_mask;
  logic [14:0] populated_rom_word_address;
  logic [11:0] host_program_word_address;
  logic [12:0] local_ram_word_address;

  hard_drivin_sound_local_memory_decode dut (
    .address_i                         (address),
    .address_strobe_n_i                (address_strobe_n),
    .rva_i                             (rva),
    .rvas_n_i                          (rvas_n),
    .read_not_write_i                  (read_not_write),
    .upper_data_strobe_n_i             (upper_data_strobe_n),
    .lower_data_strobe_n_i             (lower_data_strobe_n),
    .high_bank_select_n_o              (high_bank_select_n),
    .rom_select_n_o                    (rom_select_n),
    .rvf_select_n_o                    (rvf_select_n),
    .program_bank_select_n_o           (program_bank_select_n),
    .communication_bank_select_n_o     (communication_bank_select_n),
    .local_ram_select_n_o              (local_ram_select_n),
    .host_program_select_n_o           (host_program_select_n),
    .host_communication_select_n_o     (host_communication_select_n),
    .host_program_ram_chip_enable_n_o  (host_program_ram_chip_enable_n),
    .host_program_ram_write_n_o        (host_program_ram_write_n),
    .host_program_io_write_enable_n_o  (host_program_io_write_enable_n),
    .host_program_io_data_enable_n_o   (host_program_io_data_enable_n),
    .host_program_ram_read_o           (host_program_ram_read),
    .host_program_ram_write_o          (host_program_ram_write),
    .host_program_io_read_o            (host_program_io_read),
    .host_program_io_write_o           (host_program_io_write),
    .read_output_enable_n_o            (read_output_enable_n),
    .read_write_strobe_n_o             (read_write_strobe_n),
    .upper_write_enable_n_o            (upper_write_enable_n),
    .lower_write_enable_n_o            (lower_write_enable_n),
    .rom_read_o                        (rom_read),
    .local_ram_read_o                  (local_ram_read),
    .local_ram_upper_write_o           (local_ram_upper_write),
    .local_ram_lower_write_o           (local_ram_lower_write),
    .rom_read_driven_mask_o            (rom_read_driven_mask),
    .local_ram_read_driven_mask_o      (local_ram_read_driven_mask),
    .populated_rom_word_address_o      (populated_rom_word_address),
    .host_program_word_address_o       (host_program_word_address),
    .local_ram_word_address_o          (local_ram_word_address)
  );

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $error("FAIL %s", message);
      $fatal(1);
    end
  endtask

  initial begin
    address = '0;
    address_strobe_n = 1'b1;
    rva = 1'b0;
    rvas_n = 1'b1;
    read_not_write = 1'b1;
    upper_data_strobe_n = 1'b1;
    lower_data_strobe_n = 1'b1;
    #1;

    // Exhaust every control-relevant input. A22:A17 are deliberately varied
    // through all 64 values to prove the aliases that LS138 30P does not see.
    for (int unsigned as_value = 0; as_value < 2; as_value++) begin
      for (int unsigned rva_value = 0; rva_value < 2; rva_value++) begin
        for (int unsigned rvas_value = 0; rvas_value < 2; rvas_value++) begin
          for (int unsigned a23 = 0; a23 < 2; a23++) begin
            for (int unsigned alias_bits = 0; alias_bits < 64; alias_bits++) begin
              for (int unsigned bank = 0; bank < 8; bank++) begin
                for (int unsigned a13 = 0; a13 < 2; a13++) begin
                  for (int unsigned rw = 0; rw < 2; rw++) begin
                    for (int unsigned lanes = 0; lanes < 4; lanes++) begin
                      logic [7:0] expected_bank_select_n;
                      logic expected_rom_select_n;
                      logic expected_ram_select_n;
                      logic expected_read_output_enable_n;
                      logic expected_read_write_strobe_n;
                      logic expected_upper_write_enable_n;
                      logic expected_lower_write_enable_n;

                      address = '0;
                      address[23] = a23[0];
                      address[22:17] = alias_bits[5:0];
                      address[16:14] = bank[2:0];
                      address[13] = a13[0];
                      address_strobe_n = as_value[0];
                      rva = rva_value[0];
                      rvas_n = rvas_value[0];
                      read_not_write = rw[0];
                      upper_data_strobe_n = lanes[1];
                      lower_data_strobe_n = lanes[0];
                      #1;

                      expected_bank_select_n = 8'hff;
                      if (!as_value[0] && a23[0]) begin
                        expected_bank_select_n[bank] = 1'b0;
                      end
                      expected_rom_select_n = a23[0] || as_value[0];
                      expected_ram_select_n = expected_bank_select_n[7];
                      expected_read_output_enable_n = !rw[0];
                      expected_read_write_strobe_n = rvas_value[0] || rw[0];
                      expected_upper_write_enable_n =
                        lanes[1] || expected_read_write_strobe_n;
                      expected_lower_write_enable_n =
                        lanes[0] || expected_read_write_strobe_n;

                      require(high_bank_select_n == expected_bank_select_n,
                              "LS138 high-bank decode and aliases");
                      require(rom_select_n == expected_rom_select_n,
                              "EPROM select uses only A23 and /AS");
                      require(rvf_select_n == expected_bank_select_n[4],
                              "Y4 is /RVF");
                      require(program_bank_select_n == expected_bank_select_n[5],
                              "Y5 is raw program-RAM bank");
                      require(communication_bank_select_n ==
                              expected_bank_select_n[6],
                              "Y6 is raw communication-RAM bank");
                      require(local_ram_select_n == expected_ram_select_n,
                              "Y7 is local RAM");
                      require(host_program_select_n ==
                              (expected_bank_select_n[5] || rvas_value[0]),
                              "/320RAM is qualified by /RVAS");
                      require(host_communication_select_n ==
                              (expected_bank_select_n[6] || rvas_value[0]),
                              "/320COM is qualified by /RVAS");
                      require(host_program_ram_chip_enable_n ==
                              (expected_bank_select_n[5] || rvas_value[0] ||
                               address[13]),
                              "lower Y5 half drives /RAMCE during RVAS");
                      require(host_program_ram_write_n ==
                              (expected_bank_select_n[5] || rvas_value[0] ||
                               rw[0]),
                              "program /RAMWR follows R/W while Y5 is selected");
                      require(host_program_io_write_enable_n ==
                              (expected_bank_select_n[5] || rvas_value[0] ||
                               !(rva_value[0] && !rw[0] && address[13])),
                              "upper Y5 write makes /PWE from RVA");
                      require(host_program_io_data_enable_n ==
                              (expected_bank_select_n[5] || rvas_value[0] ||
                               !(!rvas_value[0] && rw[0] && address[13])),
                              "upper Y5 read makes /PDEN during RVAS");
                      require(host_program_ram_read ==
                              (!host_program_ram_chip_enable_n && rw[0]),
                              "lower Y5 program-RAM read");
                      require(host_program_ram_write ==
                              (!host_program_ram_chip_enable_n && !rw[0]),
                              "lower Y5 program-RAM write");
                      require(host_program_io_read ==
                              !host_program_io_data_enable_n,
                              "upper Y5 direct-I/O read");
                      require(host_program_io_write ==
                              !host_program_io_write_enable_n,
                              "upper Y5 direct-I/O write");
                      require(read_output_enable_n ==
                              expected_read_output_enable_n,
                              "/RWNB is the inverted R/W level");
                      require(read_write_strobe_n ==
                              expected_read_write_strobe_n,
                              "/RWS is R/W OR /RVAS");
                      require(upper_write_enable_n ==
                              expected_upper_write_enable_n,
                              "upper /WE includes /UDS");
                      require(lower_write_enable_n ==
                              expected_lower_write_enable_n,
                              "lower /WE includes /LDS");
                      require(rom_read ==
                              (!expected_rom_select_n && rw[0]),
                              "selected read enables both EPROM slices");
                      require(local_ram_read ==
                              (!expected_ram_select_n && rw[0]),
                              "selected read enables both local-RAM slices");
                      require(local_ram_upper_write ==
                              (!expected_ram_select_n &&
                               !expected_upper_write_enable_n),
                              "upper local-RAM write lane");
                      require(local_ram_lower_write ==
                              (!expected_ram_select_n &&
                               !expected_lower_write_enable_n),
                              "lower local-RAM write lane");
                      require(rom_read_driven_mask ==
                              (rom_read ? 16'hffff : 16'h0000),
                              "EPROM read drives a complete word");
                      require(local_ram_read_driven_mask ==
                              (local_ram_read ? 16'hffff : 16'h0000),
                              "local-RAM read drives a complete word");
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    // The populated 27256 pair ignores A16 and all higher alias bits but uses
    // A15:A1. The 6264 pair uses only A13:A1.
    address = 23'h012345;
    #1;
    require(populated_rom_word_address == address[15:1],
            "populated EPROM word-address projection");
    require(host_program_word_address == address[12:1],
            "host program-path word-address projection");
    require(local_ram_word_address == address[13:1],
            "local-RAM word-address projection");
    address[22:16] = ~address[22:16];
    #1;
    require(populated_rom_word_address == 15'h2345,
            "EPROM address mirrors across A22:A16");
    address[15:14] = ~address[15:14];
    #1;
    require(local_ram_word_address == 13'h0345,
            "local RAM ignores A23:A14 within selected bank");

    $display("PASS tb_hard_drivin_sound_local_memory_decode");
    $finish;
  end
endmodule

`default_nettype wire
