library ieee;
use ieee.std_logic_1164.all;
use work.fir_adv_package.all; -- used to define some signal type

-- This component implement an advance version of FIR filter. It is applied first the unfolding method with p = 3,
-- and so there are obtain three input : 3k, 3k+1, 3k+2 associated respectively to input A, B and C (same for the output)
-- The three validation signal pass through an and gate, so, it is sufficent that only one goes to 0 that all the 
-- structure is blocked.

entity fir_adv is
	port(
		DIN_3A	: in std_logic_vector(13 downto 0);		-- input data A (3k)
		DIN_3B	: in std_logic_vector(13 downto 0);     -- input data B (3k+1)
		DIN_3C	: in std_logic_vector(13 downto 0);     -- input data C (3k+2)
		VIN		: in std_logic;                         -- validation signal for input
		RST_n	: in std_logic;                         -- reset signal, active low, synchronous
		CLK		: in std_logic;                         -- clock signal
		b		: in std_logic_vector(153 downto 0);     -- eleven coefficent for the filter
		DOUT_3A	: out std_logic_vector(13 downto 0);    -- output data A (3k)
		DOUT_3B	: out std_logic_vector(13 downto 0);    -- output data B (3k+1)
		DOUT_3C	: out std_logic_vector(13 downto 0);    -- output data C (3k+2)
		VOUT	: out std_logic                         -- validation signal for output
	);
end entity fir_adv;

