// Headless Verilator harness for the SVI-328 core (svi_sim.sv).
//
//   ./obj_dir/Vsvi_sim --frames 300 --shots 300 --outdir /tmp/svi
//   ./obj_dir/Vsvi_sim --tape game.cas --type 'CLOAD\n@150' --frames 9000 --every 250 --tape-log
//
// Run with --help for every option. Frames are written as PNG.

#include "Vsvi_sim.h"
#include "Vsvi_sim___024root.h"
#include "Vsvi_sim_svi_sim.h"
#include "verilated.h"

#include <zlib.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <string>
#include <vector>
#include <deque>
#include <map>
#include <set>
#include <algorithm>
#include <sys/stat.h>

#ifdef SIM_FULL
static const uint64_t CLK_HZ = 42954545;   // clk_sys
#else
static const uint64_t CLK_HZ = 10738636;   // the 10.7 MHz rate
#endif

static Vsvi_sim* top;
static uint64_t cycles = 0;

// ---------------------------------------------------------------- options
static std::string rom_path = "../software/mister11/boot.rom";
static std::string cart_path, tape_path, outdir = "out", wav_path, disk_path, charrom_path;
static bool fdc_on = false, m806_on = false, show80 = false;
static int run_frames = 0, every = 0;
static std::set<int> shots;
static bool tape_turbo = false;
static bool tape_log = false, io_log = false, border = false, text_at_end = false, no_overlay = false, ntsc = false, model_318 = false, mem_std = false;
static std::set<int> text_frames;
static int stop_on_text_frame_check = 0;
static std::string stop_text;
static int stop_after_motor_off = -1;   // exit N frames after the motor stops for the last time
static std::map<int, std::string> dump_ram;  // frame -> file

struct KeyEv { int frame; std::string text; };
static std::vector<KeyEv> type_evs;
struct JoyEv { int frame, len; uint32_t bits; int port; };
static std::vector<JoyEv> joy_evs;
static uint64_t profile_every = 0;

// ---------------------------------------------------------------- PNG
static void put32(std::vector<uint8_t>& v, uint32_t x) {
  v.push_back(x >> 24); v.push_back(x >> 16); v.push_back(x >> 8); v.push_back(x);
}
static void chunk(FILE* f, const char* type, const std::vector<uint8_t>& data) {
  std::vector<uint8_t> b; put32(b, data.size());
  b.insert(b.end(), type, type + 4); b.insert(b.end(), data.begin(), data.end());
  uint32_t crc = crc32(0, b.data() + 4, b.size() - 4);
  put32(b, crc); fwrite(b.data(), 1, b.size(), f);
}
static bool write_png(const std::string& path, int w, int h, const std::vector<uint8_t>& rgb) {
  FILE* f = fopen(path.c_str(), "wb"); if (!f) return false;
  static const uint8_t sig[8] = {137, 80, 78, 71, 13, 10, 26, 10}; fwrite(sig, 1, 8, f);
  std::vector<uint8_t> ihdr; put32(ihdr, w); put32(ihdr, h);
  ihdr.push_back(8); ihdr.push_back(2); ihdr.push_back(0); ihdr.push_back(0); ihdr.push_back(0);
  chunk(f, "IHDR", ihdr);
  std::vector<uint8_t> raw; raw.reserve((w * 3 + 1) * h);
  for (int y = 0; y < h; y++) { raw.push_back(0); raw.insert(raw.end(), &rgb[y * w * 3], &rgb[y * w * 3] + w * 3); }
  uLongf zl = compressBound(raw.size()); std::vector<uint8_t> z(zl);
  compress2(z.data(), &zl, raw.data(), raw.size(), 6); z.resize(zl);
  chunk(f, "IDAT", z); chunk(f, "IEND", {}); fclose(f); return true;
}

// ---------------------------------------------------------------- video capture
static const int FB_W = 800, FB_H = 320;
static std::vector<uint8_t> fb(FB_W * FB_H * 3), last_fb;
static int vx = 0, vy = 0, max_x = 0, max_y = 0, last_w = 0, last_h = 0;
static bool prev_hb = true, prev_vs = false, line_had_pixels = false;
static int frame = 0;

