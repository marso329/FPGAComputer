library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pong_computer is
	port (
		clk			: in std_logic;
		rst			: in std_logic;
		JA			: out std_logic_vector(7 downto 0);	--output
		JB			: in std_logic_vector(7 downto 0);	--input
		Hsync		: out std_logic;					--horizontal sync
		Vsync		: out std_logic;					--vertical sync
		vgaRed		: out std_logic_vector(2 downto 0);	--VGA red
		vgaGreen	: out std_logic_vector(2 downto 0);	--VGA green
		vgaBlue		: out std_logic_vector(2 downto 1)	--VGA blue
    );
end pong_computer;

architecture behavioral of pong_computer is

	--adress : 0001
	component control_unit is
	port (clk : in std_logic;
		rst : in std_logic;
		--tell the pm to read from bus
		pm_read : out std_logic;
		--tell pm to write to bus
		pm_write : out std_logic;
		--tell gm to read to bus
		gm_read : out std_logic;
		--used to send data to bus
		bus_in : in std_logic_vector(15 downto 0);
		--used to receive data from bus
		bus_out : out std_logic_vector(15 downto 0);
		--used to tell which unit to put data on bus
		bus_mux : out std_logic_vector(3 downto 0);
		--used to select which register to r/w from
		select_reg : out std_logic_vector(1 downto 0);
		--tells the selected register to read
		reg_write : out std_logic;
		--tells the selected register to write
		reg_read : out std_logic;
		--selects which line in memory to r/w from
		asr_out : out std_logic_vector(7 downto 0);
		--selects which line in gm to r/w from
		asr_gm_out : out std_logic_vector(7 downto 0);
		--tells the alu to write to the bus
		alu_write : out std_logic;
		--tells the alu which function to use
		alu_control : out std_logic_vector(3 downto 0);
		--flags
		Z : in std_logic;
		N : in std_logic;
		O : in std_logic;
		C : in std_logic;
		--output
		JA: out std_logic_vector(7 downto 0);
		--input
		JB: in std_logic_vector(7 downto 0)
		);
	end component;
	
	--adress : 0010
	component pm is
	port (clk : in std_logic;
		rst : in std_logic;
		--tells the pm which line to select
		adress_pm : in std_logic_vector(7 downto 0);
		--tells the pm to read from the bus into the selected line
		pm_read : in std_logic;
		--tells the pm to write from the selected line onto the bus 
		pm_write : in std_logic;
		--used to receive data from the bus
		bus_in : in std_logic_vector(15 downto 0);
		--used to send data to the bus
		bus_out : out std_logic_vector(15 downto 0)
		);
	end component;
	
	--adress : 0011
	component grX is
	port (clk	: in std_logic;
		rst	: in std_logic;
		--used to select which register to r/w from
		select_reg : in std_logic_vector(1 downto 0);
		-- tells the selected register to write to the bus
		reg_write : in std_logic;
		-- tells the selected reg to read from the bus
		reg_read : in std_logic;
		--used to receive from the bus
		bus_in : in std_logic_vector(15 downto 0);
		--used to send to the bus
		bus_out	: out std_logic_vector(15 downto 0)
		);
	end component;
	
	--adress : 0100
	component alu is
	port (clk : in std_logic;
		rst: in std_logic;
		--used to receive data from the bus
		bus_in : in std_logic_vector(15 downto 0);
		--used to send data to the bus
		bus_out : out std_logic_vector(15 downto 0);
		--tells the alu to write to the bus
		alu_write : in std_logic;
		--controls which function the alu will do
		alu_control : in std_logic_vector(3 downto 0);
		--flags
		Z : out std_logic;
		N : out std_logic;
		O : out std_logic;
		C : out std_logic
		);
	end component;
	
	--adress : --
	component gpu is
	port(clk : in std_logic;
		rst : in std_logic;
		--used to receive from gm
		bus_in_gpu : in std_logic_vector(15 downto 0);
		--tells gm which line to select
		 asr_gm : out std_logic_vector(7 downto 0);
		--VGA output
		vgaRed, vgaGreen : out std_logic_vector(2 downto 0);
		vgaBlue : out std_logic_vector(2 downto 1);
		--h/vsync
		Hsync, Vsync : out std_logic
		);
	end component;
	
	
	--adress : 0101
	component gm is
	port(clk : in std_logic;
		rst : in std_logic;
		--tells gm to read from the bus into the selected line
		gm_read : in std_logic;
		--tells gm which line to select (from cpu)
		adress_gm : in std_logic_vector(7 downto 0);
		--tells gm which line to select (from gpu)
		adress_gpu : in std_logic_vector(7 downto 0);
		--used to receive from the bus
		bus_in : in std_logic_vector(15 downto 0);
		--used to send to the gpu
		bus_out_gpu : out std_logic_vector(15 downto 0)
		);
	end component;
	
	--bridges
	signal rst_bridge					: std_logic;
	signal pm_read_bridge				: std_logic;
	signal pm_write_bridge				: std_logic;
	signal gm_read_bridge				: std_logic;
	signal asr_bridge					: std_logic_vector(7 downto 0);
	signal asr_gm_bridge				: std_logic_vector(7 downto 0);
	signal select_reg_bridge			: std_logic_vector(1 downto 0);
	signal reg_write_bridge				: std_logic;
	signal reg_read_bridge				: std_logic;
	signal bus_mux_bridge				: std_logic_vector(3 downto 0);
	signal bus_out_bridge				: std_logic_vector(15 downto 0);
	signal bus_in_bridge_control_unit	: std_logic_vector(15 downto 0);
	signal bus_in_bridge_pm				: std_logic_vector(15 downto 0);
	signal bus_in_bridge_grx			: std_logic_vector(15 downto 0);
	
	--alu bridges
	signal bus_in_bridge_alu	: std_logic_vector(15 downto 0);
	signal alu_write_bridge		: std_logic;
	signal alu_control_bridge	: std_logic_vector(3 downto 0);
	
	--flag bridges
	signal Z_bridge	: std_logic;
	signal N_bridge	: std_logic;
	signal O_bridge	: std_logic;
	signal C_bridge	: std_logic;
	
	--gpu bridges
	signal bus_in_gpu_bridge 	: std_logic_vector(15 downto 0);
	signal asr_gpu_bridge 		: std_logic_vector(7 downto 0);


