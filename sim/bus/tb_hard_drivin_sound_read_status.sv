`timescale 1ns/1ps
`default_nettype none

module tb_hard_drivin_sound_read_status;
  logic        main_flag;
  logic        main_flag_valid;
  logic        sound_flag;
  logic        sound_flag_valid;
  logic        sound_test;
  logic        sound_test_valid;
  logic        tirdy_n;
  logic        tirdy_n_valid;
  logic [15:0] host_read_data;
  logic [15:0] host_driven_mask;
  logic [15:0] host_valid_mask;

  hard_drivin_sound_read_status dut (
    .main_flag_i          (main_flag),
    .main_flag_valid_i    (main_flag_valid),
    .sound_flag_i         (sound_flag),
    .sound_flag_valid_i   (sound_flag_valid),
    .sound_test_i         (sound_test),
    .sound_test_valid_i   (sound_test_valid),
    .tirdy_n_i            (tirdy_n),
    .tirdy_n_valid_i      (tirdy_n_valid),
    .host_read_data_o     (host_read_data),
    .host_driven_mask_o   (host_driven_mask),
    .host_valid_mask_o    (host_valid_mask)
  );

  task automatic require(input logic condition, input string message);
    if (!condition) begin
      $fatal(1, "%s", message);
    end
  endtask

  initial begin
    for (int unsigned value = 0; value < 16; value++) begin
      for (int unsigned valid = 0; valid < 16; valid++) begin
        main_flag        = value[3];
        sound_flag       = value[2];
        sound_test       = value[1];
        tirdy_n          = value[0];
        main_flag_valid  = valid[3];
        sound_flag_valid = valid[2];
        sound_test_valid = valid[1];
        tirdy_n_valid    = valid[0];
        #1;

        require(host_driven_mask == 16'hf000,
                "/READSTAT physically drives only D15:D12");
        require(host_valid_mask == {valid[3:0], 12'h000},
                "each raw status source controls only its own valid lane");
        require(host_read_data == {
                  value[3:0] & valid[3:0], 12'h000
                },
                "carrier clamps invalid sources and undriven lanes to zero");
      end
    end

    main_flag = 1'b1;
    main_flag_valid = 1'b1;
    sound_flag = 1'b0;
    sound_flag_valid = 1'b1;
    sound_test = 1'b1;
    sound_test_valid = 1'b1;
    tirdy_n = 1'b0;
    tirdy_n_valid = 1'b1;
    #1;
    require(host_read_data == 16'ha000 &&
            host_valid_mask == 16'hf000,
            "raw polarity maps MAINFLAG/SOUNDFLAG/SOUND.TEST-/TIRDY exactly");

    $display("PASS tb_hard_drivin_sound_read_status");
    $finish;
  end
endmodule

`default_nettype wire