// ---------------------------------------------------------------- PS/2 typing
struct PS2 { uint16_t code; bool ext, press; };
static std::deque<PS2> ps2q;
static uint64_t ps2_next = 0;
static int ps2_toggle = 0;

// char -> (scancode, shift) for the US-style SVI layout, via keyboard_svi's table
static bool char_code(char c, uint8_t& code, bool& shift) {
  static const char* letters = "abcdefghijklmnopqrstuvwxyz";
  static const uint8_t lc[26] = {0x1C,0x32,0x21,0x23,0x24,0x2B,0x34,0x33,0x43,0x3B,0x42,0x4B,0x3A,
                                 0x31,0x44,0x4D,0x15,0x2D,0x1B,0x2C,0x3C,0x2A,0x1D,0x22,0x35,0x1A};
  static const uint8_t dc[10] = {0x45,0x16,0x1E,0x26,0x25,0x2E,0x36,0x3D,0x3E,0x46};
  shift = false;
  if (c >= 'A' && c <= 'Z') { code = lc[c - 'A']; return true; }   // BASIC shows caps anyway
  if (c >= 'a' && c <= 'z') { code = lc[strchr(letters, c) - letters]; return true; }
  if (c >= '0' && c <= '9') { code = dc[c - '0']; return true; }
  const char* sh = ")!@#$%^&*(";
  if (const char* p = strchr(sh, c)) { if (c) { code = dc[p - sh]; shift = true; return true; } }
  switch (c) {
    case ' ': code = 0x29; return true;
    case '\n': code = 0x5A; return true;
    case '"': code = 0x52; shift = true; return true;
    case '\'': code = 0x52; return true;
    // typed as on a PC: keyboard_svi inverts Shift on the key right of L
    // (the SVI key gives ':' unshifted, ';' shifted)
    case ';': code = 0x4C; return true;
    case ':': code = 0x4C; shift = true; return true;
    case ',': code = 0x41; return true;
    case '<': code = 0x41; shift = true; return true;
    case '.': code = 0x49; return true;
    case '>': code = 0x49; shift = true; return true;
    case '/': code = 0x4A; return true;
    case '?': code = 0x4A; shift = true; return true;
    case '=': code = 0x55; return true;
    case '+': code = 0x55; shift = true; return true;
    case '-': code = 0x4E; return true;
    case '_': code = 0x4E; shift = true; return true;
  }
  return false;
}

// named keys for --key
static bool key_name(const std::string& n, uint8_t& code, bool& ext) {
  static const std::map<std::string, std::pair<uint8_t, bool>> k = {
    {"enter",{0x5A,0}},{"space",{0x29,0}},{"esc",{0x76,0}},{"bs",{0x66,0}},{"tab",{0x0D,0}},
    {"stop",{0x0A,0}},{"select",{0x83,0}},{"print",{0x01,0}},{"f1",{0x05,0}},{"f2",{0x06,0}},{"f3",{0x04,0}},{"f4",{0x0C,0}},{"f5",{0x03,0}},
    {"up",{0x75,1}},{"down",{0x72,1}},{"left",{0x6B,1}},{"right",{0x74,1}},{"ins",{0x70,1}},
    {"del",{0x71,1}},{"home",{0x6C,1}},{"caps",{0x58,0}},{"ctrl",{0x14,0}},{"shift",{0x12,0}},
    {"lgraph",{0x11,0}},{"rgraph",{0x11,1}},
    {"kp0",{0x70,0}},{"kp1",{0x69,0}},{"kp2",{0x72,0}},{"kp3",{0x7A,0}},{"kp4",{0x6B,0}},
    {"kp5",{0x73,0}},{"kp6",{0x74,0}},{"kp7",{0x6C,0}},{"kp8",{0x75,0}},{"kp9",{0x7D,0}}};
  auto it = k.find(n); if (it == k.end()) return false;
  code = it->second.first; ext = it->second.second; return true;
}

