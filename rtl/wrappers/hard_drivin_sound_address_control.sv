`default_nettype none

// FPGA boundary for A044427's four cascaded LS191 sound-address counters and
// separate port-6 block latch. initialize_i supplies deterministic FPGA state
// only; physical processor reset does not reach these components.
module hard_drivin_sound_address_control (
  input  logic        clk_i,
  input  logic        initialize_i,
  input  logic [2:0]  io_port_i,
  input  logic        io_read_i,
  input  logic        io_write_i,
  input  logic [15:0] io_write_data_i,
  input  logic        io_commit_i,
  output logic [15:0] sound_address_o,
  output logic        sound_address_valid_o,
  output logic [3:0]  sound_rom_block_o,
  output logic        sound_rom_block_valid_o
);
  always_ff @(posedge clk_i) begin
    if (initialize_i) begin
      sound_address_o         <= 16'h0000;
      sound_address_valid_o   <= 1'b0;
      sound_rom_block_o       <= 4'h0;
      sound_rom_block_valid_o <= 1'b0;
    end else if (io_commit_i) begin
      // Every physical input transaction clocks /PDEN low then high. The
      // LS191 chain therefore increments regardless of which input port was
      // selected. Invalid initial state remains explicitly invalid.
      if (io_read_i) begin
        sound_address_o <= sound_address_o + 16'h0001;
      end else if (io_write_i) begin
        case (io_port_i)
          3'd6: begin
            sound_rom_block_o       <= io_write_data_i[3:0];
            sound_rom_block_valid_o <= 1'b1;
          end
          3'd7: begin
            sound_address_o       <= io_write_data_i;
            sound_address_valid_o <= 1'b1;
          end
          default: begin
          end
        endcase
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (!initialize_i) begin
      assert (!io_commit_i || (io_read_i ^ io_write_i));
    end
  end
endmodule

`default_nettype wire
