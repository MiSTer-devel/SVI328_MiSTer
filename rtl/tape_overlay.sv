// tape_overlay.sv - tape status bar and next-step hint over the picture
// (OSD "Tape overlay"), after the MiSTer tape standard (rules 19-28).
// Structure ported from the Basic Master Jr core's rtl/tape_overlay.sv, itself
// from the Sharp X1 core's x1_tape_overlay.sv (GPL-2.0).
//
// While the deck plays, the bottom-left corner shows
//
//     TAPE > 0:09/ 2:24 x4
//     [=========---------]
//
// elapsed/total time at the real tape speed, the turbo factor while turbo is
// on, and a 64-step progress bar. While the deck is stopped, the same corner
// shows what to type next (svi_tape_hint), read from the tape's first header.
//
// Times. The player (cassette.v / square_gen.v) sends a 1 bit as 2 and a 0
// bit as 4 periods of a 4899 Hz tick (21.477 MHz x 0EF3h / 2^24); a byte with
// its start bit is 36 - 2 x (ones) ticks. Each block's 16 x 55h + 7Fh is
// played as a 400-byte 55h leader plus 7Fh, without start bits (400 x 24 + 18
// ticks instead of 16 x 28 + 22). svi_tape_status adds this up as the image
// downloads for the total, and counts the player's ticks for the elapsed time.
// Both are exact for what the player sends.

`define TH_RETURN 8'h01
`define TH_PLAY   8'h03