// keys are queued per frame: a key goes down, stays down 3 frames, up, 2 frames gap
struct Sched { int frame; PS2 ev; };
static std::vector<Sched> sched;
static void schedule_text(int f, const std::string& t) {
  for (size_t i = 0; i < t.size(); i++) {
    char c = t[i];
    if (c == '\\' && i + 1 < t.size() && t[i + 1] == 'n') { c = '\n'; i++; }
    uint8_t code; bool shift;
    if (!char_code(c, code, shift)) { fprintf(stderr, "cannot type '%c'\n", c); continue; }
    if (shift) sched.push_back({f, {0x12, false, true}});
    sched.push_back({f, {code, false, true}});
    sched.push_back({f + 3, {code, false, false}});
    if (shift) sched.push_back({f + 3, {0x12, false, false}});
    f += 5;
  }
}

// ---------------------------------------------------------------- loading
static std::vector<uint8_t> read_file(const std::string& p) {
  std::vector<uint8_t> d; FILE* f = fopen(p.c_str(), "rb");
  if (!f) { fprintf(stderr, "cannot open %s\n", p.c_str()); exit(1); }
  fseek(f, 0, SEEK_END); d.resize(ftell(f)); fseek(f, 0, SEEK_SET);
  if (fread(d.data(), 1, d.size(), f) != d.size()) { fprintf(stderr, "short read %s\n", p.c_str()); exit(1); }
  fclose(f); return d;
}

static void tick() {
  top->clk = 0; top->eval();
  top->clk = 1; top->eval();
  cycles++;
}

// ---------------------------------------------------------------- SD card (hps_io) for the SV-801
// One image in memory; writes stay in memory (the file is never changed).
static std::vector<uint8_t> disk_img;
static int sd_state = 0, sd_cnt = 0, sd_addr = 0;
static uint32_t sd_lba_r = 0;
static bool sd_is_wr = false;
static uint64_t sd_reads = 0, sd_writes = 0;
static void sd_step() {
  top->sd_buff_wr = 0;
  switch (sd_state) {
    case 0:
      if (top->sd_rd || top->sd_wr) {
        sd_is_wr = top->sd_wr; sd_lba_r = top->sd_lba; sd_cnt = 40; sd_state = 1;
        if (sd_is_wr) sd_writes++; else sd_reads++;
      }
      break;
    case 1:
      if (--sd_cnt == 0) { top->sd_ack = 1; sd_addr = 0; sd_cnt = 0; sd_state = 2; }
      break;
    case 2: {
      // one byte every 4 clocks, as hps_io paces it
      if (++sd_cnt < 4) {
        if (sd_is_wr && sd_cnt == 1) top->sd_buff_addr = sd_addr;
        break;
      }
      sd_cnt = 0;
      size_t off = (size_t)sd_lba_r * 512 + sd_addr;
      if (sd_is_wr) {
        if (off < disk_img.size()) disk_img[off] = top->sd_buff_din;
      } else {
        top->sd_buff_addr = sd_addr;
        top->sd_buff_dout = off < disk_img.size() ? disk_img[off] : 0;
        top->sd_buff_wr = 1;
      }
      if (++sd_addr == 512) { sd_state = 3; sd_cnt = 8; }
      break;
    }
    case 3:
      if (--sd_cnt == 0) { top->sd_ack = 0; sd_state = 4; sd_cnt = 8; }
      break;
    case 4:
      if (--sd_cnt == 0) sd_state = 0;
      break;
  }
}

static void download(int target, uint32_t base, const std::vector<uint8_t>& d) {
  top->dl_busy = 1; top->dl_target = target; tick(); tick();
  for (size_t i = 0; i < d.size(); i++) {
    top->dl_wr = 1; top->dl_target = target; top->dl_addr = base + i; top->dl_data = d[i];
    tick();
    top->dl_wr = 0; tick();          // hps_io: one write strobe per byte
  }
  top->dl_wr = 0; tick();
  top->dl_busy = 0; tick();
}

