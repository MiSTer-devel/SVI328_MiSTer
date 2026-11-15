// SVI-318/328 CAS player.
//
// A CAS file holds the bytes the BIOS reads, but not the tape's leader or the
// framing. Every block starts with 16 x 55h + 7Fh (the end of the leader and
// the sync byte). This player turns the file back into the bit stream the
// BIOS expects, the way MAME (svi_cas.cpp) and openMSX (CasImage.cc) do:
//
//   - wherever the next 17 bytes are 16 x 55h + 7Fh (at any offset): a leader
//     of LEAD_BYTES x 55h without start bits, then 7Fh without a start bit
//     (the BIOS syncs on 01111111 at 0x2149 after measuring the leader's
//     polarity at 0x2117);
//   - every other byte: a 0 start bit and 8 data bits, MSB first.
//
// The search runs on the bytes themselves, so it does not depend on where the
// motor last started: the BIOS stops the motor after each header and wherever
// a CLOAD ends, and the old player (fixed offsets 00-10h / 23-33h counted from
// the last motor start) lost sync on the next block when that happened
// (issue #2: Mr. Do!, Robocop, Kung Fu Master).
//
// The motor (play) pauses and resumes at the current byte. After the last byte
// (tape_end) the output stays high, as MAME ends every block (svi_cas.cpp,
// CAS_EMPTY_SAMPLES of SMPHI): the high level after the last bit's low half is
// the edge that ends that bit, and the BIOS needs it (Mr. Do!'s last block ends
// exactly at the end of the file: cutting the signal there gave "Device I/O
// error"). It no longer plays whatever is left in the buffer past the end.

module cassette #(
  parameter LEAD_BYTES = 400          // 55h bytes per leader (old player: 16 x 25)
) (
  input             clk,
  input             Q,                // the player steps on rising edges of Q
  input             play,             // motor on
  input             rewind,
  input      [24:0] tape_end,         // address of the last byte of the image
  input             turbo,            // play 4x faster (the CPU runs 4x with it)

  // tape buffer (SDRAM, sdram.sv handshake): a rising edge of sdram_rd starts
  // a read of sdram_addr; sdram_ready goes high again one clock before the data
  // is latched. A buffer that answers at once can tie sdram_ready to 1.
  output reg [24:0] sdram_addr,
  input       [7:0] sdram_data,
  output reg        sdram_rd = 1'b0,
  input             sdram_ready,
  output reg [24:0] pos,              // position in the image (next byte to play)

  output            data,
  output            tick,             // one 4899 Hz period of tape time sent (tape_overlay)
  output      [2:0] status            // 0 = idle / stopped
);

localparam
  IDLE    = 3'd0,
  FETCH   = 3'd1,   // address set, wait for the byte
  CHECK   = 3'd2,   // byte is 55h: compare the next 16 bytes
  SEND    = 3'd3,   // start square_gen
  WAITSQ  = 3'd4,   // wait for the byte to finish
  ENDED   = 3'd5;

reg  [2:0] state = IDLE;
reg  [7:0] cur;           // byte at pos
reg  [4:0] chk;           // CHECK: offset being compared (1..16)
reg  [9:0] lead_cnt;      // leader bytes still to send
reg        in_lead;       // sending a synthesized leader
reg        send_sync;     // the 7Fh after the leader
reg  [7:0] sq_byte;
reg        sq_ext;        // 1 = with start bit
reg        sq_start;
wire       done;
reg  [2:0] rdw = 3'd0;    // read in flight: 1 = rd up, 2 = rd down, 3 = wait ready, 4 = data next

assign status = state;
wire   sq_data;
assign data = (state == ENDED) ? 1'b1 : sq_data;

reg q_r, ffplay, ffrewind;
always @(posedge clk) begin
  q_r <= Q;
  if (Q && !q_r) begin
    ffplay   <= play;
    ffrewind <= rewind;
    sq_start <= 1'b0;

    case (rdw)
      3'd1: begin sdram_rd <= 1'b1; rdw <= 3'd2; end
      3'd2: begin sdram_rd <= 1'b0; rdw <= 3'd3; end
      3'd3: if (sdram_ready) rdw <= 3'd4;
      3'd4: rdw <= 3'd0;
      default: ;
    endcase

    case (state)
      FETCH: if (rdw == 3'd0) begin
        // data for sdram_addr == pos is valid now
        cur <= sdram_data;
        if (sdram_data == 8'h55 && pos + 25'd16 <= tape_end) begin
          chk        <= 5'd1;
          read_at(pos + 25'd1);
          state      <= CHECK;
        end else begin
          sq_byte <= sdram_data; sq_ext <= 1'b1;
          state   <= SEND;
        end
      end

      CHECK: if (rdw == 3'd0) begin
        // sdram_data = byte at pos + chk
        if ((chk != 5'd16 && sdram_data == 8'h55) || (chk == 5'd16 && sdram_data == 8'h7F)) begin
          if (chk == 5'd16) begin
            // a block starts at pos
            in_lead  <= 1'b1;
            lead_cnt <= LEAD_BYTES[9:0] - 10'd1;
            sq_byte  <= 8'h55; sq_ext <= 1'b0;
            state    <= SEND;
          end else begin
            chk        <= chk + 5'd1;
            read_at(pos + chk + 25'd1);
          end
        end else begin
          // not a block start: play the 55h as an ordinary byte
          sq_byte <= cur; sq_ext <= 1'b1;
          state   <= SEND;
        end
      end

      SEND: begin
        sq_start <= 1'b1;
        state    <= WAITSQ;
      end

      WAITSQ: if (done && !sq_start) begin
        if (in_lead) begin
          if (lead_cnt != 0) begin
            lead_cnt <= lead_cnt - 10'd1;
            state    <= SEND;
          end else begin
            in_lead   <= 1'b0;
            send_sync <= 1'b1;
            sq_byte   <= 8'h7F; sq_ext <= 1'b0;
            state     <= SEND;
          end
        end else if (send_sync) begin
          send_sync <= 1'b0;
          pos       <= pos + 25'd17;
          next_byte(pos + 25'd17);
        end else begin
          pos <= pos + 25'd1;
          next_byte(pos + 25'd1);
        end
      end

      default: ;
    endcase

    // motor: pause / resume at the current byte (a byte in flight restarts)
    if (ffplay ^ play) begin
      if (play) begin
        in_lead   <= 1'b0;
        send_sync <= 1'b0;
        next_byte(pos);
      end else if (state != ENDED) begin
        state <= IDLE;
      end
    end

    if (rewind) begin
      pos        <= 25'd0;
      in_lead    <= 1'b0;
      send_sync  <= 1'b0;
      state      <= IDLE;
    end else if (ffrewind && play) begin
      // rewind released with the motor running: start from the top
      next_byte(25'd0);
    end
  end
end

task read_at(input [24:0] a);
  begin
    sdram_addr <= a;
    sdram_rd   <= 1'b0;     // low first, so the next request is always a rising edge
    rdw        <= 3'd1;
  end
endtask

task next_byte(input [24:0] a);
  begin
    if (a > tape_end) state <= ENDED;
    else begin
      read_at(a);
      state <= FETCH;
    end
  end
endtask

square_gen sq(
  .clk(clk),
  .Q(Q),
  .start(sq_start),
  .din(sq_byte),
  .extend(sq_ext),
  .turbo(turbo),
  .done(done),
  .dout(sq_data),
  .tick(tick)
);

endmodule
