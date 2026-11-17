// Display = Auto: show the screen the software writes its text to.
//
// On the real machine the SV-806 drove its own monitor next to the TV, so
// nothing chose between the two pictures. Here one output is shown, and Auto
// follows the software: a CPU write to the card's display RAM points at the
// 80-column screen, a write to the VDP (ports 80h-83h and mirrors) at the
// VDP. The shown screen changes once the other one has been the last written
// for 2^HOLD clocks with no write to the shown one in between (0.2 s at
// 42.95 MHz), so software that writes to both screens can't make the picture
// flicker between them. Disk BASIC with the card writes only to the card
// after its banner, WIDTH 40 moves it to the VDP and WIDTH 80 back; CP/M
// writes to the card; games write to the VDP.
//
// Starts on the VDP at reset, and stays there without the card.

module sv806_auto #(parameter HOLD = 23) (
    input      clk,
    input      reset,
    input      enable,      // the SV-806 is present
    input      m806_wr,     // CPU write to the card's display RAM (level)
    input      vdp_wr,      // CPU write to the VDP (level)
    output reg show80 = 1'b0
);

reg last80 = 1'b0, m806_wr_r = 1'b0, vdp_wr_r = 1'b0;
reg [HOLD-1:0] hold = '0;

always @(posedge clk) begin
    m806_wr_r <= m806_wr;
    vdp_wr_r  <= vdp_wr;
    if (reset | ~enable) begin
        show80 <= 1'b0;
        last80 <= 1'b0;
        hold   <= '0;
    end else begin
        if (m806_wr & ~m806_wr_r)    last80 <= 1'b1;
        else if (vdp_wr & ~vdp_wr_r) last80 <= 1'b0;

        if (last80 == show80) hold <= '0;
        else if (&hold) begin
            show80 <= last80;
            hold   <= '0;
        end else hold <= hold + 1'd1;
    end
end

endmodule
