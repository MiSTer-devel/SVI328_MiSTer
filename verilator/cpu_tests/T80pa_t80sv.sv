// Bench top: t80sv_T80pa (rtl/t80sv, the hardware's CPU) under the name T80pa, the ports cpu_t80.h drives.
module T80pa (
  input RESET_n, CLK, CEN_p, CEN_n, WAIT_n, INT_n, NMI_n, BUSRQ_n, OUT0,
  output M1_n, MREQ_n, IORQ_n, RD_n, WR_n, RFSH_n, HALT_n, BUSAK_n,
  output [15:0] A, input [7:0] DI, output [7:0] DO,
  output [211:0] REG, input DIRSet, input [211:0] DIR);
  t80sv_T80pa #(.Mode(0)) d (.RESET_n, .CLK, .CEN_p, .CEN_n, .WAIT_n, .INT_n, .NMI_n, .BUSRQ_n,
    .M1_n, .MREQ_n, .IORQ_n, .RD_n, .WR_n, .RFSH_n, .HALT_n, .BUSAK_n, .OUT0, .A, .DI, .DO,
    .R800_mode(1'b0), .REG, .DIRSet, .DIR);
endmodule
