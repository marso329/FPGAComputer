library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity gm is
	port (clk			: in std_logic;
		rst				: in std_logic;
		gm_read 		: in std_logic;
		adress_gm		: in std_logic_vector(7 downto 0);
		adress_gpu		: in std_logic_vector(7 downto 0);
		bus_in			: in std_logic_vector(15 downto 0);
		bus_out_gpu		: out std_logic_vector(15 downto 0)
);
end gm;

architecture Behavioral of gm is

	type ram_t is array (0 to 255) of
		std_logic_vector(15 downto 0);
	
	-- set gm to zero
	signal ram : ram_t := ( 
		x"0000",
		others => (others => '0'));
	
	--used to store the xpos from storev instruction
	signal x_pos :unsigned(5 downto 0):="000000";
	signal y_pos :unsigned(5 downto 0):="000000";
	signal color:std_logic:='0';
	
	signal counter:std_logic_vector(1 downto 0):="00";
	signal bit_adress	: natural:=0;
	signal adress:natural:=0;
	signal temp_memory:std_logic_vector(15 downto 0):=x"0000";
	signal reset_counter:std_logic_vector(7 downto 0):=x"00";
	
begin

	--send data to gpu
	process(clk)
	begin 
		if (rising_edge(clk)) then
			bus_out_gpu <= ram(to_integer(unsigned(adress_gpu)));
		end if;
	end process;
	
	--handles writing to gm
	process(clk)
	begin
		if (rising_edge(clk)) then
			if rst='0'then
				x_pos<="000000";
				y_pos<="000000";
				color<='0';
				counter<="00";
				ram(to_integer(unsigned(reset_counter)))<=x"0000";
				reset_counter<=reset_counter+ '1';
				if (reset_counter=x"ff") then
					reset_counter<=x"00";
				end if;
			else
				reset_counter<=x"00";
				if (counter="01") then
					adress<=to_integer((x_pos+y_pos*to_unsigned(64,7))/16+1);
					bit_adress<=to_integer((x_pos+y_pos*to_unsigned(64,7)) mod 16);
					counter<="10";
				end if;
				if(counter="10") then
					temp_memory<=ram(adress);
					temp_memory(bit_adress)<=color;
					counter<="11";
				end if;
				if (counter="11") then 
					ram(adress)<=temp_memory;
				end if;
				if (gm_read = '0') then
					x_pos<=unsigned(bus_in(6 downto 1));
					color<=bus_in(0);
					y_pos<=unsigned(bus_in(12 downto 7))+1;
					counter<="01";
	    		end if;
			end if;
		end if;
	end process;
end Behavioral;
