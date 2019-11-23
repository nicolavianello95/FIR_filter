library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;

-- This component is used to simulate the filter. It pass at every clock cycle three data to the filter and provide the coefficent
-- used by the filter ( in this case the order of the filter is ten, so 11 coefficent are passed). 
entity data_maker_adv is  
  port (
    CLK     : in  std_logic;						-- clock signal
    RST_n   : in  std_logic;                        -- reset signal
    VOUT	: out std_logic;                        -- validation signal for input 
    DOUT_A  : out std_logic_vector(13 downto 0);    -- data generate for input A
    DOUT_B  : out std_logic_vector(13 downto 0);    -- data generate for input B
    DOUT_C  : out std_logic_vector(13 downto 0);    -- data generate for input C
	B		: out std_logic_vector(153 downto 0);   -- coefficent generate
    END_SIM : out std_logic);						-- signal used to notify the end of the simulation
end data_maker_adv;

architecture beh of data_maker_adv is

	constant tco : time := 0.5 ns;					-- time between clock edge and signal change
	constant N	 : integer:= 14;                 -- filter has a parallelism of 14 bits
	
	signal sEndSim : std_logic;
	signal END_SIM_i : std_logic_vector(0 to 10);  
	signal not_valid: std_logic;					--if it is = 1, all goes in normal way, if it is 0, the valid signal is put to 0
begin  -- beh

	-- assign the value to the coefficients
	B( 13 downto 0)<= std_logic_vector(to_signed(-1, N));
	B( 27 downto 14)<= std_logic_vector(to_signed(-104, N));
	B( 41 downto 28)<= std_logic_vector(to_signed(-203, N));
	B( 55 downto 42)<= std_logic_vector(to_signed(520, N));
	B( 69 downto 56)<= std_logic_vector(to_signed(2251, N));
	B( 83 downto 70)<= std_logic_vector(to_signed(3260, N));
	B( 97 downto 84)<= std_logic_vector(to_signed(2251, N));
	B( 111 downto 98)<= std_logic_vector(to_signed(520, N));
	B( 125 downto 112)<= std_logic_vector(to_signed(-203, N));
	B( 139 downto 126)<= std_logic_vector(to_signed(-104, N));	
	B( 153 downto 140)<= std_logic_vector(to_signed(-1, N));


	-- this process manage the data generation and control the valid signal
	process (CLK, RST_n)
		file fp_in : text open READ_MODE is "samples.txt";			-- put "samples_sat.txt" if you want test the saturation stage
		variable line_in : line;
		variable x,y,z : integer;
		variable cc: integer:=0;
		begin  -- process
			if RST_n = '0' then                 					-- asynchronous reset (active low)
				VOUT <= '0' after tco;
				DOUT_A <= (others => '0') after tco;      
				DOUT_B <= (others => '0') after tco;      
				DOUT_C <= (others => '0') after tco;      
				sEndSim <= '0' after tco;
				not_valid <= '1' after tco;
			elsif rising_edge(CLK) then  -- rising clock edge
				
				------------- TEST VALIDATION SIGNAL -------------
				cc := cc+1;						-- count the  number of clock cycle
				if (cc = 25) then	
					not_valid <= '0';			-- when arrive at 25, it put the validation signal to 0
				end if;				
				if (cc = 30) then				-- after 5 clock cycle, it stars at the same point in which it is stopped
					not_valid <= '1';
				end if;
				---------------------------------------------------

				if not_valid = '1' then 
					
					if not endfile(fp_in) then
						readline(fp_in, line_in);
						read(line_in, x);
						DOUT_A <=  conv_std_logic_vector(x, N) after tco;
						VOUT <= '1' after tco;
						sEndSim <= '0' after tco;
					else
						VOUT <= '0' after tco;       
						sEndSim <= '1' after tco;
					end if;
					
					if not endfile(fp_in) then
						readline(fp_in, line_in);
						read(line_in, y);
						DOUT_B <=  conv_std_logic_vector(y, N) after tco;
						VOUT <= '1' after tco;
						sEndSim <= '0' after tco;
					else
						VOUT <= '0' after tco;        
						sEndSim <= '1' after tco;
					end if;
					
					if not endfile(fp_in) then
						readline(fp_in, line_in);
						read(line_in, z);
						DOUT_C <=  conv_std_logic_vector(z, N) after tco;
						VOUT <= '1' after tco;
						sEndSim <= '0' after tco;
					else    
						VOUT <= '0' after tco;     
						sEndSim <= '1' after tco;
					end if;	
				else 
					VOUT <= '0' after tco;
				end if;
			end if;
		end process;
	
	-- process used to stopped the computation after 10 clock cycle from the last read data
	process (CLK, RST_n)
		begin  -- process
			if RST_n = '0' then                 -- asynchronous reset (active low)
				END_SIM_i <= (others => '0') after tco;
			elsif rising_edge(CLK) then  -- rising clock edge
				END_SIM_i(0) <= sEndSim after tco;
				END_SIM_i(1 to 10) <= END_SIM_i(0 to 9) after tco;
			end if;
	end process;
	
	END_SIM <= END_SIM_i(10);  

	
end beh;
