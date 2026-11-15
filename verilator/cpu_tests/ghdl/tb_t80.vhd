-- GHDL testbench for T80pa (Mode 0) running the tests written by "VT80pa pindump".
-- Drives the core exactly like cpu_t80.h (reset, DIRSet load, one CLK with CEN_p then one
-- with CEN_n per T-state, DI from the current address/strobes) and prints the same pin
-- trace, so the Verilator run of the GHDL --synth netlist can be diffed against a
-- simulation of the original VHDL.
--   ghdl -r tb_t80 -gINFILE=tests.txt > trace.txt
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_t80 is
  generic (INFILE : string := "tests.txt");
end;

architecture sim of tb_t80 is
  signal clk, rst_n, cen_p, cen_n, dirset : std_logic := '0';
  signal m1, mreq, iorq, rd, wr, rfsh : std_logic;
  signal a : std_logic_vector(15 downto 0);
  signal di, do_s : std_logic_vector(7 downto 0) := (others => '0');
  signal dir, reg : std_logic_vector(211 downto 0) := (others => '0');
begin
  u : entity work.T80pa
    generic map (Mode => 0)
    port map (RESET_n => rst_n, CLK => clk, CEN_p => cen_p, CEN_n => cen_n, WAIT_n => '1',
              INT_n => '1', NMI_n => '1', BUSRQ_n => '1', M1_n => m1, MREQ_n => mreq,
              IORQ_n => iorq, RD_n => rd, WR_n => wr, RFSH_n => rfsh, HALT_n => open,
              BUSAK_n => open, OUT0 => '0', A => a, DI => di, DO => do_s, REG => reg,
              DIRSet => dirset, DIR => dir);

  process
    type mem_t is array (0 to 65535) of integer range 0 to 255;
    variable mem : mem_t := (others => 0);
    type ports_t is array (0 to 15) of integer;
    variable paddr, pval : ports_t;
    variable np : integer := 0;
    file fin : text open read_mode is INFILE;
    variable l, o : line;
    variable v : integer;
    variable r : integer_vector(0 to 21);
    variable nram, ad, va, nt : integer;
    variable cur_a : integer;

    function b(s : std_logic) return character is
    begin
      if s = '0' then return '1'; elsif s = '1' then return '0'; else return 'X'; end if;
    end function;

    procedure clock is
    begin
      clk <= '1'; wait for 1 ns; clk <= '0'; wait for 1 ns;
    end procedure;

    -- one CLK edge with the given enables; DI from the pins before the edge
    procedure half(p : boolean; prt : boolean) is
      variable ai : integer;
      variable d : integer;
    begin
      if p then cen_p <= '1'; cen_n <= '0'; else cen_p <= '0'; cen_n <= '1'; end if;
      if is_x(a) then ai := 0; else ai := to_integer(unsigned(a)); end if;
      d := mem(ai);
      if iorq = '0' and m1 = '0' then
        d := 255;
      elsif iorq = '0' and rd = '0' then
        d := 255;
        for k in 0 to np - 1 loop
          if paddr(k) = ai then d := pval(k); end if;
        end loop;
      end if;
      di <= std_logic_vector(to_unsigned(d, 8));
      wait for 1 ns;
      clk <= '1'; wait for 1 ns;
      if prt then
        write(o, to_hstring(a));
        if wr = '0' then write(o, string'(" ") & to_hstring(do_s) & string'(" "));
        else write(o, string'(" -- ")); end if;
        write(o, b(m1)); write(o, b(mreq)); write(o, b(iorq)); write(o, b(rd)); write(o, b(wr)); write(o, b(rfsh));
        writeline(output, o);
      end if;
      if wr = '0' and mreq = '0' and not is_x(a) then
        mem(to_integer(unsigned(a))) := to_integer(unsigned(do_s));
      end if;
      clk <= '0'; wait for 1 ns;
    end procedure;

    procedure reset is
    begin
      rst_n <= '0'; cen_p <= '0'; cen_n <= '0';
      for i in 0 to 3 loop clock; end loop;
      rst_n <= '1'; wait for 1 ns;
    end procedure;

    procedure setv(lo, n, val : integer) is
    begin
      dir(lo + n - 1 downto lo) <= std_logic_vector(to_unsigned(val, n));
    end procedure;
  begin
    -- power-up: reset and a few NOPs (as the C++ constructor)
    reset;
    for i in 0 to 15 loop half(true, false); half(false, false); end loop;
    cen_n <= '0';
    loop
      readline(fin, l);
      exit when l.all = "END";
      write(o, string'("T ") & l.all);
      writeline(output, o);
      readline(fin, l);
      for k in 0 to 21 loop read(l, r(k)); end loop;
      readline(fin, l);
      mem := (others => 0);
      read(l, nram);
      for k in 1 to nram loop read(l, ad); read(l, va); mem(ad) := va; end loop;
      readline(fin, l);
      read(l, np);
      for k in 0 to np - 1 loop read(l, paddr(k)); read(l, pval(k)); end loop;
      -- r: pc sp a f b c d e h l i r ix iy af_ bc_ de_ hl_ im iff1 iff2 nt
      reset;
      dir <= (others => '0');
      wait for 0 ns;
      setv(0, 8, r(2)); setv(8, 8, r(3)); setv(16, 8, r(14) / 256); setv(24, 8, r(14) mod 256);
      setv(32, 8, r(10)); setv(40, 8, r(11)); setv(48, 16, r(1)); setv(64, 16, r(0));
      setv(80, 16, r(4) * 256 + r(5)); setv(96, 16, r(6) * 256 + r(7)); setv(112, 16, r(8) * 256 + r(9));
      setv(128, 16, r(12)); setv(144, 16, r(15)); setv(160, 16, r(16)); setv(176, 16, r(17));
      setv(192, 16, r(13)); setv(208, 2, r(18)); setv(210, 1, r(19)); setv(211, 1, r(20));
      nt := r(21);
      dirset <= '1'; wait for 1 ns;
      clock;
      dirset <= '0'; wait for 1 ns;
      for t in 0 to nt - 1 loop
        half(true, true);
        half(false, true);
      end loop;
      cen_n <= '0';
      write(o, string'("R ") & to_hstring(reg));
      writeline(output, o);
    end loop;
    std.env.finish;
  end process;
end;
