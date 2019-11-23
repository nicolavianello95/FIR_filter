library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

-- component used to write the results. It write only when the validation signal is equal to 1 for all the three signal(A,B,C)

entity data_sink_adv is
  port (
    CLK   	: in std_logic;							-- clock signal
    RST_n 	: in std_logic;                         -- reset signal, active low, asynchronous
    VIN		: in std_logic;                         -- validation signal for input A
    DIN_A   : in std_logic_vector(13 downto 0);     -- input data A (3k)
	DIN_B   : in std_logic_vector(13 downto 0);     -- input data B (3k+1)
	DIN_C   : in std_logic_vector(13 downto 0));    -- input data C (3k+2)
end data_sink_adv;

architecture beh of data_sink_adv is

begin  -- beh

	-- write the result in the file result; if it is not present in the folder of the project, it creates one and write it
	process (CLK, RST_n)
		file res_fp : text open WRITE_MODE is "./results.txt";
		variable line_out : line;    
	begin 
		if RST_n = '0' then                 -- asynchronous reset (active low)
			null;
		elsif rising_edge(CLK) then  		-- rising clock edge
			if (VIN = '1') then
				write(line_out, conv_integer(signed(DIN_A)));
				writeline(res_fp, line_out);
				write(line_out, conv_integer(signed(DIN_B)));
				writeline(res_fp, line_out);
				write(line_out, conv_integer(signed(DIN_C)));
				writeline(res_fp, line_out);
			end if;
		end if;
	end process;

end beh;
