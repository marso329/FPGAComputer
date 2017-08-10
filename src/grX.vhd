library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity grX is
	port (clk		: in std_logic;
		rst			: in std_logic;
		select_reg	: in std_logic_vector(1 downto 0);
		reg_write	: in std_logic;
		reg_read	: in std_logic;
		bus_in		: in std_logic_vector(15 downto 0);
		bus_out		: out std_logic_vector(15 downto 0)
	);
end grX;

architecture Behavioral of grX is

	type grX is array(0 to 3) of std_logic_vector(15 downto 0);
	signal registers : grX:= (others => (others => '0'));
	
	--Controls input and output on GRx.
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if rst='0' then
				registers<=(others => (others => '0'));
				bus_out<=x"0000";
			else
				if reg_read='0' then
					registers(conv_integer(select_reg)) <= bus_in;
				end if;
				if reg_write='0' then
					bus_out <= registers(conv_integer(select_reg));
				end if;
			end if;	
		end if;
	end process;
end Behavioral;

 
