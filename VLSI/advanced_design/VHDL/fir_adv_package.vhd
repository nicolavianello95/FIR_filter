library ieee;
use ieee.std_logic_1164.all;

package fir_adv_package is

	type mult_in is array (10 downto 0) of std_logic_vector(13 downto 0);			-- used to put all the signal used as input by the multiplier
	type wire_net is array (10 downto 0) of std_logic_vector (14 downto 0);
	type wire_adder is array (13 downto 0) of std_logic_vector(14 downto 0);		-- used to connect data along the adder

	type wire_delay is array (4 downto 0) of std_logic_vector(13 downto 0);			-- used to collect the data delayed 
	type wire_valid_delay is array (4 downto 0) of std_logic;						-- used to collect all the validation signal delayed
	
end package fir_adv_package ;
