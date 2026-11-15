library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use work.kbd_pkg.all;

entity sviKeyboard is
port
(
    clk       	: in     std_logic;
    reset     	: in     std_logic;

    -- Ps2 Input From HPS_io
    keys        : in		std_logic_vector(10 downto 0);

    -- Svi-3x8 matrix
    svi_row  : in  	std_logic_vector(3 downto 0);
    svi_col  : out 	std_logic_vector(7 downto 0)
);
end sviKeyboard;

architecture SYN of sviKeyboard is

  signal rst_n			: std_logic;
  signal ps2_chg     : std_logic;
  -- The SVI key right of L gives ':' unshifted and ';' shifted, the reverse
  -- of a PC. The matrix sees the PC's Shift inverted while that key is down,
  -- so Shift+; types ':' as printed on the PC key.
  signal lshift, rshift, semi : std_logic;
  signal svi_shift   : std_logic;

  type key_matrix is array (0 to 15) of std_logic_vector(7 downto 0);
  signal svi_matrix  : key_matrix;

begin

	rst_n <= not reset;
	
	svi_shift <= (lshift or rshift) xor semi;
	svi_col <= not (svi_matrix(CONV_INTEGER(svi_row))(7 downto 1) & (svi_matrix(CONV_INTEGER(svi_row))(0) or svi_shift)) when CONV_INTEGER(svi_row) = 6 else
	           not svi_matrix(CONV_INTEGER(svi_row));

   latchInputs: process (clk, rst_n, keys)
		variable ps2_press      : std_logic;
		variable ps2_scancode   : std_logic_vector(7 downto 0);

    begin

	 
		  if rst_n = '0' then
               svi_matrix(0) <= (others => '0');
               svi_matrix(1) <= (others => '0');
               svi_matrix(2) <= (others => '0');
               svi_matrix(3) <= (others => '0');
               svi_matrix(4) <= (others => '0');
               svi_matrix(5) <= (others => '0');
               svi_matrix(6) <= (others => '0');
               svi_matrix(7) <= (others => '0');
               svi_matrix(8) <= (others => '0');
               svi_matrix(9) <= (others => '0');
               svi_matrix(10) <= (others => '0');
               svi_matrix(11) <= (others => '0');
               svi_matrix(12) <= (others => '0');
               svi_matrix(13) <= (others => '0');
               svi_matrix(14) <= (others => '0');
               svi_matrix(15) <= (others => '0');
					
					ps2_chg <= '0';
					lshift <= '0'; rshift <= '0'; semi <= '0';

        elsif rising_edge (clk) then
         -- note: all inputs are active HIGH
			
	 		ps2_chg <= keys(10);
			ps2_press := keys(9);
			ps2_scancode := keys(7 downto 0);
		
            -- svi key matrix. keys(8) = E0 prefix: the arrows, Insert,
            -- Delete, Home and the right Ctrl/GUI/Alt share codes with the
            -- keypad and the left keys, so the two sets are decoded apart.
            -- Rows as MAME (svi318.cpp) and the Common Source Code Project
            -- (svi3x8/keyboard.cpp): row 7 bit 5 CLS (Home), bit 6 INS.
			svi_matrix(6)(0) <= '0';   -- Shift comes from svi_shift
			svi_matrix(8)(6) <= '0';   -- no key
			svi_matrix(10)(7) <= '0';  -- keypad comma: no PC key
			for i in 11 to 15 loop     -- rows the SVI doesn't have
				svi_matrix(i) <= (others => '0');
			end loop;
			if (ps2_chg /= keys(10)) then
              if keys(8) = '1' then
                case ps2_scancode is
                    when X"75" => svi_matrix(5)(7) <= ps2_press;  -- Up
                    when X"72" => svi_matrix(7)(7) <= ps2_press;  -- Down
                    when X"6B" => svi_matrix(6)(7) <= ps2_press;  -- Left
                    when X"74" => svi_matrix(8)(7) <= ps2_press;  -- Right
                    when X"70" => svi_matrix(7)(6) <= ps2_press;  -- Insert: INS
                    when X"6C" => svi_matrix(7)(5) <= ps2_press;  -- Home: CLS
                    when X"71" => svi_matrix(8)(2) <= ps2_press;  -- Delete: DEL
                    when X"14" => svi_matrix(6)(1) <= ps2_press;  -- right Ctrl
                    when X"1F" => svi_matrix(6)(2) <= ps2_press;  -- left GUI: left GRAPH
                    when X"27" => svi_matrix(6)(3) <= ps2_press;  -- right GUI: right GRAPH
                    when X"11" => svi_matrix(6)(3) <= ps2_press;  -- right Alt: right GRAPH
                    when X"5A" => svi_matrix(6)(6) <= ps2_press;  -- keypad Enter
                    when X"4A" => svi_matrix(10)(5) <= ps2_press; -- keypad /
                    when others => null;
                end case;
              else
                case ps2_scancode is
                    when SCANCODE_7         => svi_matrix(0)(7) <= ps2_press;
                    when SCANCODE_6         => svi_matrix(0)(6) <= ps2_press;
                    when SCANCODE_5         => svi_matrix(0)(5) <= ps2_press;
                    when SCANCODE_4         => svi_matrix(0)(4) <= ps2_press;
                    when SCANCODE_3         => svi_matrix(0)(3) <= ps2_press;
                    when SCANCODE_2         => svi_matrix(0)(2) <= ps2_press;
                    when SCANCODE_1         => svi_matrix(0)(1) <= ps2_press;
                    when SCANCODE_0         => svi_matrix(0)(0) <= ps2_press;

                    when SCANCODE_SLASH     => svi_matrix(1)(7) <= ps2_press;
                    when SCANCODE_PERIOD    => svi_matrix(1)(6) <= ps2_press;
                    when SCANCODE_EQUALS    => svi_matrix(1)(5) <= ps2_press;
                    when SCANCODE_COMMA     => svi_matrix(1)(4) <= ps2_press;
                    when SCANCODE_QUOTE     => svi_matrix(1)(3) <= ps2_press;
                    when SCANCODE_SEMICOLON => svi_matrix(1)(2) <= ps2_press; semi <= ps2_press;
                    when SCANCODE_9         => svi_matrix(1)(1) <= ps2_press;
                    when SCANCODE_8         => svi_matrix(1)(0) <= ps2_press;

                    when SCANCODE_G         => svi_matrix(2)(7) <= ps2_press;
                    when SCANCODE_F         => svi_matrix(2)(6) <= ps2_press;
                    when SCANCODE_E         => svi_matrix(2)(5) <= ps2_press;
                    when SCANCODE_D         => svi_matrix(2)(4) <= ps2_press;
                    when SCANCODE_C         => svi_matrix(2)(3) <= ps2_press;
                    when SCANCODE_B         => svi_matrix(2)(2) <= ps2_press;
                    when SCANCODE_A         => svi_matrix(2)(1) <= ps2_press;
                    when SCANCODE_MINUS     => svi_matrix(2)(0) <= ps2_press;

                    when SCANCODE_O         => svi_matrix(3)(7) <= ps2_press;
                    when SCANCODE_N         => svi_matrix(3)(6) <= ps2_press;
                    when SCANCODE_M         => svi_matrix(3)(5) <= ps2_press;
                    when SCANCODE_L         => svi_matrix(3)(4) <= ps2_press;
                    when SCANCODE_K         => svi_matrix(3)(3) <= ps2_press;
                    when SCANCODE_J         => svi_matrix(3)(2) <= ps2_press;
                    when SCANCODE_I         => svi_matrix(3)(1) <= ps2_press;
                    when SCANCODE_H         => svi_matrix(3)(0) <= ps2_press;

                    when SCANCODE_W         => svi_matrix(4)(7) <= ps2_press;
                    when SCANCODE_V         => svi_matrix(4)(6) <= ps2_press;
                    when SCANCODE_U         => svi_matrix(4)(5) <= ps2_press;
                    when SCANCODE_T         => svi_matrix(4)(4) <= ps2_press;
                    when SCANCODE_S         => svi_matrix(4)(3) <= ps2_press;
                    when SCANCODE_R         => svi_matrix(4)(2) <= ps2_press;
                    when SCANCODE_Q         => svi_matrix(4)(1) <= ps2_press;
                    when SCANCODE_P         => svi_matrix(4)(0) <= ps2_press;

                    when SCANCODE_BACKSPACE => svi_matrix(5)(6) <= ps2_press;
                    when SCANCODE_CLOSEBRKT => svi_matrix(5)(5) <= ps2_press;
                    when SCANCODE_BACKSLASH => svi_matrix(5)(4) <= ps2_press;
                    when SCANCODE_OPENBRKT  => svi_matrix(5)(3) <= ps2_press;
                    when SCANCODE_Z         => svi_matrix(5)(2) <= ps2_press;
                    when SCANCODE_Y         => svi_matrix(5)(1) <= ps2_press;
                    when SCANCODE_X         => svi_matrix(5)(0) <= ps2_press;

                    when SCANCODE_ENTER     => svi_matrix(6)(6) <= ps2_press;
                    when SCANCODE_F8        => svi_matrix(6)(5) <= ps2_press; -- STOP
                    when SCANCODE_F6        => svi_matrix(6)(5) <= ps2_press; -- STOP (as CSP)
                    when SCANCODE_ESC       => svi_matrix(6)(4) <= ps2_press;
                    when SCANCODE_LALT      => svi_matrix(6)(2) <= ps2_press; -- left GRAPH
                    when SCANCODE_LCTRL     => svi_matrix(6)(1) <= ps2_press;
                    when SCANCODE_LSHIFT    => lshift <= ps2_press;   -- matrix bit: svi_shift
                    when SCANCODE_RSHIFT    => rshift <= ps2_press;

                    when SCANCODE_F5        => svi_matrix(7)(4) <= ps2_press;
                    when SCANCODE_F4        => svi_matrix(7)(3) <= ps2_press;
                    when SCANCODE_F3        => svi_matrix(7)(2) <= ps2_press;
                    when SCANCODE_F2        => svi_matrix(7)(1) <= ps2_press;
                    when SCANCODE_F1        => svi_matrix(7)(0) <= ps2_press;

                    when SCANCODE_F9        => svi_matrix(8)(5) <= ps2_press; -- PRINT
                    when SCANCODE_F7        => svi_matrix(8)(4) <= ps2_press; -- SELECT
                    when SCANCODE_CAPSLOCK  => svi_matrix(8)(3) <= ps2_press;
                    when SCANCODE_TAB       => svi_matrix(8)(1) <= ps2_press;
                    when SCANCODE_SPACE     => svi_matrix(8)(0) <= ps2_press;

                    -- keypad (SVI-328): row 9 = 0-7, row 10 = 8 9 + - * / . ,
                    when X"70" => svi_matrix(9)(0) <= ps2_press;
                    when X"69" => svi_matrix(9)(1) <= ps2_press;
                    when X"72" => svi_matrix(9)(2) <= ps2_press;
                    when X"7A" => svi_matrix(9)(3) <= ps2_press;
                    when X"6B" => svi_matrix(9)(4) <= ps2_press;
                    when X"73" => svi_matrix(9)(5) <= ps2_press;
                    when X"74" => svi_matrix(9)(6) <= ps2_press;
                    when X"6C" => svi_matrix(9)(7) <= ps2_press;
                    when X"75" => svi_matrix(10)(0) <= ps2_press;
                    when X"7D" => svi_matrix(10)(1) <= ps2_press;
                    when X"79" => svi_matrix(10)(2) <= ps2_press; -- +
                    when X"7B" => svi_matrix(10)(3) <= ps2_press; -- -
                    when X"7C" => svi_matrix(10)(4) <= ps2_press; -- *
                    when X"71" => svi_matrix(10)(6) <= ps2_press; -- .

                    when others          => null;
                end case;
              end if;
            end if;
        end if; -- rising_edge (clk)
    end process latchInputs;

  
end SYN;
