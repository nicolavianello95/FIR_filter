library ieee;
use ieee.std_logic_1164.all;
use work.fir_package.all;		-- used to define some signal type

-- FIR filter (direct structure) of order ten with a parallelism of 14 bits.

entity fir is
	port(
		DIN		: in std_logic_vector(13 downto 0);		-- input data
		VIN		: in std_logic;							-- validation signal, is 1 when it is received a valid data, 0 otherwise.
		RST_n	: in std_logic;							-- reset signal active low
		CLK		: in std_logic;							-- clock signal
		b		: in std_logic_vector(153 downto 0);							-- coefficent of the filter
		DOUT	: out std_logic_vector(13 downto 0);	-- output data
		VOUT	: out std_logic							-- validation signal, is 1 when it is generated a valid data, 0 otherwise.
	);
end entity fir;

architecture behavioral of fir is

	component reg is
		Generic (N: positive:= 1 );											--	number of bits
		Port(	D		: In	std_logic_vector(N-1 downto 0);				--	data input
				Q		: Out	std_logic_vector(N-1 downto 0);				--	data output
				EN		: In 	std_logic;									--	enable active high
				CLK		: In	std_logic;									--	clock
				RST_n	: In	std_logic									--	synchronous reset active low
		);		
	end component reg;		
			
	component Mult is 		
		generic (N:  integer := 8);											--	number of bits
		Port (	A:	IN	std_logic_vector(N-1 downto 0); 					--	data input 1
				B:	IN	std_logic_vector(N-1 downto 0);						--	data input 2
				M:	OUT	std_logic_vector(N downto 0)						--	multiplication's result
			);									
	end component Mult; 		
			
	component Adder is 		
		generic (N:  integer := 8);											--	number of bits
		Port (	A:	In	std_logic_vector(N-1 downto 0); 					--	data input 1
				B:	In	std_logic_vector(N-1 downto 0);						--	data input 2
				S:	Out	std_logic_vector(N-1 downto 0)						--	sum's result
			);							
	end component Adder; 

	component MUX_4to1 is
	Generic (N: integer:= 1);												--number of bits
	Port (	IN0, IN1, IN2, IN3	: In	std_logic_vector(N-1 downto 0);		--data inputs
			SEL					: In	std_logic_vector(1 downto 0);		--selection input
			Y					: Out	std_logic_vector(N-1 downto 0));	--data output
	end component MUX_4to1;

	signal connection_reg 	: wire_reg;								-- Used to connect the register in a sequence
	signal mult_to_add		: wire_mult_add;						-- Connect the outputs of the multipliers to the inputs of adders
	signal add_to_add		: wire_mult_add;						-- Connect the output of the previously adder, to one input of the following adder
	signal enable_reg		: std_logic;							-- Is used to propagate the VIN signal in the internal structure
	signal sel_signal		: std_logic_vector(1 downto 0); 		-- Used to control the SEL signal of the mux
	signal out_mux			: std_logic_vector(13 downto 0);		-- Used to connect the output of the saturation stage to the output register for dout
	
	BEGIN
		-- the first mult is place here to simplify the generation of the following stages
		mult0	: mult
		GENERIC MAP ( N => 14 )
		PORT MAP(A => connection_reg(0), B => b(13 downto 0), M => mult_to_add(0)) ;
		
		-- all the input signals pass through registers, so two registers are placed for the two input signals (DIN,VIN)
		reg_din	: reg
		GENERIC MAP ( N => 14 )
		PORT MAP(D => DIN, Q => connection_reg(0), EN => '1' , CLK => CLK, RST_n => RST_n ) ;
		
		reg_vin	: reg
		GENERIC MAP ( N => 1 )
		PORT MAP(D(0) => VIN, Q(0) => enable_reg, EN =>'1' , CLK => CLK, RST_n => RST_n ) ;
		
		--simple assigment, that connect the output of multiplier to one input of the adder present in the next branch
		add_to_add(0) <= mult_to_add(0);
		
		-- generate the structure of the filter: the register chain, 10 adders, and the remaining 10 multipliers
		network_generation: for x in 1 to 10 generate
			reg_chain	: reg
			GENERIC MAP ( N => 14 )
			PORT MAP(D => connection_reg(x-1), Q => connection_reg(x), EN => enable_reg , CLK => CLK, RST_n => RST_n ) ;
			
			queue_mult	: mult
			GENERIC MAP ( N => 14 )
			PORT MAP(A => connection_reg(x), B => b(13+(14*x) downto 14*x), M => mult_to_add(x)) ;
			
			queue_add	: Adder
			GENERIC MAP ( N => 15 )
			PORT MAP(A => add_to_add(x-1), B => mult_to_add(x), S => add_to_add(x) ) ;
		
		end generate network_generation;

		-- compose the sel signal to control the mux of the saturation stage 
		sel_signal <= ( add_to_add(10)(14) & add_to_add(10)(13));

		-- saturation stage, if the number is lower than -8192 or greater than 8191, the number is saturated at the minimum or maximum respectively
		saturation_stage: MUX_4to1 
			Generic map(N => 14)
			Port map (	IN0=> add_to_add(10)(13 downto 0), IN1=>"01111111111111",
						IN2=> "10000000000000", IN3=> add_to_add(10)(13 downto 0), 
						SEL => sel_signal ,Y => out_mux	);
		
		-- all the outputs pass through registers, so two registers are placed for the two output signals (DOUT,VOUT)
		reg_dout	: reg
		GENERIC MAP ( N => 14 )
		PORT MAP(D => out_mux, Q => DOUT, EN => enable_reg , CLK => CLK, RST_n => RST_n ) ;
		
		reg_vout	: reg
		GENERIC MAP ( N => 1 )
		PORT MAP(D(0) =>enable_reg, Q(0) => VOUT, EN => '1' , CLK => CLK, RST_n => RST_n ) ;
end architecture behavioral;