begin
	rst_bridge<=not rst; --used to make rst activate on low instead of high
	bus_out_bridge<=bus_in_bridge_control_unit when bus_mux_bridge="0001" else
					bus_in_bridge_pm when bus_mux_bridge="0010" else
					bus_in_bridge_grx when bus_mux_bridge="0011" else
					bus_in_bridge_alu when bus_mux_bridge="0100" else
					x"0000";

	U0 : pm port map(
		clk=>clk,
		rst=>rst_bridge, 
		bus_in=>bus_out_bridge,
		bus_out=> bus_in_bridge_pm, 
		adress_pm=>asr_bridge, 
		pm_read=>pm_read_bridge, 
		pm_write=>pm_write_bridge
		);
  

	U1 : grX port map(
		clk=>clk,
		rst=>rst_bridge,
		select_reg=>select_reg_bridge,
		reg_write=>reg_write_bridge,
		reg_read=>reg_read_bridge,
		bus_in=>bus_out_bridge,
		bus_out=>bus_in_bridge_grx
		);

	U2 : control_unit port map(
		clk=>clk, 
		pm_read=>pm_read_bridge, 
		pm_write=>pm_write_bridge,
		gm_read=>gm_read_bridge,
		bus_in =>bus_out_bridge,
		bus_out=> bus_in_bridge_control_unit,
		bus_mux =>bus_mux_bridge,
		rst=>rst_bridge,
		select_reg=>select_reg_bridge,
		reg_write=>reg_write_bridge,
		reg_read=>reg_read_bridge,
		asr_out=>asr_bridge,
		asr_gm_out=>asr_gm_bridge,
		alu_control=>alu_control_bridge,
		alu_write=>alu_write_bridge,
		Z =>Z_bridge,
		N =>N_bridge,
		O =>O_bridge,
		C =>C_bridge,
		JA=>JA,
		JB=>JB
		);
  
	U3 : alu port map (
		clk=>clk,
		rst=>rst_bridge,
		bus_in=>bus_out_bridge,
		bus_out=>bus_in_bridge_alu,
		alu_write=>alu_write_bridge,
		alu_control=>alu_control_bridge,
		Z =>Z_bridge,
		N =>N_bridge,
		O =>O_bridge,
		C =>C_bridge
		);

	U4 : gm port map (
		clk=>clk,
		rst=>rst_bridge,
		gm_read=>gm_read_bridge,
		adress_gm=>asr_gm_bridge,
		adress_gpu=>asr_gpu_bridge,
		bus_in=>bus_out_bridge,
		bus_out_gpu=>bus_in_gpu_bridge
		);

	U5: gpu port map (
		clk=>clk,
		rst=>rst_bridge,
		bus_in_gpu=>bus_in_gpu_bridge,
		asr_gm=>asr_gpu_bridge,
		vgaRed=>vgaRed,
		vgaGreen=>vgaGreen,
		vgaBlue=>vgaBlue,
		Hsync=>Hsync,
		Vsync=>Vsync
		);

end behavioral;
