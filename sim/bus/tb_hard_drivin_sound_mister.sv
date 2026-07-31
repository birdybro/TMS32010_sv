`default_nettype none

module tb_hard_drivin_sound_mister;
  logic        clk;
  logic        initialize;
  logic        clock_enable;
  logic        dsp_reset_n;
  logic        host_program_select_n;
  logic        host_write;
  logic        host_commit;
  logic [11:0] host_address;
  logic [15:0] host_write_data;
  logic [15:0] host_read_data;
  logic        host_ready;
  logic        host_access_permitted;
  logic        ownership_conflict;
  logic [2:0]  io_port;
  logic        io_read;
  logic        io_write;
  logic [15:0] io_write_data;
  logic        io_commit;
  logic [15:0] io_read_data;
  logic        debug_data_write;
  logic [7:0]  debug_data_address;
  logic [15:0] debug_data;
  logic        reset_active;
  logic        memory_wait;
  logic        phase_advance;
  logic [1:0]  phase;
  logic        clkout;
  logic [11:0] native_address;
  logic        men_n;
  logic        den_n;
  logic        we_n;
  logic        native_bus_active;
  logic        tms_access_permitted;
  logic        execute_valid;
  logic [11:0] execute_address;
  logic [15:0] execute_word;
  logic        pipeline_blocked;
  logic [11:0] pc;
  logic [31:0] accumulator;
  logic        retired;
  logic        illegal;
  logic [31:0] cycle_count;

  logic [15:0] output_ports [0:7];
  integer      io_read_count;
  integer      io_write_count;

  hard_drivin_sound_mister dut (
    .clk_i                         (clk),
    .initialize_i                  (initialize),
    .clock_enable_i                (clock_enable),
    .dsp_reset_n_i                 (dsp_reset_n),
    .bio_i                         (1'b0),
    .host_program_select_n_i       (host_program_select_n),
    .host_write_i                  (host_write),
    .host_commit_i                 (host_commit),
    .host_address_i                (host_address),
    .host_write_data_i             (host_write_data),
    .host_read_data_o              (host_read_data),
    .host_ready_o                  (host_ready),
    .host_access_permitted_o       (host_access_permitted),
    .ownership_conflict_o          (ownership_conflict),
    .io_port_o                     (io_port),
    .io_read_o                     (io_read),
    .io_write_o                    (io_write),
    .io_write_data_o               (io_write_data),
    .io_commit_o                   (io_commit),
    .io_read_data_i                (io_read_data),
    .io_ready_i                    (1'b1),
    .debug_data_write_i            (debug_data_write),
    .debug_data_address_i          (debug_data_address),
    .debug_data_i                  (debug_data),
    .debug_data_address_o          (),
    .debug_data_read_o             (),
    .debug_data_write_o            (),
    .debug_data_address_valid_o    (),
    .debug_data_write_address_o    (),
    .debug_data_read_data_o        (),
    .debug_data_write_data_o       (),
    .reset_active_o                (reset_active),
    .memory_wait_o                 (memory_wait),
    .phase_advance_o               (phase_advance),
    .phase_o                       (phase),
    .clkout_o                      (clkout),
    .native_address_o              (native_address),
    .native_men_n_o                (men_n),
    .native_den_n_o                (den_n),
    .native_we_n_o                 (we_n),
    .native_sample_o               (),
    .native_bus_active_o           (native_bus_active),
    .tms_access_permitted_o        (tms_access_permitted),
    .execute_valid_o               (execute_valid),
    .execute_address_o             (execute_address),
    .execute_word_o                (execute_word),
    .pipeline_blocked_o            (pipeline_blocked),
    .pc_o                          (pc),
    .accumulator_o                 (accumulator),
    .t_register_o                  (),
    .product_register_o            (),
    .auxiliary_register_0_o        (),
    .auxiliary_register_1_o        (),
    .auxiliary_register_pointer_o  (),
    .data_page_pointer_o           (),
    .stack_top_o                    (),
    .stack_level_1_o                (),
    .stack_level_2_o                (),
    .stack_bottom_o                 (),
    .overflow_flag_o               (),
    .overflow_mode_o               (),
    .interrupt_mask_o              (),
    .interrupt_pending_o           (),
    .instruction_valid_o           (),
    .retired_o                     (retired),
    .illegal_o                     (illegal),
    .cycle_count_o                 (cycle_count)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  always_comb begin
    case (io_port)
      3'd0: io_read_data = 16'h6a80;
      3'd1: io_read_data = 16'h55aa;
      3'd2: io_read_data = 16'h0000;
      default: io_read_data = 16'hffff;
    endcase
  end

  always_ff @(posedge clk) begin
    if (initialize) begin
      io_read_count  <= 0;
      io_write_count <= 0;
      for (int unsigned port = 0; port < 8; port++) begin
        output_ports[port] <= 16'h0000;
      end
    end else if (io_commit) begin
      if (io_read) begin
        io_read_count <= io_read_count + 1;
      end
      if (io_write) begin
        io_write_count <= io_write_count + 1;
        output_ports[io_port] <= io_write_data;
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

  function automatic logic [15:0] smoke_word(input logic [3:0] address);
    case (address)
      4'h0: smoke_word = 16'h4810;
      4'h1: smoke_word = 16'h4120;
      4'h2: smoke_word = 16'h4b11;
      4'h3: smoke_word = 16'h4c12;
      4'h4: smoke_word = 16'h4d13;
      4'h5: smoke_word = 16'h4e14;
      4'h6: smoke_word = 16'h4f15;
      4'h7: smoke_word = 16'h4021;
      4'h8: smoke_word = 16'h4222;
      4'h9: smoke_word = 16'hf600;
      4'ha: smoke_word = 16'h000c;
      4'hb: smoke_word = 16'h7eee;
      4'hc: smoke_word = 16'h2020;
      4'hd: smoke_word = 16'h7f80;
      default: smoke_word = 16'h7f83;
    endcase
  endfunction

  task automatic host_write_word(
    input logic [11:0] address,
    input logic [15:0] data
  );
    host_write      = 1'b1;
    host_address    = address;
    host_write_data = data;
    host_commit     = 1'b1;
    #1;
    require(host_ready && host_access_permitted,
            "host write is accepted only in reset-qualified ownership");
    tick();
    host_commit = 1'b0;
  endtask

  task automatic debug_write_word(
    input logic [7:0] address,
    input logic [15:0] data
  );
    debug_data_address = address;
    debug_data = data;
    debug_data_write = 1'b1;
    tick();
    debug_data_write = 1'b0;
  endtask

  task automatic release_and_check_reset;
    int unsigned falling_boundaries;
    logic previous_clkout;
    logic previous_reset_active;

    host_program_select_n = 1'b1;
    tick();
    require(!host_access_permitted && !tms_access_permitted,
            "safe handoff disables host before reset release");
    dsp_reset_n = 1'b1;
    falling_boundaries = 0;
    for (int unsigned elapsed = 0; elapsed < 32; elapsed++) begin
      previous_clkout       = clkout;
      previous_reset_active = reset_active;
      tick();
      if (previous_reset_active && previous_clkout && !clkout) begin
        falling_boundaries++;
      end
      if (!reset_active) begin
        break;
      end
    end
    require(falling_boundaries == 5,
            "physical reset release retains the five-cycle modeled hold");
    require((phase == 2'd0) && !clkout && native_address == 12'h000,
            "reset release preserves native phase and address-zero state");
    require(tms_access_permitted && !ownership_conflict,
            "DSP owns RAM after safe reset release");
  endtask

  task automatic run_until_retired(input int unsigned target);
    int unsigned count;
    count = 0;
    for (int unsigned elapsed = 0; elapsed < 1200; elapsed++) begin
      tick();
      require(!ownership_conflict, "execution never overlaps host ownership");
      require(!illegal, "synthetic integration program remains legal");
      if (retired) begin
        count++;
      end
      if (count == target) begin
        return;
      end
    end
    $fatal(1, "retirement target was not reached");
  endtask

  initial begin
    initialize = 1'b1;
    clock_enable = 1'b1;
    dsp_reset_n = 1'b0;
    host_program_select_n = 1'b1;
    host_write = 1'b0;
    host_commit = 1'b0;
    host_address = 12'h000;
    host_write_data = 16'h0000;
    debug_data_write = 1'b0;
    debug_data_address = 8'h00;
    debug_data = 16'h0000;
    tick();
    initialize = 1'b0;
    tick();

    require(reset_active && !native_bus_active && men_n && den_n && we_n,
            "held physical reset keeps every TMS native strobe inactive");

    // The host loads the project-authored ROM-free board smoke program while
    // /320RES is asserted. Address 14 is an explicit conservative park word.
    host_program_select_n = 1'b0;
    for (int unsigned address = 0; address < 15; address++) begin
      host_write_word(address[11:0], smoke_word(address[3:0]));
    end

    debug_write_word(8'h10, 16'hf230);
    debug_write_word(8'h11, 16'h00a5);
    debug_write_word(8'h12, 16'h0001);
    debug_write_word(8'h13, 16'h0000);
    debug_write_word(8'h14, 16'h000b);
    debug_write_word(8'h15, 16'h3456);

    release_and_check_reset();
    run_until_retired(12);

    require(io_write_count == 6 && io_read_count == 3,
            "board smoke completes six physical writes and three reads");
    require(output_ports[0] == 16'hf230,
            "port zero receives the raw primary-backed DAC word");
    require(output_ports[3] == 16'h00a5 &&
            output_ports[4] == 16'h0001 &&
            output_ports[5] == 16'h0000 &&
            output_ports[6] == 16'h000b &&
            output_ports[7] == 16'h3456,
            "all synthetic board control outputs match the fixed fixture");
    require(accumulator == 32'h0000_55aa && cycle_count == 32'd22,
            "host-loaded smoke reaches the fixed accumulator and cycle total");
    require(pc == 12'h00e,
            "BIOZ skips the sentinel and retires the expected final NOP");

    // Reset, reload a minimal program, and prove that a low-address TBLW is
    // acknowledged by the physical I/O callback without modifying RAM[3].
    dsp_reset_n = 1'b0;
    tick();
    require(reset_active && !tms_access_permitted,
            "reasserted /320RES immediately disables the physical TMS path");
    for (int unsigned elapsed = 0; elapsed < 4; elapsed++) begin
      if (!native_bus_active) begin
        break;
      end
      tick();
    end
    require(!native_bus_active,
            "processor recognizes reset at its documented falling boundary");
    host_program_select_n = 1'b0;
    host_write_word(12'h000, 16'h7e03);  // LACK 3
    host_write_word(12'h001, 16'h7d10);  // TBLW 0x10 -> address ACC=3
    host_write_word(12'h002, 16'h7f80);  // repeated NOP
    host_write_word(12'h003, 16'h7f83);  // conservative park word

    release_and_check_reset();
    run_until_retired(3);
    require(io_write_count == 7 && output_ports[3] == 16'hf230,
            "low-address TBLW commits exactly once through output port three");
    require(cycle_count == 32'd5,
            "LACK/TBLW/NOP consumes the documented five cycles");
    require(execute_valid && execute_address == 12'h003 &&
            execute_word == 16'h7f83 && pipeline_blocked,
            "unchanged address-three park word proves TBLW did not write RAM");
    require(!memory_wait && !phase_advance && pipeline_blocked,
            "unsupported park is distinct from a callback wait");

    dsp_reset_n = 1'b0;
    tick();
    host_program_select_n = 1'b0;
    host_write = 1'b0;
    host_address = 12'h003;
    #1;
    require(!host_ready, "host read waits for the synchronous RAM response");
    tick();
    require(host_ready && host_read_data == 16'h7f83,
            "host reads the unchanged low-address park word after reset");

    $display("PASS tb_hard_drivin_sound_mister");
    $finish;
  end
endmodule

`default_nettype wire
