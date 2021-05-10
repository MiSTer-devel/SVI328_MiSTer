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

  type key_matrix is array (0 to 15) of std_logic_vector(7 downto 0);
  signal svi_matrix  : key_matrix;

begin

	rst_n <= not reset;
	
	svi_col <= not svi_matrix(CONV_INTEGER(svi_row));

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

        elsif rising_edge (clk) then
         -- note: all inputs are active HIGH
			
	 		ps2_chg <= keys(10);
			ps2_press := keys(9);
			ps2_scancode := keys(7 downto 0);
		
            -- svi key matrix
			if (ps2_chg /= keys(10)) then
                case ps2_scancode is
                    when SCANCODE_7         => svi_matrix(0)(7) <= ps2_press;
                    when SCANCODE_6         => svi_matrix(0)(6) <= ps2_press;
                    when SCANCODE_5		     => svi_matrix(0)(5) <= ps2_press;
                    when SCANCODE_4			  => svi_matrix(0)(4) <= ps2_press;
                    when SCANCODE_3         => svi_matrix(0)(3) <= ps2_press;
                    when SCANCODE_2         => svi_matrix(0)(2) <= ps2_press;
                    when SCANCODE_1         => svi_matrix(0)(1) <= ps2_press;
                    when SCANCODE_0         => svi_matrix(0)(0) <= ps2_press;

                    when SCANCODE_SLASH     => svi_matrix(1)(7) <= ps2_press;
                    when SCANCODE_PERIOD    => svi_matrix(1)(6) <= ps2_press;
                    when SCANCODE_EQUALS    => svi_matrix(1)(5) <= ps2_press;
                    when SCANCODE_COMMA	  => svi_matrix(1)(4) <= ps2_press;
                    when SCANCODE_QUOTE     => svi_matrix(1)(3) <= ps2_press;
                    when SCANCODE_SEMICOLON => svi_matrix(1)(2) <= ps2_press;
                    when SCANCODE_9         => svi_matrix(1)(1) <= ps2_press;
                    when SCANCODE_8         => svi_matrix(1)(0) <= ps2_press;


                    when SCANCODE_G         => svi_matrix(2)(7) <= ps2_press;
                    when SCANCODE_F			  => svi_matrix(2)(6) <= ps2_press;
                    when SCANCODE_E     	  => svi_matrix(2)(5) <= ps2_press;
                    when SCANCODE_D         => svi_matrix(2)(4) <= ps2_press;
                    when SCANCODE_C         => svi_matrix(2)(3) <= ps2_press;
                    when SCANCODE_B         => svi_matrix(2)(2) <= ps2_press;
                    when SCANCODE_A         => svi_matrix(2)(1) <= ps2_press;
                    when SCANCODE_MINUS     => svi_matrix(2)(0) <= ps2_press;


                    when SCANCODE_O			  => svi_matrix(3)(7) <= ps2_press;
						  when SCANCODE_N     	  => svi_matrix(3)(6) <= ps2_press;
                    when SCANCODE_M         => svi_matrix(3)(5) <= ps2_press;
						  when SCANCODE_L         => svi_matrix(3)(4) <= ps2_press;
                    when SCANCODE_K         => svi_matrix(3)(3) <= ps2_press;
                    when SCANCODE_J         => svi_matrix(3)(2) <= ps2_press;
                    when SCANCODE_I         => svi_matrix(3)(1) <= ps2_press;
                    when SCANCODE_H         => svi_matrix(3)(0) <= ps2_press;


                    when SCANCODE_W		     => svi_matrix(4)(7) <= ps2_press;
                    when SCANCODE_V 		  => svi_matrix(4)(6) <= ps2_press;
                    when SCANCODE_U      	  => svi_matrix(4)(5) <= ps2_press;
                    when SCANCODE_T      	  => svi_matrix(4)(4) <= ps2_press;						  
                    when SCANCODE_S         => svi_matrix(4)(3) <= ps2_press;
                    when SCANCODE_R         => svi_matrix(4)(2) <= ps2_press;
                    when SCANCODE_Q         => svi_matrix(4)(1) <= ps2_press;
                    when SCANCODE_P         => svi_matrix(4)(0) <= ps2_press;

                    when SCANCODE_UP        => svi_matrix(5)(7) <= ps2_press; 
                    when SCANCODE_BACKSPACE => svi_matrix(5)(6) <= ps2_press;
                    when SCANCODE_CLOSEBRKT => svi_matrix(5)(5) <= ps2_press;
                    when SCANCODE_BACKSLASH => svi_matrix(5)(4) <= ps2_press;
                    when SCANCODE_OPENBRKT  => svi_matrix(5)(3) <= ps2_press;
                    when SCANCODE_Z         => svi_matrix(5)(2) <= ps2_press;
                    when SCANCODE_Y         => svi_matrix(5)(1) <= ps2_press;
                    when SCANCODE_X         => svi_matrix(5)(0) <= ps2_press;

                    when SCANCODE_LEFT      => svi_matrix(6)(7) <= ps2_press; 
                    when SCANCODE_ENTER     => svi_matrix(6)(6) <= ps2_press; 
                    when SCANCODE_F8        => svi_matrix(6)(5) <= ps2_press; --Stop/Break
                    when SCANCODE_ESC       => svi_matrix(6)(4) <= ps2_press;
                    when SCANCODE_RGUI      => svi_matrix(6)(3) <= ps2_press; -- RGraph
                    when SCANCODE_LGUI      => svi_matrix(6)(2) <= ps2_press; -- LGraph
                    when SCANCODE_LCTRL     => svi_matrix(6)(1) <= ps2_press;
                    when SCANCODE_LSHIFT    => svi_matrix(6)(0) <= ps2_press;
						  when SCANCODE_RSHIFT    => svi_matrix(6)(0) <= ps2_press;

                    when SCANCODE_DOWN      => svi_matrix(7)(7) <= ps2_press; 
