library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;


entity alu is
port (	clk: 		in std_logic;
		rst: 		in std_logic;
		bus_in: 	in std_logic_vector(15 downto 0);
		bus_out: 	out std_logic_vector(15 downto 0);
		alu_write: 	in std_logic;
		alu_control:in std_logic_vector(3 downto 0);
		Z : 		out std_logic;
		N : 		out std_logic;
		O : 		out std_logic;
		C : 		out std_logic
		);
end alu;

architecture Behavioral of alu is
	signal temp	: std_logic		:= '0';
	signal AR 	: std_logic_vector(15 downto 0):=x"0000";
	begin
	
	--output to bus
	process(clk)
	begin
		if (rising_edge(clk)) then
			if rst='0' then
				bus_out<=x"0000";
			else
				if alu_write='0' then
					bus_out<=AR;
				end if;
			end if;
		end if;
	end process;
	
	--calculates expressions
	process(clk)
	begin
		if (rising_edge(clk)) then
			if rst='0' then
				AR<=x"0000";
				Z<='0';
				N<='0';
				O<='0';
				C<='0';
			else
				case alu_control is 
					when "0001"=>
						AR<=bus_in;
					when "0010"=>
						AR<= not bus_in;
					when "0011"=>
						AR<=x"0000";
					when "0100"=>
						if AR(15)='1' and bus_in(15)='1' then
							O<='1';
							C<='1';
						else
							O<='0';
							C<='0';
						end if;
						AR<= std_logic_vector(unsigned(AR) + unsigned(bus_in));
						if AR=x"0000" and bus_in=x"0000" then
							Z<='1';
						else 
							Z<='0';
						end if;
					when "0101" =>
						if unsigned(AR) < unsigned(bus_in) then 
							N<='1';
						else
							N<='0';
						end if;
						AR<= std_logic_vector( unsigned(bus_in)-unsigned(AR) );
						if AR=bus_in then
							Z<='1';
						else 
							Z<='0';
						end if;
					when "0110"=>
						AR<= AR and bus_in;
						if  x"0000"=(AR and bus_in) then
							Z<='1';
						else 
							Z<='0';
						end if;
					when "0111"=>
						AR<=AR or bus_in;
					when "1000"=>
						AR(15 downto  to_integer(unsigned(bus_in)))<=AR(15- to_integer(unsigned(bus_in)) downto 0);
						--AR(to_integer(unsigned(bus_in)))<='0';
						for i in 0 to 15 loop	
							AR(i) <= '0';
							if(i=to_integer(unsigned(bus_in)-1)) then
								exit;
							end if;
						end loop;
						--C<=AR(0);
						--AR(0)<='0';
						if AR=x"0000"then
							Z<='1';
						else 
							Z<='0';
							end if;
					when "1001"=>
						AR(15 downto 1)<=AR(14 downto 0);
						C<=AR(0);
						AR(0)<='0';
						if AR=x"0000"then
							Z<='1';
						else 
							Z<='0';
						end if;
					when "1010"=>
						AR<= bus_in(15 downto 8) & AR(7 downto 0);
					when "1011"=>
						AR(14 downto 0)<=AR(15 downto 1);
						C<=AR(15);
						AR(15)<='0';
						if AR=x"0000"then
							Z<='1';
						else 
							Z<='0';
						end if;
					when "1100"=>
						null;
					when "1101"=>
						null;
					when "1110"=>
						temp<=AR(15);
						AR(15 downto 1)<=AR(14 downto 0);
						AR(0)<=temp;
						if AR=x"0000"then
							Z<='1';
						else 
							Z<='0';
						end if;
					when others=> null;
				end case;
			end if;
		end if;
	end process;
end Behavioral;
