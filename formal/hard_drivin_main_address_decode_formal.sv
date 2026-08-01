`default_nettype none

module hard_drivin_main_address_decode_formal (
  input logic [23:1] address_i,
  input logic        address_strobe_n_i,
  input logic        rvas0_n_i
);
  logic [7:0] primary_select_n;
  logic [3:0] ram_select_n;
  logic [3:0] high_speed_select_n;
  logic rom_enable_n;
  logic n_bus_select_n;
  logic external_bus_select_n;
  logic low_speed_bus_select_n;
  logic high_speed_bus_select_n;
  logic ram_enable_n;
  logic duart_select_n;
  logic zero_ram_select_n;
  logic ram0_select_n;
  logic ram1_select_n;
  logic read_high_speed_bus_n;
  logic gsp_select_n;
  logic msp_select_n;

  hard_drivin_main_address_decode dut (
    .address_i                    (address_i),
    .address_strobe_n_i           (address_strobe_n_i),
    .rvas0_n_i                    (rvas0_n_i),
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

  always_comb begin
    for (int unsigned output_number = 0;
         output_number < 8; output_number++) begin
      assert (primary_select_n[output_number] ==
              (address_strobe_n_i ||
               (address_i[23:21] != output_number[2:0])));
    end

    assert (rom_enable_n == primary_select_n[0]);
    assert (n_bus_select_n == primary_select_n[3]);
    assert (external_bus_select_n == primary_select_n[4]);
    assert (low_speed_bus_select_n == primary_select_n[5]);
    assert (high_speed_bus_select_n == primary_select_n[6]);
    assert (ram_enable_n == primary_select_n[7]);

    assert (duart_select_n ==
            (ram_enable_n || (address_i[15:14] != 2'b00)));
    assert (zero_ram_select_n ==
            (ram_enable_n || (address_i[15:14] != 2'b01)));
    assert (ram0_select_n ==
            (ram_enable_n || (address_i[15:14] != 2'b10)));
    assert (ram1_select_n ==
            (ram_enable_n || (address_i[15:14] != 2'b11)));
    assert (read_high_speed_bus_n ==
            (high_speed_bus_select_n || rvas0_n_i));
    assert (gsp_select_n ==
            (read_high_speed_bus_n || (address_i[15:14] != 2'b00)));
    assert (msp_select_n ==
            (read_high_speed_bus_n || (address_i[15:14] != 2'b01)));
    assert ($onehot0(~primary_select_n));
    assert ($onehot0(~ram_select_n));
    assert ($onehot0(~high_speed_select_n));

    cover (!address_strobe_n_i &&
           (address_i[23:14] == 10'(24'hff0000 >> 14)) &&
           !duart_select_n);
    cover (!address_strobe_n_i && !rvas0_n_i &&
           (address_i[23:14] == 10'(24'hc00000 >> 14)) &&
           !gsp_select_n);
    cover (!address_strobe_n_i && !rvas0_n_i &&
           (address_i[23:14] == 10'(24'hc04000 >> 14)) &&
           !msp_select_n);
    cover (!address_strobe_n_i && rvas0_n_i &&
           !high_speed_bus_select_n && gsp_select_n && msp_select_n);
    cover (!address_strobe_n_i && !rom_enable_n);
    cover (!address_strobe_n_i && !external_bus_select_n);
  end
endmodule

`default_nettype wire
