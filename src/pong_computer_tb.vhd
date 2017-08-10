library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pong_computer_tb is
end pong_computer_tb;

architecture Behavioral of pong_computer_tb is

  component pong_computer
      Port (
  	    clk,rst : in STD_LOGIC;
  	    JA: out std_logic_vector(7 downto 0);
  	    JB: in std_logic_vector(7 downto 0)
           );
  end component;

  -- Testsignaler
  signal clk : STD_LOGIC:='0';
    SIGNAL rst : std_logic := '1';
  SIGNAL tb_running : boolean := true;
  signal JB : std_logic_vector(7 downto 0):=x"00";
  signal JA : std_logic_vector(7 downto 0):=x"00";
BEGIN

  uut: pong_computer PORT MAP(
    clk => clk,rst=>rst,JB=>JB,JA=>JA);
          JB(0)<=JA(0);
    JB(1)<=JA(1);

	clg_gen: process
	begin
		while tb_running loop
			clk <= '0';
		wait for 5 ns;
			clk <= '1';
		wait for 5 ns;
		end loop;
		wait;
	end process;
	
  stimuli_generator : process
    variable i : integer;
  begin
    -- Aktivera reset ett litet tag.
    rst <= '1';
    wait for 500 ns;

    wait until rising_edge(clk);        -- se till att reset släpps synkront
                                        -- med klockan
    rst <= '0';
    report "Reset released" severity note;
    wait for 1 us;
    
    for i in 0 to 39 loop
      wait for 8.68 us;
    end loop;  -- i
    
    for i in 0 to 50000000 loop         -- Vänta ett antal klockcykler
      wait until rising_edge(clk);
          end loop;  -- i
    
    tb_running <= false;                -- Stanna klockan (vilket medför att inga
                                        -- nya event genereras vilket stannar
                                        -- simuleringen).
    wait;
  end process;

		

END;