// ---------------------------------------------------------------- tape bookkeeping
static std::vector<uint32_t> block_starts;   // offsets of 16 x 55 + 7F in the CAS image
static std::vector<uint8_t> cas_img;
static void scan_blocks() {
  for (size_t i = 0; i + 17 <= cas_img.size(); i++) {
    bool ok = cas_img[i + 16] == 0x7F;
    for (int j = 0; ok && j < 16; j++) ok = cas_img[i + j] == 0x55;
    if (ok) { block_starts.push_back(i); i += 16; }
  }
}
static int block_of(uint32_t a) {
  auto it = std::upper_bound(block_starts.begin(), block_starts.end(), a);
  return int(it - block_starts.begin()) - 1;
}

// ---------------------------------------------------------------- screen text (VDP text/graphics I name table)
static int vdp_reg(int n) {
  // ctrl_reg_q is declared [0:7] per element, i.e. bit 0 = MSB, which Verilator stores as normal bits
  return top->rootp->svi_sim->console__DOT__vdp__DOT__cpu_io_b__DOT__ctrl_reg_q[n];
}

// SVI BASIC's character set is ASCII shifted down by 20h (VRAM 00 = space, 21 = 'A')
static char svi_char(uint8_t c) { return c < 0x5F ? char(c + 0x20) : '.'; }

static void print_text(int f) {
  int r1 = vdp_reg(1), r2 = vdp_reg(2);
  bool text_mode = r1 & 0x10;   // M1
  int cols = text_mode ? 40 : 32;
  int base = (r2 & 0x0F) * 0x400;
  printf("--- screen at frame %d (%s, name table %04X) ---\n", f, text_mode ? "text 40" : "32 col", base);
  for (int y = 0; y < 24; y++) {
    std::string line;
    for (int x = 0; x < cols; x++) {
      uint8_t c = top->rootp->svi_sim->vram[(base + y * cols + x) & 0x3FFF];
      line += svi_char(c);
    }
    while (!line.empty() && line.back() == ' ') line.pop_back();
    printf("|%s\n", line.c_str());
  }
  fflush(stdout);
}

static bool screen_contains(const std::string& s) {
  int r1 = vdp_reg(1), r2 = vdp_reg(2);
  int cols = (r1 & 0x10) ? 40 : 32, base = (r2 & 0x0F) * 0x400;
  std::string all;
  for (int i = 0; i < cols * 24; i++) {
    uint8_t c = top->rootp->svi_sim->vram[(base + i) & 0x3FFF];
    all += svi_char(c);
    if ((i + 1) % cols == 0) all += '\n';
  }
  return all.find(s) != std::string::npos;
}

// ---------------------------------------------------------------- WAV
static FILE* wav = nullptr; static uint32_t wav_samples = 0;
static void wav_open() {
  wav = fopen(wav_path.c_str(), "wb"); if (!wav) { perror("wav"); exit(1); }
  uint8_t h[44] = {0}; fwrite(h, 1, 44, wav);
}
static void wav_close() {
  if (!wav) return;
  uint32_t rate = 44100, bytes = wav_samples * 2;
  fseek(wav, 0, SEEK_SET);
  auto w32 = [](uint32_t v) { fwrite(&v, 4, 1, wav); };
  auto w16 = [](uint16_t v) { fwrite(&v, 2, 1, wav); };
  fwrite("RIFF", 1, 4, wav); w32(36 + bytes); fwrite("WAVEfmt ", 1, 8, wav);
  w32(16); w16(1); w16(1); w32(rate); w32(rate * 2); w16(2); w16(16);
  fwrite("data", 1, 4, wav); w32(bytes); fclose(wav);
}

