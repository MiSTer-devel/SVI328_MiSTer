/*
    You should have received a copy of the MIT License
    along with svi_mapper.  If not, see https://mit-license.org/

    Author: Naeloob - RWDevTeam
    Version: 0.02
    Date: 03-04-2021, bank decode rewritten 2026-11-14 (see below) */

// SVI-318/328 memory banks, selected by PSG port B (0 = enabled):
//
//   bit 0 CART   bank 11 (0000-7FFF) cartridge ROM, CCS1/CCS2
//   bit 1 BK21   bank 21 (0000-7FFF) RAM (on the SVI-328 board)
//   bit 2 BK22   bank 22 (8000-FFFF) SV-807 RAM
//   bit 3 BK31   bank 31 (0000-7FFF) SV-807 RAM
//   bit 4 BK32   bank 32 (8000-FFFF) SV-807 RAM
//   bit 5 CAPS   Caps Lock LED
//   bit 6 ROMEN0 cartridge ROM at 8000-BFFF (CCS3), only while CART = 0
//   bit 7 ROMEN1 cartridge ROM at C000-FFFF (CCS4), only while CART = 0
//
// Default (bits = 1): BASIC ROM (bank 01) at 0000-7FFF, RAM (bank 02) above.
// ROMEN0/1 are independent 16 KB enables gated by CART, as on the STM-A
// schematic (IC31 74LS139 + IC28: /CCS3 = Y2 | /ROMEN0, /CCS4 = Y3 | /ROMEN1,
// cartridge half enabled only with /CART low) and in MAME (svi318.cpp).
// When several bits are low the order is MAME's: cartridge first, then
// bank 21, then bank 31 (lower half); cartridge, bank 22, bank 32 (upper).
// See refs/docs/RESEARCH_2026-11-14.md (a).
//
// Port B is an input after reset (AY R7 = 0) and its pull-ups make all bits
// read 1 until the BIOS sets R7 bit 7: cv_console gives FF here until then.
//
// Block RAM layout {bank, A15:0}:
//   00000-07FFF BASIC ROM      08000-0FFFF bank 02 RAM
//   10000-17FFF bank 11 cart   18000-1FFFF bank 12 cart (CCS3/CCS4)
//   20000-27FFF bank 21        28000-2FFFF bank 22
//   30000-37FFF bank 31        38000-3FFFF bank 32
//
// A cartridge area with no ROM behind it reads FF (open bus, as MAME's
// unmap_value_high): no cartridge loaded, or beyond the loaded image.
//
// Machine (OSD Model, Memory; research (b), (c)):
//   SVI-328           bank 02 (32 KB) + bank 21
//   SVI-318           16 KB at C000-FFFF only (8000-BFFF reads FF), no bank 21
//   SV-807 expansion  banks 21, 22, 31, 32 all present (and on a 318 the full
//                     bank 02), a superset of any DIP setting of the card
// A bank bit selecting a bank that isn't there changes nothing: the BASIC
// ROM / bank 02 stay (ROMDIS / RAMDIS are driven only by a card that decodes
// the bank).

module svi_mapper(
    input      [15:0] addr_i,
    input       [7:0] RegMap_i,     // PSG port B pins
    input             cart_loaded,
    input      [15:0] cart_last,    // offset of the cartridge image's last byte
    input             model_318,
    input             expanded,     // SV-807
    output     [17:0] addr_o,
    output            ram,          // writable RAM
    output            open_bus      // nothing answers: reads FF
);

wire cart_n  = RegMap_i[0];
wire bk21_n  = RegMap_i[1];
wire bk22_n  = RegMap_i[2];
wire bk31_n  = RegMap_i[3];
wire bk32_n  = RegMap_i[4];
wire romen0_n = RegMap_i[6];
wire romen1_n = RegMap_i[7];

wire upper = addr_i[15];
wire cart_hi = !cart_n && (addr_i[14] ? !romen1_n : !romen0_n);
wire has21 = !model_318 || expanded;
wire has3x = expanded;              // 22, 31, 32
wire has02_lo = !model_318 || expanded;   // 8000-BFFF of bank 02

reg [1:0] bank;
always @(*) begin
    if (!upper) begin
        if      (!cart_n) bank = 2'd1;
        else if (!bk21_n && has21) bank = 2'd2;
        else if (!bk31_n && has3x) bank = 2'd3;
        else              bank = 2'd0;
    end else begin
        if      (cart_hi) bank = 2'd1;
        else if (!bk22_n && has3x) bank = 2'd2;
        else if (!bk32_n && has3x) bank = 2'd3;
        else              bank = 2'd0;
    end
end

wire is_cart = bank == 2'd1;
wire is_rom  = bank == 2'd0 && !upper;

assign addr_o   = {bank, addr_i};
assign ram      = !is_cart && !is_rom;
assign open_bus = (is_cart && (!cart_loaded || addr_i > cart_last)) ||
                  (bank == 2'd0 && upper && !addr_i[14] && !has02_lo);

endmodule