// svi_tape_hint - what to type next, from the first file's header block.
//
// An SVI header block is 10 x the file type then a 6-character name (BIOS
// 0x2xxx; MAME svi_cas.cpp). The type gives the command (software/DETECTION.md:
// 199 of the 200 TOSEC tapes that name their load command agree):
//
//   D3h tokenized BASIC     CLOAD, then RUN
//   D0h machine code        BLOAD"CAS:",R   (starts itself)
//   EAh ASCII BASIC         RUN"CAS:"       (starts itself)
//
// With the deck stopped:
//   tape at its start                         the load command
//   BASIC: after its data block (CLOAD done)  RUN, until Return is pressed
//   anywhere else                             nothing
module svi_tape_hint (
  input  logic         clk,
  input  logic         dl_start,    // a new image starts downloading
  input  logic         dl_wr,       // image byte written
  input  logic  [24:0] dl_addr,
  input  logic   [7:0] dl_data,
  input  logic  [24:0] position,    // cassette byte pointer
  input  logic         playing,
  input  logic  [10:0] ps2_key,
  output logic         show,
  output logic   [4:0] len,
  output logic [175:0] text         // 22 characters, the first in [175:168]
);
  logic [4:0]  run55;               // 55h bytes in a row (saturates at 16)
  logic [1:0]  nblk;                // block starts seen (saturates at 3)
  logic [24:0] blk1, blk2;          // where blocks 1 and 2 start (first 55h)
  logic [3:0]  hcnt;                // header bytes captured after block 0's 7Fh
  logic        hdr_on, hdr_ok;
  logic [7:0]  ftype;
  logic        run_done;            // RUN hint dismissed by Return
  logic        old_tog;
  localparam logic [1:0] K_NONE = 2'd0, K_LOAD = 2'd1, K_RUN = 2'd2;
  logic [1:0]  kind;

  initial begin
    run55 = 0; nblk = 0; blk1 = 0; blk2 = 0; hcnt = 0; hdr_on = 0; hdr_ok = 0;
    ftype = 0; run_done = 0; old_tog = 0;
  end

  always_ff @(posedge clk) begin
    if (dl_start) begin
      run55 <= 0; nblk <= 0; blk1 <= 0; blk2 <= 0; hcnt <= 0; hdr_on <= 0; hdr_ok <= 0;
      ftype <= 0; run_done <= 0;
    end else if (dl_wr) begin
      if (dl_data == 8'h55) begin
        if (run55 != 5'd16) run55 <= run55 + 5'd1;
      end else run55 <= 0;
      if (hdr_on) begin
        // 10 x type: the first sets it, the other nine must match
        if (hcnt == 0) begin ftype <= dl_data; hdr_ok <= 1; end
        else if (dl_data != ftype) hdr_ok <= 0;
        if (hcnt == 4'd9) hdr_on <= 0;
        hcnt <= hcnt + 4'd1;
      end
      if (dl_data == 8'h7F && run55 == 5'd16) begin
        if (nblk != 2'd3) nblk <= nblk + 2'd1;
        if (nblk == 2'd0) begin hdr_on <= 1; hcnt <= 0; end
        if (nblk == 2'd1) blk1 <= dl_addr - 25'd16;
        if (nblk == 2'd2) blk2 <= dl_addr - 25'd16;
      end
    end

    // Return dismisses the RUN hint; rewinding brings the load hint back.
    old_tog <= ps2_key[10];
    if (old_tog != ps2_key[10] && ps2_key[9] && ps2_key[7:0] == 8'h5A && show && kind == K_RUN)
      run_done <= 1;
    if (position == 0) run_done <= 0;
  end

  wire known = hdr_ok && (ftype == 8'hD3 || ftype == 8'hD0 || ftype == 8'hEA);
  // CLOAD stops the motor inside the data block or the bytes after it; the
  // player's position is then past that block's leader and sync (17 bytes).
  wire after_cload = ftype == 8'hD3 && nblk >= 2'd2 && position >= blk1 + 25'd17 &&
                     (nblk == 2'd2 || position <= blk2);
  always_comb begin
    kind = K_NONE;
    if (known && !playing) begin
      if (position == 0) kind = K_LOAD;
      else if (after_cload && !run_done) kind = K_RUN;
    end
  end

  assign show = kind != K_NONE;
  always_comb begin
    text = {22{8'h20}};
    len  = 5'd0;
    if (kind == K_RUN) begin
      text[175 -: 80] = {"TYPE RUN ", `TH_RETURN};
      len = 5'd10;
    end else if (ftype == 8'hD3) begin
      text[175 -: 96] = {"TYPE CLOAD ", `TH_RETURN};
      len = 5'd12;
    end else if (ftype == 8'hD0) begin
      text[175 -: 160] = {"TYPE BLOAD\"CAS:\",R ", `TH_RETURN};
      len = 5'd20;
    end else begin
      text[175 -: 128] = {"TYPE RUN\"CAS:\" ", `TH_RETURN};
      len = 5'd16;
    end
  end
endmodule

module svi_tape_status (
  input  logic         clk,
  input  logic         dl_start,    // a new image starts downloading
  input  logic         dl_wr,       // image byte written
  input  logic   [7:0] dl_data,
  input  logic         dl_busy,     // download in progress
  input  logic         loaded,      // a tape is mounted
  input  logic         playing,     // deck running
  input  logic         fast,        // turbo active
  input  logic         tick,        // one tape tick (1/4899 s of tape) played
  input  logic  [24:0] position,    // byte pointer (0 after mount/rewind)
  input  logic  [24:0] length,      // bytes on the tape
  input  logic         hint_show,
  input  logic   [4:0] hint_len,
  input  logic [175:0] hint_text,
  // to the video clock
  output logic [223:0] status,      // held while req != ack
  output logic         req,
  input  logic         ack          // asynchronous; synchronised here
);
  localparam logic [12:0] RATE = 13'd4899;

  logic [15:0] elapsed, total;      // BCD m1 m0 s1 s0
  logic [12:0] frac;
  logic [31:0] ticks, rem;          // total ticks of the image; left to convert
  logic [4:0]  run55;
  logic [24:0] last_pos, thresh;
  wire  [24:0] step_bytes = length[24:6] == 0 ? 25'd1 : {6'd0, length[24:6]};
  logic [6:0]  fill;
  logic        computing, was_busy;
  logic [1:0]  ack_sync;

  function automatic logic [15:0] bcd_tick(input logic [15:0] t);
    logic [15:0] n;
    n = t;
    if (t == 16'h9959) return t;                 // saturate at 99:59
    if (t[3:0] != 4'd9) n[3:0] = t[3:0] + 4'd1;
    else begin
      n[3:0] = 0;
      if (t[7:4] != 4'd5) n[7:4] = t[7:4] + 4'd1;
      else begin
        n[7:4] = 0;
        if (t[11:8] != 4'd9) n[11:8] = t[11:8] + 4'd1;
        else begin n[11:8] = 0; n[15:12] = t[15:12] + 4'd1; end
      end
    end
    return n;
  endfunction

  function automatic logic [5:0] byte_ticks(input logic [7:0] d);
    logic [3:0] ones;
    ones = 0;
    for (int i = 0; i < 8; i++) ones = ones + {3'd0, d[i]};
    return 6'd36 - {1'b0, ones, 1'b0};
  endfunction

  wire [223:0] pack = {hint_show, hint_len, hint_text, loaded, playing, fast, fill, elapsed, total};

  initial begin
    elapsed = 0; total = 0; frac = 0; ticks = 0; rem = 0; run55 = 0; last_pos = 0;
    thresh = 0; fill = 0; computing = 0; was_busy = 0; req = 0; status = 0; ack_sync = 0;
  end

  always_ff @(posedge clk) begin
    ack_sync <= {ack_sync[0], ack};

    // Total: ticks of the image as the player will send it.
    was_busy <= dl_busy;
    if (dl_start) begin
      ticks <= 0; run55 <= 0; total <= 0; computing <= 0;
    end else if (dl_wr) begin
      if (dl_data == 8'h55) begin
        if (run55 != 5'd16) run55 <= run55 + 5'd1;
      end else run55 <= 0;
      // a block start: 16 x 55h + 7Fh become the leader + 7Fh, no start bits
      ticks <= ticks + {26'd0, byte_ticks(dl_data)} +
               (dl_data == 8'h7F && run55 == 5'd16 ? 32'd9148 : 32'd0);
    end else if (was_busy && !dl_busy) begin
      rem <= ticks; total <= 0; computing <= 1;
    end else if (computing) begin
      if (rem >= {19'd0, RATE}) begin rem <= rem - {19'd0, RATE}; total <= bcd_tick(total); end
      else computing <= 0;
    end

    // Elapsed: the player's ticks; back to 0 when the tape is rewound.
    last_pos <= position;
    if (dl_start || position < last_pos) begin
      elapsed <= 0; frac <= 0;
    end else if (tick) begin
      if (frac == RATE - 13'd1) begin frac <= 0; elapsed <= bcd_tick(elapsed); end
      else frac <= frac + 13'd1;
    end

    // Fill: 64 steps of length / 64 bytes.
    if (dl_start || position < last_pos || thresh == 0) begin
      fill <= 0; thresh <= step_bytes;
    end else if (position >= thresh && fill != 7'd64) begin
      fill <= fill + 7'd1; thresh <= thresh + step_bytes;
    end

    // Send a changed status once the previous one was taken.
    if (req == ack_sync[1] && pack != status) begin
      status <= pack;
      req <= !req;
    end
  end
endmodule

module svi_tape_overlay #(
  parameter logic [3:0] FACTOR = 4'd4      // shown as "x4" while turbo is on
)(
  input  logic         clk,         // video clock
  input  logic         ce_pix,
  input  logic         hblank, vblank,
  input  logic         enable,      // OSD Tape overlay: On
  input  logic [223:0] status,      // from svi_tape_status, stable while req != ack
  input  logic         req,
  output logic         ack,
  input  logic  [23:0] rgb_in,
  output logic  [23:0] rgb_out
);
  localparam int CHARS = 22;
  logic [1:0]   req_sync;
  logic [223:0] shown;
  logic [10:0]  x, width;
  logic [9:0]   y, height;
  logic         line_active, old_hblank, old_vblank;

  initial begin
    req_sync = 0; ack = 0; shown = 0; x = 0; y = 0; width = 0; height = 0;
    line_active = 0; old_hblank = 0; old_vblank = 0;
  end

  // Measure the active picture each frame (256x192, or larger with the border).
  always_ff @(posedge clk) begin
    req_sync <= {req_sync[0], req};
    if (req_sync[1] != ack) begin shown <= status; ack <= req_sync[1]; end
    if (ce_pix) begin
      old_hblank <= hblank; old_vblank <= vblank;
      if (!hblank && !vblank) begin x <= x + 11'd1; line_active <= 1; end
      if (hblank && !old_hblank) begin
        if (line_active) begin width <= x; y <= y + 10'd1; end
        x <= 0; line_active <= 0;
      end
      if (vblank && !old_vblank) begin height <= y; y <= 0; end
    end
  end

  wire         hint_show = shown[223];
  wire [4:0]   hint_len  = shown[222:218];
  wire [175:0] hint_text = shown[217:42];
  wire         tape_bar  = enable && shown[41] && shown[40];   // loaded, playing
  wire         hint      = enable && hint_show && !tape_bar;
  wire         visible   = tape_bar || hint;
  wire         fast      = shown[39];
  wire [6:0]   fill      = shown[38:32];
  wire [15:0]  elapsed   = shown[31:16];
  wire [15:0]  total     = shown[15:0];
  // Double the overlay on wide or tall pictures (the SVI's are 256-284 x 192-240).
  wire         sx = width >= 11'd512, sy = height >= 10'd300;
  wire [4:0]   chars = tape_bar ? 5'(CHARS) : hint_len;
  wire [10:0]  box_w = {3'd0, chars, 3'd0} + 11'd4;
  wire [9:0]   box_h = tape_bar ? 10'd18 : 10'd12;
  wire [10:0]  x0 = 11'd4;
  wire [9:0]   y0 = height - (sy ? {box_h[8:0], 1'b0} : box_h) - 10'd4;
  wire [10:0]  dx = x - x0;
  wire [9:0]   dy = y - y0;
  wire [10:0]  lx = sx ? {1'b0, dx[10:1]} : dx;
  wire [9:0]   ly = sy ? {1'b0, dy[9:1]} : dy;
  wire         in_box = x >= x0 && y >= y0 && lx < box_w && ly < box_h;

  wire [10:0]  tx = lx - 11'd2;
  wire [9:0]   ty = ly - 10'd2;

  `include "tape_font.vh"

  function automatic logic [7:0] digit(input logic [3:0] d, input logic blank_zero);
    return blank_zero && d == 0 ? 8'h20 : 8'h30 + {4'd0, d};
  endfunction
  // The character at column col (an always_comb, not a function reading
  // module signals: Quartus 17 reports those signals as never read).
  wire  [4:0] col = tx[7:3];
  logic [7:0] ch;
  always_comb begin
    if (!tape_bar) ch = hint_text[175 - 8 * col -: 8];
    else case (col)
      5'd0: ch = "T";  5'd1: ch = "A";  5'd2: ch = "P";  5'd3: ch = "E";
      5'd5: ch = `TH_PLAY;
      5'd7: ch = digit(elapsed[15:12], 1'b1);  5'd8: ch = digit(elapsed[11:8], 1'b0);
      5'd9: ch = ":";
      5'd10: ch = digit(elapsed[7:4], 1'b0);  5'd11: ch = digit(elapsed[3:0], 1'b0);
      5'd12: ch = "/";
      5'd13: ch = digit(total[15:12], 1'b1);  5'd14: ch = digit(total[11:8], 1'b0);
      5'd15: ch = ":";
      5'd16: ch = digit(total[7:4], 1'b0);  5'd17: ch = digit(total[3:0], 1'b0);
      5'd19: ch = fast ? "x" : " ";
      5'd20: ch = fast ? digit(FACTOR, 1'b0) : " ";
      default: ch = " ";
    endcase
  end
  function automatic logic [7:0] glyph(input logic [7:0] c, input logic [2:0] r);
    logic [63:0] g;
    if (c == `TH_RETURN) begin g = 64'h0002022262FE6020; return g[63 - 8 * r -: 8]; end
    if (c == `TH_PLAY)   begin g = 64'h4060707870604000; return g[63 - 8 * r -: 8]; end
    if (c >= 8'h40 && c < 8'h60) return tape_font({1'b0, c[4:0]}, r);
    if (c >= 8'h20 && c < 8'h40) return tape_font({1'b1, c[4:0]}, r);
    return 8'h00;
  endfunction

  wire [7:0] glyph_row = glyph(ch, ty[2:0]);
  wire text_on = ty < 10'd8 && tx < {3'd0, chars, 3'd0} && glyph_row[3'd7 - tx[2:0]];
  // Progress bar at ly 12..15, 128 px for 64 steps.
  wire bar_area = tape_bar && ly >= 10'd12 && ly < 10'd16 && lx >= 11'd2 && lx < 11'd130;
  wire bar_on = bar_area && (lx - 11'd2) < {3'd0, fill, 1'b0};

  always_comb begin
    rgb_out = rgb_in;
    if (visible && in_box)
      rgb_out = text_on ? 24'hFFFFFF : bar_on ? 24'h44CC44 : bar_area ? 24'h333333 : 24'h000000;
  end
endmodule
