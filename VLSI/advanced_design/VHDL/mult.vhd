library ieee; 
use ieee.std_logic_1164.all; 
use IEEE.std_logic_signed.all;
use ieee.numeric_std.all;

-- element used to perform multiplication between two input signal
entity Mult is 
	generic (N:  integer := 8);							--	number of bits
	Port (	A:	IN	std_logic_vector(N-1 downto 0); 	--	data input 1
			B:	IN	std_logic_vector(N-1 downto 0);		--	data input 2
			M:	OUT	std_logic_vector(N downto 0)		--	multiplication's result
			);							
end Mult; 

architecture BHV of Mult is

signal y	:	std_logic_vector(2*N-1 downto 0);

begin

	y 	<= 	A*B;					--perform multiplication
	M 	<= 	y(2*N-1 downto N-1);	-- take only the most significant part to obtain a result on N+1 bit

end BHV;