library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity gpu is
	port (clk			: in std_logic;
		bus_in_gpu		: in std_logic_vector(15 downto 0);
		rst				: in std_logic;
		asr_gm			: out std_logic_vector(7 downto 0);
		vgaRed, vgaGreen: out std_logic_vector(2 downto 0);
		vgaBlue			: out std_logic_vector(2 downto 1);
		Hsync, Vsync	: out std_logic
	);
end gpu;


architecture behavioral of gpu is
	
	signal Xpixel				: unsigned(9 downto 0):= "0000000000";	--pixel counter
	signal Ypixel				: unsigned(9 downto 0):= "0000000000";	--pixel counter
	signal ClkDiv				: unsigned(1 downto 0):="00";			--divisor, generates 25MHz signal
	signal Clk25				: std_logic:='0'; 						--one pulse width 25 MHz signal
	signal Blank				: std_logic:='0';						--blanking signal
	signal pixel_data			: std_logic:='0';						--data used to write to VGA output
	signal adress_pixel			: std_logic_vector(7 downto 0):= x"00";
	signal temp_adress_pixel	: std_logic_vector(19 downto 0):="00000000000000000000";
	signal temp_bit_adress		: std_logic_vector(19 downto 0):="00000000000000000000";
	signal bit_adress			: std_logic_vector(3 downto 0):="0000";
	signal Xpixel_div,Ypixel_div: unsigned(9 downto 0):="0000000000";


	function  divide  (a : UNSIGNED; b : UNSIGNED) return UNSIGNED is
		variable a1 : unsigned(a'length-1 downto 0):=a;
		variable b1 : unsigned(b'length-1 downto 0):=b;
		variable p1 : unsigned(b'length downto 0):= (others => '0');
		variable i : integer:=0;

	begin
		for i in 0 to b'length-1 loop
			p1(b'length-1 downto 1) := p1(b'length-2 downto 0);
			p1(0) := a1(a'length-1);
			a1(a'length-1 downto 1) := a1(a'length-2 downto 0);
			p1 := p1-b1;
			if(p1(b'length-1) ='1') then
				a1(0) :='0';
				p1 := p1+b1;
			else
				a1(0) :='1';
			end if;
		end loop;
		return a1;
	end divide;


begin

	-- Clock divisor
	-- Divide system clock (100 MHz) by 4
	process(clk)
	begin
		if rising_edge(clk) then
			ClkDiv <= ClkDiv + 1;
		end if;
	end process;


	-- 25 MHz clock (one system clock pulse width)
	Clk25 <= '1' when (ClkDiv = 3) else '0';

	-- Horizontal pixel counter
	process(clk)
	begin
		if rising_edge(clk) then 
			if Clk25='1' then
				if rst='0' then
					Xpixel<="0000000000";
				else
					if Xpixel>=799 then
						Xpixel<="0000000000";
					else
						Xpixel<=Xpixel+1;
					end if;
				end if;
			end if;    
		end if;
	end process;

	-- Vertical pixel counter
	process(clk)
	begin
		if rising_edge(clk) then 
			if Clk25='1' then
				if rst='0' then
					Ypixel<="0000000000";
				else
					if Xpixel>=799 then
						if Ypixel>=520 then
							Ypixel<="0000000000";
						else
							Ypixel<=Ypixel+1;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	-- Horizontal sync
	process(clk)
	begin
		if rising_edge(clk) then 
			if Clk25='1' then
				if rst='0' then
					Hsync<='1';
				else
					if (655<=Xpixel) and (Xpixel<750) then
						Hsync<='0';
					else
						Hsync<='1';
					end if;
				end if;
			end if;
		end if;
	end process;


	-- Vertical sync
	process(clk)
	begin
		if rising_edge(clk) then 
			if Clk25='1' then
				if rst='0' then
					Vsync<='1';
				else
					if (489<=Ypixel) and (Ypixel<491) then
						Vsync<='0';
					else
						Vsync<='1';
					end if;
				end if;
			end if;
		end if;
	end process;


	-- Video blanking signal
	process(clk)
	begin
		if rising_edge(clk) then 
			if Clk25='1' then
				if rst='0' then
					Blank<='0';
			    else
					if (479<=Ypixel) or (Xpixel>=639) then
						Blank<='1';
					else
						Blank<='0';
					end if;
				end if;
			end if;
		end if;
	end process;
	

	-- Write to vga
	process(clk)
	begin
		if rising_edge(clk) then
			if blank='0' then
				pixel_data <= bus_in_gpu(to_integer(unsigned(bit_adress)));
			else
				pixel_data <= '0';
			end if;	
		end if;	
	end process;

  
	Xpixel_div<=divide(unsigned(Xpixel),to_unsigned(10,10));
	Ypixel_div<=divide(unsigned(Ypixel),to_unsigned(10,10));
	temp_adress_pixel<=std_logic_vector((Xpixel_div+Ypixel_div*64)/16);
	adress_pixel<=temp_adress_pixel(7 downto 0);
	asr_gm<=adress_pixel+'1';
	
	temp_bit_adress<=std_logic_vector((Xpixel_div+Ypixel_div*64) mod 16);
	bit_adress<=temp_bit_adress(3 downto 0);



	vgaRed(2)	<= pixel_data;
	vgaRed(1)	<= pixel_data;
	vgaRed(0)	<= pixel_data;
	vgaGreen(2)	<= pixel_data;
	vgaGreen(1)	<= pixel_data;
	vgaGreen(0)	<= pixel_data;
	vgaBlue(2)	<= pixel_data;
	vgaBlue(1)	<= pixel_data;
	
end behavioral;