// ---------------------------------------------------------------- usage
static void usage() {
  puts("Vsvi_sim options:\n"
       "  --rom FILE              BIOS/BASIC ROM (default ../software/mister11/boot.rom)\n"
       "  --cart FILE             cartridge ROM at SDRAM 10000 (bank 11)\n"
       "  --tape FILE             CAS image into the tape buffer (SDRAM in hardware; 4 MB here)\n"
       "  --frames N              stop after N frames (required)\n"
       "  --shots F1,F2,..        save these frames as OUTDIR/frame_NNNNN.png\n"
       "  --every K               save every Kth frame\n"
       "  --outdir DIR            (default ./out)\n"
       "  --no-overlay             OSD Tape overlay = Off\n"
       "  --ntsc                   OSD Video standard = NTSC (default PAL)\n"
       "  --disk FILE              SV-801 on, FILE (.dsk, 172032 / 346112 bytes) in drive 0\n"
       "  --fdc                    SV-801 on, no disk\n"
       "  --80col / --show80       SV-806 on / and show its output (Display = 80-column)\n"
       "  --charrom FILE           SV-806 character ROM (boot1.rom; implies --80col)\n"
       "  --318                    OSD Model = SVI-318 (16 KB at C000-FFFF)\n"
       "  --mem-std                OSD Memory = Standard (no SV-807 banks)\n"
       "  --type 'TEXT@FRAME'     type TEXT from FRAME (\\n = Return), 5 frames per key\n"
       "  --key NAME@FRAME[:N]    hold a key N frames (enter space esc bs tab stop f1-f5 up down\n"
       "                          left right ins del home caps ctrl shift lgraph rgraph)\n"
       "  --joy BITS@FRAME[:N][/2] joystick: BITS from 'udlrf' (f = fire), N frames, /2 = port 2\n"
       "  --text F1,F2,..         print the screen's text (name table) at these frames\n"
       "  --text-end              print the screen's text at the end\n"
       "  --until 'TEXT'          stop as soon as TEXT appears on screen (checked every 10 frames)\n"
       "  --after-motor N         stop N frames after the tape motor last switched off\n"
       "  --tape-log              log motor on/off with CAS position and block numbers\n"
       "  --turbo                 OSD Tape speed = 4x (full-rate build only)\n"
       "  --io-log                log PPI port A (98h) reads per frame and PSG/PPI writes\n"
       "  --profile N             sample the Z80 PC every N cycles, print the busiest at exit\n"
       "  --dump-ram FILE@FRAME   write the 256 KB SDRAM window at FRAME\n"
       "  --wav FILE              write audio as 44.1 kHz mono WAV\n"
       "  --border                VDP border on\n");
}

static std::pair<std::string, int> split_at(const std::string& s) {
  size_t p = s.rfind('@');
  if (p == std::string::npos) { fprintf(stderr, "missing @FRAME in '%s'\n", s.c_str()); exit(1); }
  return {s.substr(0, p), atoi(s.c_str() + p + 1)};
}