--                    when SCANCODE_UP        => svi_matrix(7)(6) <= ps2_press; -- CLS
                    when SCANCODE_INS       => svi_matrix(7)(5) <= ps2_press;
                    when SCANCODE_F5        => svi_matrix(7)(4) <= ps2_press;						  
                    when SCANCODE_F4        => svi_matrix(7)(3) <= ps2_press;
                    when SCANCODE_F3        => svi_matrix(7)(2) <= ps2_press;
                    when SCANCODE_F2        => svi_matrix(7)(1) <= ps2_press;
                    when SCANCODE_F1        => svi_matrix(7)(0) <= ps2_press;


                    when SCANCODE_RIGHT     => svi_matrix(8)(7) <= ps2_press;
--                    when SCANCODE_UP        => svi_matrix(8)(6) <= ps2_press;  -- NULL/VOID/VACIO/NADA
--                    when SCANCODE_RIGHT     => svi_matrix(8)(5) <= ps2_press;  -- PRINT
--                    when SCANCODE_M         => svi_matrix(8)(4) <= ps2_press;	-- SEL					  
                    when SCANCODE_CAPSLOCK  => svi_matrix(8)(3) <= ps2_press;
                    when SCANCODE_DELETE    => svi_matrix(8)(2) <= ps2_press;
                    when SCANCODE_TAB       => svi_matrix(8)(1) <= ps2_press;
                    when SCANCODE_SPACE     => svi_matrix(8)(0) <= ps2_press;

                    when SCANCODE_PAD7      => svi_matrix(9)(7) <= ps2_press;
--                    when SCANCODE_PAD6      => svi_matrix(9)(6) <= ps2_press; -- OVerlaps
                    when SCANCODE_PAD5      => svi_matrix(9)(5) <= ps2_press;
--                    when SCANCODE_PAD4      => svi_matrix(9)(4) <= ps2_press;	-- OVerlaps					  
                    when SCANCODE_PAD3      => svi_matrix(9)(3) <= ps2_press;
--                    when SCANCODE_PAD2      => svi_matrix(9)(2) <= ps2_press; -- OVerlaps
                    when SCANCODE_PAD1      => svi_matrix(9)(1) <= ps2_press;
--                    when SCANCODE_PAD0      => svi_matrix(9)(0) <= ps2_press; -- OVerlaps
						  
--TODO
--                    when SCANCODE_ESC       => svi_matrix(10)(7) <= ps2_press; -- NUM,
--                    when SCANCODE_UP        => svi_matrix(10)(6) <= ps2_press; -- NUM.
--                    when SCANCODE_RIGHT     => svi_matrix(10)(5) <= ps2_press; -- NUM/
                    when SCANCODE_PADTIMES  => svi_matrix(10)(4) <= ps2_press;						  
                    when SCANCODE_PADMINUS  => svi_matrix(10)(3) <= ps2_press;
                    when SCANCODE_PADPLUS   => svi_matrix(10)(2) <= ps2_press;
                    when SCANCODE_PAD9      => svi_matrix(10)(1) <= ps2_press;
--                    when SCANCODE_PAD8      => svi_matrix(10)(0) <= ps2_press; -- OVerlaps

						  
                    when others          => null;
                end case;
            end if;
        end if; -- rising_edge (clk)
    end process latchInputs;

  
end SYN;
