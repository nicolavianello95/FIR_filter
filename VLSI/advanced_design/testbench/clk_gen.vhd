library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- used to generate the clock and reset signal 
entity clk_gen is
  port (
    END_SIM : in  std_logic;
    CLK     : out std_logic;
    RST_n   : out std_logic);
end clk_gen;

architecture beh of clk_gen is

	constant Ts : time := 7.8 ns;		-- set the period of the clock signal
	
	signal CLK_i : std_logic;
  
begin  -- beh

	process
	begin  -- process
		if (CLK_i = 'U') then
			CLK_i <= '0';
		else
			CLK_i <= not(CLK_i);
		end if;
		wait for Ts/2;
	end process;
	
	CLK <= CLK_i and not(END_SIM);
	
	process
	begin  -- process
		RST_n <= '0';
		wait for 3*Ts;
		RST_n <= '1';
		wait;
	end process;

end beh;
