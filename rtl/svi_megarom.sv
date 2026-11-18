// Cartridges over 64 KB ("megaROM"), as in teiram's Calypso port of this core
// (calypso-ports svi328/SVI328.sv, "Megarom logic", v0.3): the cartridge bank
// (bank 11/12, every address the mapper sends to the cartridge) shows one 16 KB
// page of the image, mirrored, and the page moves on to the next one 8 times a
// second, by a timer and not by anything the program does. Calypso cycles
// through 64 pages (1 MB) whatever the size; here the cycle wraps at the last
// page of the image (the same for a 1 MB image, and no pages of junk after a
// smaller one). The image is up to 1 MB; more is ignored.
//
// The image lives in SDRAM (loaded with the cartridge). The page the CPU sees
// is in block RAM, so CPU reads answer in one clock as the rest of the CPU
// memory does: two 16 KB buffers, one shown and one being filled with the next
// page from SDRAM (~5 ms of the 125). Page 0 goes straight into the shown
// buffer during the download, so the machine starts on it.
//
// The timer and the page run from the end of the download, free (a reset does
// not restart them, as on Calypso).

module svi_megarom #(
    parameter [24:0] BASE = 25'h1000000     // SDRAM address of the image
) (
    input             clk,
    input             ce_5m37,                // 42.954545 / 8 MHz

    // cartridge download (hps_io ioctl, index 1)
    input             dl,                     // downloading a cartridge
    input             dl_wr,
    input      [24:0] dl_addr,
    input       [7:0] dl_data,
    input             eject,

    output reg        active = 0,             // a cartridge over 64 KB is in

    // SDRAM read port (svi_sdram_arb): req held until ack, data with ack
    output reg        rd_req = 0,
    output     [24:0] rd_addr,
    input             rd_ack,
    input       [7:0] rd_data,

    // CPU: the cartridge offset
    input      [13:0] cpu_a,
    output reg  [7:0] cpu_q
);

localparam [19:0] TICKS = 20'd671165;         // 5.369318 MHz / 8 Hz

reg  [7:0] mbuf[32768];
reg        shown = 0;                         // buffer the CPU sees
reg  [5:0] page = 0, last_page = 0;
reg  [5:0] pf_page = 0;
reg [13:0] pf_ptr = 0;
reg        pf_busy = 0, pf_ready = 0;
reg [19:0] tcnt = 0;
reg [24:0] dl_last = 0;
reg        dl_r = 0;

wire [5:0] next_page = (page == last_page) ? 6'd0 : page + 1'd1;
assign rd_addr = BASE + {pf_page, pf_ptr};

always @(posedge clk) cpu_q <= mbuf[{shown, cpu_a}];

always @(posedge clk) begin
    dl_r <= dl;

    if (dl_wr) dl_last <= dl_addr;
    if (dl & ~dl_r) begin
        active  <= 0;
        pf_busy <= 0;
        rd_req  <= 0;
    end

    // page 0 into buffer 0 while it downloads
    if (dl && dl_wr && ~|dl_addr[24:14]) mbuf[{1'b0, dl_addr[13:0]}] <= dl_data;
    else if (pf_busy && rd_ack) mbuf[{~shown, pf_ptr}] <= rd_data;

    // end of the download: over 64 KB makes it a megaROM
    if (~dl & dl_r) begin
        active    <= |dl_last[24:16];
        shown     <= 0;
        page      <= 0;
        last_page <= |dl_last[24:20] ? 6'd63 : dl_last[19:14];
        tcnt      <= 0;
        pf_page   <= 6'd1;
        pf_ptr    <= 0;
        pf_busy   <= |dl_last[24:16];
        pf_ready  <= 0;
        rd_req    <= |dl_last[24:16];
    end

    if (eject) begin
        active  <= 0;
        pf_busy <= 0;
        rd_req  <= 0;
    end

    // prefetch the next page into the hidden buffer
    if (pf_busy && rd_ack) begin
        pf_ptr <= pf_ptr + 1'd1;
        if (&pf_ptr) begin
            pf_busy  <= 0;
            pf_ready <= 1;
            rd_req   <= 0;
        end
    end

    // 8 Hz: show the next page (if it has arrived) and fetch the one after
    if (active && ce_5m37) begin
        if (tcnt == TICKS - 1'd1) begin
            tcnt <= 0;
            if (pf_ready) begin
                shown    <= ~shown;
                page     <= next_page;
                pf_page  <= (next_page == last_page) ? 6'd0 : next_page + 1'd1;
                pf_ptr   <= 0;
                pf_busy  <= 1;
                pf_ready <= 0;
                rd_req   <= 1;
            end
        end else tcnt <= tcnt + 1'd1;
    end
end

endmodule