architecture behavioral of fir_adv is

	component reg is
		Generic (N: positive:= 1 );									--	number of bits
		Port(	D		: In	std_logic_vector(N-1 downto 0);		--	data input
				Q		: Out	std_logic_vector(N-1 downto 0);		--	data output
				EN		: In 	std_logic;							--	enable active high
				CLK		: In	std_logic;							--	clock
				RST_n	: In	std_logic							--	synchronous reset active low
		);
	end component reg;

	component fir_block is
	port(
		DATA_IN		: in mult_in;						-- inputs vectors 
		enable_line1: in std_logic;                     -- enable signal for pipeline stage 1
		enable_line2: in std_logic;                     -- enable signal for pipeline stage 2
		enable_line3: in std_logic;                     -- enable signal for pipeline stage 3
		enable_line4: in std_logic;                     -- enable signal for pipeline stage 4
		RST_n		: in std_logic;                     -- reset signal
		CLK			: in std_logic;                     -- clock signal
		B			: in std_logic_vector(153 downto 0);                       -- coefficent
		DATA_OUT	: out std_logic_vector(13 downto 0) -- output data
	);
	end component fir_block;	
	
	-- In line_x are put in order the input for the fir_block. line_x(0) feed the first multiplier inside fir block, line_x(10) feed the last one.
	signal line_1		: mult_in;							
	signal line_2		: mult_in;                      	 
	signal line_3		: mult_in;
	
	-- are created three delay line in which the input is delayed several times
	-- for example: delay_A(2) stand for: input A pass through two register
	signal delay_A		: wire_delay;                   	    
	signal delay_B		: wire_delay;                   	    
	signal delay_C		: wire_delay; 
	
	-- delay line to proper manage the enable signal for the different pipeline stages
	signal delay_valid	: wire_valid_delay; 
	
	-- three signal used to connect the output of the fir_block to the output register for DOUT
	signal outA,outB,outC:std_logic_vector(13 downto 0);                  	    
	
	BEGIN

		-- input registers
		reg_in_A	: reg
		GENERIC MAP ( N => 14 )
		PORT MAP(D => DIN_3A, Q =>delay_A(0) , EN => '1' , CLK => CLK, RST_n => RST_n ) ;

		reg_in_B	: reg
		GENERIC MAP ( N => 14 )
		PORT MAP(D => DIN_3B, Q =>delay_B(0) , EN => '1' , CLK => CLK, RST_n => RST_n ) ;
		
		reg_in_C	: reg
		GENERIC MAP ( N => 14 )
		PORT MAP(D => DIN_3C, Q =>delay_C(0) , EN => '1' , CLK => CLK, RST_n => RST_n ) ;
		
		reg_in_VIN	: reg
		GENERIC MAP ( N => 1 )
		PORT MAP(D(0) => VIN, Q(0) =>delay_valid(0) , EN => '1' , CLK => CLK, RST_n => RST_n ) ;
		
		--delay the validation signal with 4 registers
		sequence_reg_vin: for x in 0 to 3 generate			
			reg_d_vin	: reg
			GENERIC MAP ( N => 1 )
			PORT MAP(D(0) => delay_valid(x), Q(0) => delay_valid(x+1), EN => '1' , CLK => CLK, RST_n => RST_n ) ;
		end generate sequence_reg_vin;
		
		--delay the input 3k with a maximum sequence of 3 regs
		sequence_reg_A: for x in 0 to 2 generate			
			reg_d_A	: reg
			GENERIC MAP ( N => 14 )
			PORT MAP(D => delay_A(x), Q => delay_A(x+1), EN => delay_valid(0) , CLK => CLK, RST_n => RST_n ) ;
		end generate sequence_reg_A;
		
		--delay the input 3k+1 with a maximum sequence of 3 regs
		sequence_reg_B: for x in 0 to 2 generate			
			reg_d_B	: reg
			GENERIC MAP ( N => 14 )
			PORT MAP(D => delay_B(x), Q => delay_B(x+1), EN => delay_valid(0) , CLK => CLK, RST_n => RST_n ) ;
		end generate sequence_reg_B;

		--delay the input 3k+2 with a maximum sequence of 3 regs
		sequence_reg_C: for x in 0 to 3 generate			
			reg_d_C	: reg
			GENERIC MAP ( N => 14 )
			PORT MAP(D => delay_C(x), Q => delay_C(x+1), EN => delay_valid(0) , CLK => CLK, RST_n => RST_n ) ;
		end generate sequence_reg_C;
		
		-- compose line to assign easly to the fir block. See the comment on the declaration of signal delay_x to know how works			
			line_1(0)	<= delay_A(0);
			line_1(1)	<= delay_C(1);
			line_1(2)	<= delay_B(1);
			line_1(3)	<= delay_A(1);
			line_1(4)	<= delay_C(2);
			line_1(5)	<= delay_B(2);
			line_1(6)	<= delay_A(2);
			line_1(7)	<= delay_C(3);
			line_1(8)	<= delay_B(3);
			line_1(9)	<= delay_A(3);
			line_1(10) 	<= delay_C(4);
			
			
			line_2(0)	<= delay_B(0);
			line_2(1)	<= delay_A(0);
			line_2(2)	<= delay_C(1);
			line_2(3)	<= delay_B(1);
			line_2(4)	<= delay_A(1);
			line_2(5)	<= delay_C(2);
			line_2(6)	<= delay_B(2);
			line_2(7)	<= delay_A(2);
			line_2(8)	<= delay_C(3);
			line_2(9)	<= delay_B(3);
			line_2(10) 	<= delay_A(3);
		
			line_3(0)	<= delay_C(0);
			line_3(1)	<= delay_B(0);
			line_3(2)	<= delay_A(0);
			line_3(3)	<= delay_C(1);
			line_3(4)	<= delay_B(1);
			line_3(5)	<= delay_A(1);
			line_3(6)	<= delay_C(2);
			line_3(7)	<= delay_B(2);
			line_3(8)	<= delay_A(2);
			line_3(9)	<= delay_C(3);
			line_3(10) 	<= delay_B(3);		
			
		-- generate the three block for the advance filter		
		BLOCK_A_FIR:fir_block
		PORT MAP(DATA_IN =>	line_1 , RST_n => RST_n ,CLK => CLK, B =>b ,DATA_OUT => outA,
				enable_line1 =>delay_valid(0), enable_line2 => delay_valid(1), 
				enable_line3 => delay_valid(2), enable_line4 => delay_valid(3));
																										  
		BLOCK_B_FIR:fir_block                                                                             
		PORT MAP(DATA_IN =>	line_2 , RST_n => RST_n ,CLK => CLK, B =>b ,DATA_OUT => outB,
				enable_line1 => delay_valid(0), enable_line2 => delay_valid(1), 
				enable_line3 => delay_valid(2), enable_line4 => delay_valid(3));
				
		BLOCK_C_FIR:fir_block                                                                             
		PORT MAP(DATA_IN =>	line_3 , RST_n => RST_n ,CLK => CLK, B =>b ,DATA_OUT => outC,
				enable_line1 => delay_valid(0), enable_line2 => delay_valid(1), 
				enable_line3 => delay_valid(2), enable_line4 => delay_valid(3));
		
		-- output register
		reg_out_A	: reg
		GENERIC MAP ( N => 14 )
		PORT MAP(D => outA, Q =>DOUT_3A , EN => '1' , CLK => CLK, RST_n => RST_n ) ;

		reg_out_B	: reg
		GENERIC MAP ( N => 14 )
		PORT MAP(D => outB, Q =>DOUT_3B , EN => '1' , CLK => CLK, RST_n => RST_n ) ;
		
		reg_out_C	: reg
		GENERIC MAP ( N => 14 )
		PORT MAP(D => outC, Q =>DOUT_3C , EN => '1' , CLK => CLK, RST_n => RST_n ) ;
		
		reg_out_VOUT	: reg
		GENERIC MAP ( N => 1 )
		PORT MAP(D(0) => delay_valid(4), Q(0) =>VOUT , EN => '1' , CLK => CLK, RST_n => RST_n ) ;
		
		-- simple assignement
		
		
end architecture behavioral;
