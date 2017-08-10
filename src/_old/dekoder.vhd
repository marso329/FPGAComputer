library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pong_computer is
  port (
    clk : in std_logic);
end pong_computer;

architecture behavioral of pong_computer is

	component control_unit is
	port (clk : in std_logic;
		asr_pm_enable : out std_logic;
		pm_enable : out std_logic;
		pm_write : out std_logic;
		bus_cpu : inout std_logic_vector(15 downto 0)
);
end component;


component block_RAM is
port (clk : in std_logic;
      adress_pm : in std_logic_vector(7 downto 0);
      pm_enable : in std_logic;
      pm_write : in std_logic;
      bus_cpu : inout std_logic_vector(15 downto 0)
);
	end component;

  component asr_pm
    port (clk : in std_logic;
      adress_pm : out std_logic_vector(7 downto 0);
      asr_pm_enable : in std_logic;
      bus_cpu : in std_logic_vector(15 downto 0));
  end component;

-- block_RAM and asr_pm
signal bus_cpu_bridge : std_logic_vector(7 downto 0);
signal adress_pm_bridge : std_logic_vector(7 downto 0);

-- asr_pm and control_unit
signal asr_pm_enable_bridge : std_logic_vector;

-- block_RAM and control_unit
signal pm_enable_bridge : std_logic_vector;
signal pm_write_bridge : std_logic_vector;

begin

  U0 : asr_pm port map(clk=>clk, bus_cpu=>bus_cpu_bridge, adress_pm=>adress_pm_bridge, asr_pm_enable=>asr_pm_enable_bridge);
  U1 : block_RAM port map(clk=>clk, bus_cpu=>bus_cpu_bridge, adress_pm=>adress_pm_bridge, pm_enable=>pm_enable_bridge, pm_write=>pm_write_bridge);
  U2 : control_unit port map(clk=>clk, asr_pm_enable=>asr_pm_enable_bridge, pm_enable=>pm_enable_bridge, pm_write=>pm_write_bridge);

end behavioral;