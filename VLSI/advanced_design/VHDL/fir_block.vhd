library ieee;
use ieee.std_logic_1164.all;
use work.fir_adv_package.all; -- used to define some signal type

-- component in which the structure of the FIR filter is divide in pipeline stages.
entity fir_block is
	port(
		DATA_IN		: in mult_in;							-- inputs vectors 
		enable_line1: in std_logic;                     	-- enable signal for pipeline stage 1
		enable_line2: in std_logic;                     	-- enable signal for pipeline stage 2
		enable_line3: in std_logic;                     	-- enable signal for pipeline stage 3
		enable_line4: in std_logic;                     	-- enable signal for pipeline stage 4
		RST_n		: in std_logic;                     	-- reset signal
		CLK			: in std_logic;                     	-- clock signal
		B			: in std_logic_vector(153 downto 0);	-- coefficent
		DATA_OUT	: out std_logic_vector(13 downto 0) 	-- output data
	);
end entity fir_block;

architecture behavioral of fir_block is

	component reg is
		Generic (N: positive:= 1 );									--	number of bits
		Port(	D		: In	std_logic_vector(N-1 downto 0);		--	data input
				Q		: Out	std_logic_vector(N-1 downto 0);		--	data output
				EN		: In 	std_logic;							--	enable active high
				CLK		: In	std_logic;							--	clock
				RST_n	: In	std_logic							--	synchronous reset active low
		);
	end component reg;
	
	component Mult is 
		generic (N:  integer := 8);									--	number of bits
		Port (	A:	IN	std_logic_vector(N-1 downto 0); 			--	data input 1
				B:	IN	std_logic_vector(N-1 downto 0);				--	data input 2
				M:	OUT	std_logic_vector(N downto 0)				--	multiplication's result
			);							
	end component Mult; 
	
	component Adder is 
		generic (N:  integer := 8);									--	number of bits
		Port (	A:	In	std_logic_vector(N-1 downto 0); 			--	data input 1
				B:	In	std_logic_vector(N-1 downto 0);				--	data input 2
				S:	Out	std_logic_vector(N-1 downto 0)				--	sum's result
			);							
	end component Adder; 
	
	component MUX_4to1 is
	Generic (N: integer:= 1);	--number of bits
	Port (	IN0, IN1, IN2, IN3	: In	std_logic_vector(N-1 downto 0);		--data inputs
			SEL					: In	std_logic_vector(1 downto 0);		--selection input
			Y					: Out	std_logic_vector(N-1 downto 0));	--data output
	end component MUX_4to1;
	
	signal mult_to_reg		: wire_net;								-- connect the output of the multiplier to the input of one register
	signal reg_to_adder		: wire_net;                             -- connect the output of the register to the input of adder
	signal reg_to_reg_1		: wire_net;                             -- connect the output of the register to the input of other register
	signal reg_to_reg_2		: wire_net;                             -- connect the output of the register to the input of other register
	signal reg_to_reg_3		: std_logic_vector(14 downto 0);        -- connect the output of the register to the input of other register
	signal add_to_adder		: wire_adder;                           -- connect the output of the adder to the input of other adder
	signal sel_signal 		: std_logic_vector(1 downto 0);			-- used to control the SEL signal of the mux
	
	BEGIN
		-- place the eleven adder
		network_generation: for x in 0 to 10 generate			
			instance_mult	: mult
			GENERIC MAP ( N => 14 )
			PORT MAP(A => DATA_IN(x), B => B(13+(14*x) downto 14*x), M => mult_to_reg(x)) ;
		end generate network_generation;

		-- bank of register to implement pipelininig that divides adder in sequence of 3 max

		pipe_generation_1a: for x in 0 to 3 generate
			reg_pipe03	: reg
			GENERIC MAP ( N => 15 )
			PORT MAP(D => mult_to_reg(x), Q => reg_to_adder(x), EN => enable_line1 , CLK => CLK, RST_n => RST_n ) ;
		end generate pipe_generation_1a;

		pipe_generation_1b: for x in 4 to 10 generate
			reg_pipe410	: reg
			GENERIC MAP ( N => 15 )
			PORT MAP(D => mult_to_reg(x), Q => reg_to_reg_1(x), EN => enable_line1 , CLK => CLK, RST_n => RST_n ) ;
		end generate pipe_generation_1b;
		
		pipe_generation_2a: for x in 4 to 6 generate
			reg_pipe46	: reg
			GENERIC MAP ( N => 15 )
			PORT MAP(D => reg_to_reg_1(x), Q => reg_to_adder(x), EN => enable_line2 , CLK => CLK, RST_n => RST_n ) ;
		end generate pipe_generation_2a;

		pipe_generation_2b: for x in 7 to 10 generate
			reg_pipe710	: reg
			GENERIC MAP ( N => 15 )
			PORT MAP(D => reg_to_reg_1(x), Q => reg_to_reg_2(x), EN => enable_line2 , CLK => CLK, RST_n => RST_n ) ;
		end generate pipe_generation_2b;

		pipe_generation_3a: for x in 7 to 9 generate
			reg_pipe79	: reg
			GENERIC MAP ( N => 15 )
			PORT MAP(D => reg_to_reg_2(x), Q => reg_to_adder(x), EN => enable_line3 , CLK => CLK, RST_n => RST_n ) ;
		end generate pipe_generation_3a;

		reg_pipe10_1	: reg
			GENERIC MAP ( N => 15 )
			PORT MAP(D => reg_to_reg_2(10), Q => reg_to_reg_3, EN => enable_line3 , CLK => CLK, RST_n => RST_n ) ;

		reg_pipe10_2	: reg
			GENERIC MAP ( N => 15 )
			PORT MAP(D => reg_to_reg_3, Q => reg_to_adder(10), EN => enable_line4 , CLK => CLK, RST_n => RST_n ) ;

		-- simple assignement 
		add_to_adder(0) <= reg_to_adder(0);
		
		-- first three adder
		first_chain_adder: for x in 1 to 3 generate
			add_one_to_three	: Adder
			GENERIC MAP ( N => 15 )
			PORT MAP(A => add_to_adder(x-1), B => reg_to_adder(x), S => add_to_adder(x) ) ;
		end generate first_chain_adder;
		
		-- first register used to separate the chain of adder
		reg_between_1	: reg
			GENERIC MAP ( N => 15 )
			PORT MAP(D => add_to_adder(3), Q => add_to_adder(4), EN => enable_line2 , CLK => CLK, RST_n => RST_n ) ;
		
		-- second chain of three adder
		second_chain_adder: for x in 4 to 6 generate
			add_four_to_six	: Adder
			GENERIC MAP ( N => 15 )
			PORT MAP(A => add_to_adder(x), B => reg_to_adder(x), S => add_to_adder(x+1) ) ;
		end generate second_chain_adder;
		
		-- second register used to separate the chain of adder
		reg_between_2	: reg
			GENERIC MAP ( N => 15 )
			PORT MAP(D => add_to_adder(7), Q => add_to_adder(8), EN => enable_line3 , CLK => CLK, RST_n => RST_n ) ;
		
		-- third chain of three adder
		third_chain_adder: for x in 7 to 9 generate
			add_seven_to_nine	: Adder
			GENERIC MAP ( N => 15 )
			PORT MAP(A => add_to_adder(x+1), B => reg_to_adder(x), S => add_to_adder(x+2) ) ;
		end generate third_chain_adder;
		
		-- last register used to separate the chain of adder
		reg_between_3	: reg
			GENERIC MAP ( N => 15 )
			PORT MAP(D => add_to_adder(11), Q => add_to_adder(12), EN => enable_line4 , CLK => CLK, RST_n => RST_n ) ;			
		
		-- last adder 
		add_ten	: Adder
			GENERIC MAP ( N => 15 )
			PORT MAP(A => add_to_adder(12), B => reg_to_adder(10), S => add_to_adder(13) ) ;
		
		-- compose the sel signal to control the mux of the saturation stage 
		sel_signal <= (add_to_adder(13)(14) & add_to_adder(13)(13));
		 
		-- saturation stage, if the number is lower than -8192 or greater than 8191, the number is saturated at the minimum or maximum respectively
		saturation_stage: MUX_4to1 
			Generic map(N => 14)
			Port map (	IN0=> add_to_adder(13)(13 downto 0), IN1=>"01111111111111",
						IN2=> "10000000000000", IN3=> add_to_adder(13)(13 downto 0), 
						SEL => sel_signal ,Y =>DATA_OUT	);

end architecture behavioral;