library ieee;
use ieee.std_logic_1164.all;

-- used to define some signal type
package fir_package is
	
	type wire_reg is array (10 downto 0) of std_logic_vector(13 downto 0);			-- signal used to manage the connection between register
	type wire_mult_add is array (10 downto 0) of std_logic_vector(14 downto 0);		-- signal used to manage the connection between arithmetic part
end package fir_package ;
