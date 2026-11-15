// SystemVerilog port of rtl/keyboard_svi.vhd (sviKeyboard), table for table.
// Keep in step with the VHDL.
//  - keys[8] (E0) separates the arrows / Insert / Delete / Home / right
//    Ctrl, GUI, Alt from the keypad and the left keys;
//  - row 7: bit 5 CLS (Home), bit 6 INS (MAME svi318.cpp, CSP svi3x8);
//  - the SVI key right of L gives ':' unshifted and ';' shifted: Shift is
//    inverted while it is down, so the PC's ; and Shift+; type ; and :.
module svi_keyboard (
  input              clk,
  input              reset,
  input      [10:0]  keys,     // hps_io ps2_key: [7:0] code, [8] E0, [9] pressed, [10] toggle
  input      [3:0]   svi_row,
  output     [7:0]   svi_col
);
  logic [7:0] m [16];
  logic       chg, lshift, rshift, semi;

  wire  svi_shift = (lshift | rshift) ^ semi;
  assign svi_col = ~(svi_row == 4'd6 ? {m[6][7:1], m[6][0] | svi_shift} : m[svi_row]);

  wire       press = keys[9];
  wire       ext   = keys[8];
  wire [7:0] code  = keys[7:0];

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < 16; i++) m[i] <= 8'd0;
      chg <= 1'b0; lshift <= 1'b0; rshift <= 1'b0; semi <= 1'b0;
    end else begin
      chg <= keys[10];
      if (chg != keys[10]) begin
        if (ext) begin
          case (code)
            8'h75: m[5][7]  <= press;  // Up
            8'h72: m[7][7]  <= press;  // Down
            8'h6B: m[6][7]  <= press;  // Left
            8'h74: m[8][7]  <= press;  // Right
            8'h70: m[7][6]  <= press;  // Insert: INS
            8'h6C: m[7][5]  <= press;  // Home: CLS
            8'h71: m[8][2]  <= press;  // Delete
            8'h14: m[6][1]  <= press;  // right Ctrl
            8'h1F: m[6][2]  <= press;  // left GUI: left GRAPH
            8'h27: m[6][3]  <= press;  // right GUI: right GRAPH
            8'h11: m[6][3]  <= press;  // right Alt: right GRAPH
            8'h5A: m[6][6]  <= press;  // keypad Enter
            8'h4A: m[10][5] <= press;  // keypad /
            default: ;
          endcase
        end else begin
          case (code)
            8'h3D: m[0][7] <= press;  // 7
            8'h36: m[0][6] <= press;  // 6
            8'h2E: m[0][5] <= press;  // 5
            8'h25: m[0][4] <= press;  // 4
            8'h26: m[0][3] <= press;  // 3
            8'h1E: m[0][2] <= press;  // 2
            8'h16: m[0][1] <= press;  // 1
            8'h45: m[0][0] <= press;  // 0

            8'h4A: m[1][7] <= press;  // /
            8'h49: m[1][6] <= press;  // .
            8'h55: m[1][5] <= press;  // =
            8'h41: m[1][4] <= press;  // ,
            8'h52: m[1][3] <= press;  // '
            8'h4C: begin m[1][2] <= press; semi <= press; end  // ; :
            8'h46: m[1][1] <= press;  // 9
            8'h3E: m[1][0] <= press;  // 8

            8'h34: m[2][7] <= press;  // G
            8'h2B: m[2][6] <= press;  // F
            8'h24: m[2][5] <= press;  // E
            8'h23: m[2][4] <= press;  // D
            8'h21: m[2][3] <= press;  // C
            8'h32: m[2][2] <= press;  // B
            8'h1C: m[2][1] <= press;  // A
            8'h4E: m[2][0] <= press;  // -

            8'h44: m[3][7] <= press;  // O
            8'h31: m[3][6] <= press;  // N
            8'h3A: m[3][5] <= press;  // M
            8'h4B: m[3][4] <= press;  // L
            8'h42: m[3][3] <= press;  // K
            8'h3B: m[3][2] <= press;  // J
            8'h43: m[3][1] <= press;  // I
            8'h33: m[3][0] <= press;  // H

            8'h1D: m[4][7] <= press;  // W
            8'h2A: m[4][6] <= press;  // V
            8'h3C: m[4][5] <= press;  // U
            8'h2C: m[4][4] <= press;  // T
            8'h1B: m[4][3] <= press;  // S
            8'h2D: m[4][2] <= press;  // R
            8'h15: m[4][1] <= press;  // Q
            8'h4D: m[4][0] <= press;  // P

            8'h66: m[5][6] <= press;  // Backspace
            8'h5B: m[5][5] <= press;  // ]
            8'h5D: m[5][4] <= press;  // backslash
            8'h54: m[5][3] <= press;  // [
            8'h1A: m[5][2] <= press;  // Z
            8'h35: m[5][1] <= press;  // Y
            8'h22: m[5][0] <= press;  // X

            8'h5A: m[6][6] <= press;  // Enter
            8'h0A: m[6][5] <= press;  // F8: STOP
            8'h0B: m[6][5] <= press;  // F6: STOP
            8'h76: m[6][4] <= press;  // Esc
            8'h11: m[6][2] <= press;  // left Alt: left GRAPH
            8'h14: m[6][1] <= press;  // left Ctrl
            8'h12: lshift <= press;
            8'h59: rshift <= press;

            8'h03: m[7][4] <= press;  // F5
            8'h0C: m[7][3] <= press;  // F4
            8'h04: m[7][2] <= press;  // F3
            8'h06: m[7][1] <= press;  // F2
            8'h05: m[7][0] <= press;  // F1

            8'h01: m[8][5] <= press;  // F9: PRINT
            8'h83: m[8][4] <= press;  // F7: SELECT
            8'h58: m[8][3] <= press;  // Caps Lock
            8'h0D: m[8][1] <= press;  // Tab
            8'h29: m[8][0] <= press;  // Space

            // keypad: row 9 = 0-7, row 10 = 8 9 + - * / . ,
            8'h70: m[9][0]  <= press;
            8'h69: m[9][1]  <= press;
            8'h72: m[9][2]  <= press;
            8'h7A: m[9][3]  <= press;
            8'h6B: m[9][4]  <= press;
            8'h73: m[9][5]  <= press;
            8'h74: m[9][6]  <= press;
            8'h6C: m[9][7]  <= press;
            8'h75: m[10][0] <= press;
            8'h7D: m[10][1] <= press;
            8'h79: m[10][2] <= press;  // +
            8'h7B: m[10][3] <= press;  // -
            8'h7C: m[10][4] <= press;  // *
            8'h71: m[10][6] <= press;  // .
            default: ;
          endcase
        end
      end
    end
  end
endmodule
