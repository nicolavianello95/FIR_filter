library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

-- Element used to perform addition between two signal 
entity Adder is 
	generic (N:  integer := 8);							--number of bits
	Port (	A:	In	std_logic_vector(N-1 downto 0); 	--data input 1
			B:	In	std_logic_vector(N-1 downto 0);		--data input 2
			S:	Out	std_logic_vector(N-1 downto 0)		--sum's result
			);							
end Adder; 

architecture BHV of Adder is
	signal y	:	std_logic_vector(N downto 0);
	signal a_i	:	std_logic_vector(N downto 0);
	signal b_i	:	std_logic_vector(N downto 0);
	
 begin

	a_i <= A(N-1) & A;			 -- extend signal A
	b_i <= B(N-1) & B;           -- extend signal B
	y <= a_i + b_i;              -- sum
	S <= y(N-1 downto 0);        -- cut the signal to obtain one with the same number of bits of the input signals

end BHV;