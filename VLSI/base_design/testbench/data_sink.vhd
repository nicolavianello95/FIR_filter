library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity data_sink is
  port (
    CLK   : in std_logic;							-- clock signal
    RST_n : in std_logic;                           -- asynchronous reset (active low)
    VIN   : in std_logic;                           -- validation signal
    DIN   : in std_logic_vector(13 downto 0));      -- data input provide by the filter
end data_sink;

architecture beh of data_sink is

begin

	process (CLK, RST_n)
		file res_fp : text open WRITE_MODE is "./results.txt";
		variable line_out : line;    
	begin  
		if RST_n = '0' then                 			
			null;
		elsif rising_edge(CLK) then  					-- rising clock edge, if vin=1 write on file, otherwise do nothing
			if (VIN = '1') then
				write(line_out, conv_integer(signed(DIN)));
				writeline(res_fp, line_out);
			end if;
		end if;
	end process;

end beh;
