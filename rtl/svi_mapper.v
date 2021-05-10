/*  
    You should have received a copy of the MIT License
    along with svi_mapper.  If not, see https://mit-license.org/

    Author: Naeloob - RWDevTeam
    Version: 0.01
    Date: 03-04-2021 */

//Todo Select sv-807 from OSD
	 
module svi_mapper(
    input       [15:0]   addr_i,
    input        [7:0]   RegMap_i,
    output		 [17:0]   addr_o,
	 output  				 ram
);


//https://www.msx.org/wiki/SVI-3x8_Memory_Banks
//#0000-#7FFF		Description							#8000-#FFFF	Description
//BANK 01			BASIC ROM							BANK 02		MAIN RAM
//BANK 11			Game cartridge ROM				(BANK 12)	ROM0 + ROM1 (optional game cartridge ROMs)
//BANK 21			Standard SVI-328 extended RAM	BANK 22		SV-807 RAM expansion
//BANK 31			SV-807 RAM expansion				BANK 32		SV-807 RAM expansion

//RegMap_i Bits : 
//0 CART ROM Bank 11 (#0000-#7FFF) Game cartridge
//1 BK21 RAM Bank 21 (#0000-#7FFF) RAM on SVI-328
//2 BK22 RAM Bank 22 (#8000-#FFFF) Expansion RAM
//3 BK31 RAM Bank 31 (#0000-#7FFF) Expansion RAM
//4 BK32 RAM Bank 32 (#8000-#FFFF) Expansion RAM
//5 (CAPS Caps Lock LED on/off)
//6 ROMEN0 ROM "Bank 12/L" (#8000-#BFFF) Game cartridge
//7 ROMEN1 ROM "Bank 12/H" (#C000-#FFFF) Game cartridge

//0 = Enabled, 1 = Disabled

// There is no single bit to select BANK 12, but instead it is divided to 2x 16KB blocks that are controlled by ROMEN0 and ROMEN1 bits. 
// Although in theory they can be individually selected ON/OFF, this makes no sense as apart from each other there is nothing that can be activated with 16kB ROM to same bank due to size difference. 
// These ROMEN0 and ROMEN1 bits don't have effect unless BANK 11 is selected, so actually the usage of this special area is more limited when compared to other banks.

wire pageSel = addr_i[15];


//Full Ram with sv-807
wire [1:0] page0 = RegMap_i[0] ? (RegMap_i[1] ? (RegMap_i[3] ? 2'd0:2'd3):2'd2): 2'd1;
wire [1:0] page1 = RegMap_i[2] ? (RegMap_i[4] ? ((RegMap_i[6] && RegMap_i[7])  ? 2'd0:2'd1):2'd3): 2'd2;


//General
wire [1:0] bank = (RegMap_i == 7'd0)? 2'd0: (pageSel ? page1:page0);


//Outputs
assign ram = (bank == 2'd1 | (bank == 2'd0 && pageSel == 1'b0)) ? 1'b0 : 1'b1 ;
assign addr_o = {bank, addr_i}; 


endmodule