static void parse_list(const char* s, std::set<int>& out) {
  std::string t(s); size_t p = 0;
  while (p < t.size()) { size_t q = t.find(',', p); if (q == std::string::npos) q = t.size();
    out.insert(atoi(t.substr(p, q - p).c_str())); p = q + 1; }
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  for (int i = 1; i < argc; i++) {
    std::string a = argv[i];
    auto next = [&]() -> const char* { if (i + 1 >= argc) { fprintf(stderr, "%s needs a value\n", a.c_str()); exit(1); } return argv[++i]; };
    if (a == "--help" || a == "-h") { usage(); return 0; }
    else if (a == "--rom") rom_path = next();
    else if (a == "--cart") cart_path = next();
    else if (a == "--tape") tape_path = next();
    else if (a == "--frames") run_frames = atoi(next());
    else if (a == "--shots") parse_list(next(), shots);
    else if (a == "--every") every = atoi(next());
    else if (a == "--outdir") outdir = next();
    else if (a == "--type") { auto p = split_at(next()); schedule_text(p.second, p.first); }
    else if (a == "--key") {
      std::string s = next(); int len = 3; size_t c = s.find(':');
      if (c != std::string::npos) { len = atoi(s.c_str() + c + 1); s = s.substr(0, c); }
      auto p = split_at(s); uint8_t code; bool ext;
      if (!key_name(p.first, code, ext)) { fprintf(stderr, "unknown key %s\n", p.first.c_str()); return 1; }
      sched.push_back({p.second, {code, ext, true}});
      sched.push_back({p.second + len, {code, ext, false}});
    }
    else if (a == "--joy") {
      std::string s = next(); int port = 0, len = 3;
      if (s.size() > 2 && s.substr(s.size() - 2) == "/2") { port = 1; s = s.substr(0, s.size() - 2); }
      size_t c = s.find(':'); if (c != std::string::npos) { len = atoi(s.c_str() + c + 1); s = s.substr(0, c); }
      auto p = split_at(s); uint32_t bits = 0;
      for (char ch : p.first) bits |= ch == 'r' ? 1 : ch == 'l' ? 2 : ch == 'd' ? 4 : ch == 'u' ? 8 : ch == 'f' ? 16 : 0;
      joy_evs.push_back({p.second, len, bits, port});
    }
    else if (a == "--text") parse_list(next(), text_frames);
    else if (a == "--text-end") text_at_end = true;
    else if (a == "--until") stop_text = next();
    else if (a == "--after-motor") stop_after_motor_off = atoi(next());
    else if (a == "--tape-log") tape_log = true;
    else if (a == "--turbo") {
#ifndef SIM_FULL
      fprintf(stderr, "--turbo needs the full-rate build (make full, obj_full/Vsvi_sim)\n"); return 1;
#endif
      tape_turbo = true;
    }
    else if (a == "--io-log") io_log = true;
    else if (a == "--profile") profile_every = atoll(next());
    else if (a == "--dump-ram") { auto p = split_at(next()); dump_ram[p.second] = p.first; }
    else if (a == "--wav") wav_path = next();
    else if (a == "--border") border = true;
    else if (a == "--no-overlay") no_overlay = true;
    else if (a == "--ntsc") ntsc = true;
    else if (a == "--318") model_318 = true;
    else if (a == "--mem-std") mem_std = true;
    else if (a == "--disk") { disk_path = next(); fdc_on = true; }
    else if (a == "--fdc") fdc_on = true;
    else if (a == "--80col") m806_on = true;
    else if (a == "--show80") { m806_on = true; show80 = true; }
    else if (a == "--charrom") { charrom_path = next(); m806_on = true; }
    else { fprintf(stderr, "unknown option %s\n", a.c_str()); usage(); return 1; }
  }
  if (run_frames <= 0) { fprintf(stderr, "--frames N is required\n"); return 1; }
  mkdir(outdir.c_str(), 0755);
  std::sort(sched.begin(), sched.end(), [](const Sched& x, const Sched& y) { return x.frame < y.frame; });

  top = new Vsvi_sim;
  top->border = border;
  top->overlay_off = no_overlay;
  top->ntsc = ntsc;
  top->model_318 = model_318;
  top->mem_std = mem_std;
  top->fdc_on = fdc_on;
  top->m806_on = m806_on;
  top->show80 = show80;
  top->sd_ack = 0; top->sd_buff_wr = 0; top->img_mounted = 0; top->img_readonly = 0;
  top->tape_turbo = tape_turbo;
  top->reset = 1; top->ps2_key = 0; top->joy0 = 0; top->joy1 = 0;
  for (int i = 0; i < 16; i++) tick();

  // Main loads boot.rom as index 0 and a cartridge as index 1 while reset is held
  download(0, 0x00000, read_file(rom_path));
  if (!cart_path.empty()) download(0, 0x10000, read_file(cart_path));
  if (!charrom_path.empty()) download(2, 0, read_file(charrom_path));   // boot1.rom
  if (!tape_path.empty()) {
    cas_img = read_file(tape_path);
    download(1, 0, cas_img);
    top->tape_end = cas_img.size() - 1;   // Svi328.sv: last ioctl_addr
    scan_blocks();
    printf("tape: %zu bytes, %zu blocks%s\n", cas_img.size(), block_starts.size(),
           cas_img.size() > 4194304 ? " (LARGER THAN THE SIM'S 4 MB BUFFER)" : "");
  }
  top->tape_rewind = 1; for (int i = 0; i < 8; i++) tick(); top->tape_rewind = 0;
  for (int i = 0; i < 64; i++) tick();
  top->reset = 0;
  if (!disk_path.empty()) {
    // hps_io: img_mounted with img_size, held a while (wd1793 samples on its ce)
    disk_img = read_file(disk_path);
    top->img_size = disk_img.size(); top->img_mounted = 1;
    for (int i = 0; i < 2000; i++) tick();
    top->img_mounted = 0;
    printf("disk: %zu bytes\n", disk_img.size());
  }
  if (!wav_path.empty()) wav_open();

  size_t si = 0;
  int last_motor = -1, last_motor_off_frame = -1;
  uint32_t ppi_a_reads = 0, ppi_a_zero_fire = 0;
  bool prev_io = false;
  std::map<uint16_t, uint64_t> pc_hist;
  uint64_t wav_acc = 0;

  while (frame < run_frames) {
    // scripted input for this frame (applied once per frame at its start)
    tick();
    if (fdc_on) sd_step();

    // PS/2 queue: one event every 2000 cycles
    if (!ps2q.empty() && cycles >= ps2_next) {
      PS2 e = ps2q.front(); ps2q.pop_front();
      ps2_toggle ^= 1;
      top->ps2_key = (e.code & 0xFF) | (e.ext << 8) | (e.press << 9) | (ps2_toggle << 10);
      ps2_next = cycles + 2000;
    }

    // video: pixel on ce_pix outside blanking
    if (top->ce_pix) {
      bool hb = top->HBlank, vb = top->VBlank;
      if (!hb && !vb) {
        if (vx < FB_W && vy < FB_H) {
          uint8_t* p = &fb[(vy * FB_W + vx) * 3]; p[0] = top->R; p[1] = top->G; p[2] = top->B;
        }
        vx++; line_had_pixels = true;
      }
      if (hb && !prev_hb) {   // end of a line
        if (line_had_pixels) { max_x = std::max(max_x, vx); vy++; }
        vx = 0; line_had_pixels = false;
      }
      prev_hb = hb;
    }

    // I/O watch
    bool io = !top->cpu_iorq_n && top->cpu_m1_n && (!top->cpu_rd_n || !top->cpu_wr_n);
    if (io && !prev_io) {
      uint8_t port = top->cpu_a & 0xFF;
      if (port == 0x98 && !top->cpu_rd_n) {
        ppi_a_reads++;
      }
      if (io_log && !top->cpu_wr_n && (port == 0x88 || port == 0x8C || port == 0x97))
        printf("f%d io W %02X <- %02X\n", frame, port, top->cpu_dout);
    }
    if (io && !top->cpu_rd_n && (top->cpu_a & 0xFF) == 0x98 && io_log) {
      // sample the value the CPU sees at the end of the read cycle
      static uint8_t last_seen = 0xFF; last_seen = top->cpu_din;
      if ((last_seen & 0x10) == 0) ppi_a_zero_fire++;
    }
    prev_io = io;

#ifdef SIM_T80
    // no PC register to peek at in the netlist: sample the opcode fetch address
    { static uint64_t next_sample = 0;
      if (profile_every && cycles >= next_sample && !top->cpu_m1_n && top->cpu_iorq_n) {
        pc_hist[top->cpu_a]++; next_sample = cycles + profile_every; } }
#else
    if (profile_every && cycles % profile_every == 0)
      pc_hist[top->rootp->svi_sim->console__DOT__cpu__DOT__i_tv80_core__DOT__PC]++;
#endif

    if (wav) { wav_acc += 44100; if (wav_acc >= CLK_HZ) { wav_acc -= CLK_HZ;
      int16_t s = int16_t((top->audio << 4) - 16384); fwrite(&s, 2, 1, wav); wav_samples++; } }

    // motor
    int m = top->motor;
    if (m != last_motor) {
      if (tape_log && last_motor != -1 && !cas_img.empty()) {
        uint32_t a = top->cas_addr; int b = block_of(a);
        printf("f%d motor %s%s  CAS_addr=%06X (%u)  block %d%s  +%d\n", frame, m ? "ON " : "OFF", tape_turbo && m ? " (4x)" : "", a, a,
               b, b >= 0 ? "" : " (before first)", b >= 0 ? int(a - block_starts[b]) : 0);
        fflush(stdout);
      }
      if (!m) last_motor_off_frame = frame;
      last_motor = m;
    }

    // frame boundary on VSync rising edge
    bool vs = top->VSync;
    if (vs && !prev_vs) {
      if (vy > 0) { last_w = std::min(max_x, FB_W); last_h = std::min(vy, FB_H); }
      vy = 0; vx = 0; max_x = 0;
      frame++;
      if (shots.count(frame) || (every && frame % every == 0)) {
        std::vector<uint8_t> out(last_w * last_h * 3);
        for (int y = 0; y < last_h; y++) memcpy(&out[y * last_w * 3], &fb[y * FB_W * 3], last_w * 3);
        char name[64]; snprintf(name, sizeof name, "/frame_%05d.png", frame);
        write_png(outdir + name, last_w, last_h, out);
      }
      if (text_frames.count(frame)) print_text(frame);
      if (dump_ram.count(frame)) {
        FILE* f = fopen(dump_ram[frame].c_str(), "wb");
        for (int i = 0; i < 262144; i++) fputc(top->rootp->svi_sim->sdram[i], f);
        fclose(f); printf("f%d dumped SDRAM to %s\n", frame, dump_ram[frame].c_str());
      }
      if (io_log) { printf("f%d ppiA reads=%u fire1_low=%u\n", frame, ppi_a_reads, ppi_a_zero_fire); }
      ppi_a_reads = 0; ppi_a_zero_fire = 0;

      // scheduled keys and joystick for the new frame
      while (si < sched.size() && sched[si].frame <= frame) ps2q.push_back(sched[si++].ev);
      uint32_t j0 = 0, j1 = 0;
      for (auto& e : joy_evs) if (frame >= e.frame && frame < e.frame + e.len) (e.port ? j1 : j0) |= e.bits;
      top->joy0 = j0; top->joy1 = j1;

      if (!stop_text.empty() && frame % 10 == 0 && screen_contains(stop_text)) {
        printf("f%d found \"%s\" on screen\n", frame, stop_text.c_str()); break;
      }
      // only after the last scripted key (the BIOS blips the motor at boot)
      int last_input = sched.empty() ? 0 : sched.back().frame;
      if (stop_after_motor_off >= 0 && last_motor == 0 && last_motor_off_frame > last_input &&
          frame - last_motor_off_frame >= stop_after_motor_off) {
        printf("f%d motor off for %d frames, stopping\n", frame, stop_after_motor_off); break;
      }
      if (frame % 500 == 0) { fprintf(stderr, "frame %d\n", frame); }
    }
    prev_vs = vs;
  }

  if (text_at_end) print_text(frame);
  if (!pc_hist.empty()) {
    std::vector<std::pair<uint64_t, uint16_t>> v;
    for (auto& p : pc_hist) v.push_back({p.second, p.first});
    std::sort(v.rbegin(), v.rend());
    printf("PC profile:\n");
    for (size_t i = 0; i < v.size() && i < 20; i++) printf("  %04X %llu\n", v[i].second, (unsigned long long)v[i].first);
  }
  printf("done: %d frames, %llu cycles, last frame %dx%d, CAS_addr=%06X\n", frame,
         (unsigned long long)cycles, last_w, last_h, (unsigned)top->cas_addr);
  wav_close();
  delete top;
  return 0;
}
