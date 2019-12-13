library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

-- Element used to perform addition between two signal 
entity adder is 
	generic (N:  integer := 8);							--number of bits
	Port (	A:	In	std_logic_vector(N-1 downto 0); 	--data input 1
			B:	In	std_logic_vector(N-1 downto 0);		--data input 2
			S:	Out	std_logic_vector(N-1 downto 0)		--sum's result
			);							
end adder; 

architecture BHV of adder is
	begin
		S<=A+B
end BHV;