--------------------------------------------------------------------------------
-- VGA MOTOR
-- Anders Nilsson
-- 16-feb-2016
-- Version 1.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity graphic_controller is
	port ( clk		: in std_logic;
		data		: in std_logic_vector(15 downto 0);
		addr		: out unsigned(10 downto 0);
		rst			: in std_logic;
		vgaRed		: out std_logic_vector(2 downto 0);
		vgaGreen	: out std_logic_vector(2 downto 0);
		vgaBlue		: out std_logic_vector(2 downto 1);
		Hsync		: out std_logic;
		Vsync		: out std_logic);
end graphic_controller;


-- architecture
architecture Behavioral of graphic_controller is
	
	signal Xpixel		: unsigned(9 downto 0):="0000000000";	-- Horizontal	pixel counter 0-640
	signal Ypixel		: unsigned(9 downto 0):="0000000000";	-- Vertical		pixel counter 0-480
	signal ClkDiv		: unsigned(1 downto 0);					-- Clock divisor, to generate 25 MHz signal
	signal Clk25		: std_logic;							-- One pulse width 25 MHz signal
		
	signal tilePixel	: std_logic_vector(7 downto 0);			-- Tile pixel data
	signal tileAddr		: unsigned(10 downto 0);				-- Tile address
	
	signal blank		: std_logic;                    		-- blanking signal
	
	
	type ram_t is array (0 to 255) of std_logic_vector(15 downto 0);
	
	signal tileMem : ram_t := (
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",		-- ball
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",		-- player x3
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF"
		
	
	);
	
		  
begin

	-- Clock divisor
	-- Divide system clock (100 MHz) by 4
	process(clk)
	begin
		if rising_edge(clk) then
			if rst='1' then
				ClkDiv <= (others => '0');
			else
				ClkDiv <= ClkDiv + 1;
			end if;
		end if;
	end process;
		
	-- 25 MHz clock (one system clock pulse width)
	Clk25 <= '1' when (ClkDiv = 3) else '0';
	
	
	-- Horizontal pixel counter
	
	-- ***********************************
	-- *                                 *
	-- *  VHDL for :                     *
	-- *  Xpixel                         *
	-- *                                 *
	-- ***********************************
	process(clk)
	begin
		if rising_edge(clk) then 
			if Clk25='1' then
				if rst='1' then
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

  
	-- Horizontal sync
	
	-- ***********************************
	-- *                                 *
	-- *  VHDL for :                     *
	-- *  Hsync                          *
	-- *                                 *
	-- ***********************************
	process(clk)
	begin
		if rising_edge(clk) then 
			if Clk25='1' then
				if rst='1' then
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
  

	
	-- Vertical pixel counter
	
	-- ***********************************
	-- *                                 *
	-- *  VHDL for :                     *
	-- *  Ypixel                         *
	-- *                                 *
	-- ***********************************
	
	process(clk)
	begin
		if rising_edge(clk) then 
			if Clk25='1' then
				if rst='1' then
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

	-- Vertical sync
	
	-- ***********************************
	-- *                                 *
	-- *  VHDL for :                     *
	-- *  Vsync                          *
	-- *                                 *
	-- ***********************************
	process(clk)
	begin
		if rising_edge(clk) then 
			if Clk25='1' then
				if rst='1' then
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
	
	-- ***********************************
	-- *                                 *
	-- *  VHDL for :                     *
	-- *  Blank                          *
	-- *                                 *
	-- ***********************************
	process(clk)
	begin
		if rising_edge(clk) then 
			if Clk25='1' then
			    if rst='1' then
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
	
	
	
	-- Tile memory
	process(clk)
	begin
		if rising_edge(clk) then
			if (blank = '0') then
				
				-- tilePixel <= tileMem(to_integer(tileAddr));
			else
				tilePixel <= (others => '0');
			end if;
		end if;
	end process;
	
	
	
	-- Tile memory address composite
	tileAddr <= unsigned(data(4 downto 0)) & Ypixel(4 downto 2) & Xpixel(4 downto 2);
	
	
	-- Picture memory address composite
	addr <= to_unsigned(20, 7) * Ypixel(8 downto 5) + Xpixel(9 downto 5);
	
	
	-- VGA generation
	vgaRed(2)	<= tilePixel(7);
	vgaRed(1)	<= tilePixel(6);
	vgaRed(0)	<= tilePixel(5);
	vgaGreen(2)	<= tilePixel(4);
	vgaGreen(1)	<= tilePixel(3);
	vgaGreen(0)	<= tilePixel(2);
	vgaBlue(2)	<= tilePixel(1);
	vgaBlue(1)	<= tilePixel(0);
	

end Behavioral;

