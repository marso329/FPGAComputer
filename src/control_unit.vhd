library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity control_unit is
port (	clk : in std_logic;
		pm_read : out std_logic;
		pm_write : out std_logic;
		gm_read : out std_logic;
		bus_in : in std_logic_vector(15 downto 0);
		bus_out : out std_logic_vector(15 downto 0);
		bus_mux : out std_logic_vector(3 downto 0);
		rst : in std_logic;
		select_reg : out std_logic_vector(1 downto 0);
		reg_write : out std_logic;
		reg_read : out std_logic;
		asr_out : out std_logic_vector(7 downto 0);
		asr_gm_out : out std_logic_vector(7 downto 0);
		alu_write : out std_logic;
		alu_control : out std_logic_vector(3 downto 0);
		Z : in std_logic;
		N : in std_logic;
		O : in std_logic;
		C : in std_logic;
		JA : out std_logic_vector(7 downto 0);
		JB: in std_logic_vector(7 downto 0)
);
end control_unit;

architecture Behavioral of control_unit is
	
	-- read in instruction
	
	-- IR is used to read instruction from bus_cpu 16 bit
	signal IR : std_logic_vector(15 downto 0) := X"0000";
	
	-- PC is used to adress the instructions 8 bit
	signal PC : std_logic_vector(7 downto 0) := X"00";
	
	-- OP is used to tell which operand is used 4 bit
	alias OP            : std_logic_vector(3 downto 0)      is IR(15 downto 12);
	
	--GRx is used to tell which register to adress 2 bit
	alias GRx           : std_logic_vector(1 downto 0)      is IR(11 downto 10);
	
	-- M tells which adress method is used 2 bit
	alias M             : std_logic_vector(1 downto 0)      is IR(9 downto 8);

	--ADR tells which adress to adress 8 bit
	alias ADR           : std_logic_vector(7 downto 0)     is IR(7 downto 0); 
	
	-- Microcode
	
	--uPC is the program counter for the microcode memory 8 bit 
	signal uPC		    : std_logic_vector(7 downto 0)      := X"00";
	
	--SuPC is used to store uPC during jumps, might skip this 8 bit
	signal SuPC			: std_logic_vector(7 downto 0)      := X"00";
	
	-- K1 is used to point out the opcodes microcode in micromemory 8 bit
	signal K1       	: std_logic_vector(7 downto 0)      := X"00";
	
	-- K2 is used to point out microcode for the adressmethod 8 bit
	signal K2			: std_logic_vector(7 downto 0)      := X"00";
	
	-- the current microcode instruction 32 bit but only 25 is used
	signal uIR          : std_logic_vector(31 downto 0)     := X"00000000";
	
	-- ALU points out which ALU operations to use 4 bit
	alias ALU           : std_logic_vector(3 downto 0)      is uIR(25 downto 22);
	
	-- tells which data to send to the bus 3 bit
	alias TB            : std_logic_vector(2 downto 0)      is uIR(21 downto 19); 
	
	-- tells where to send the data from the bus
	alias FB            : std_logic_vector(2 downto 0)      is uIR(18 downto 16); 
	
	-- tells if the GRx or the M-field controlls the register mux 1 bit
	alias S             : std_logic                         is uIR(15);
	
	-- counts up the PC when high 1 bit
	alias P             : std_logic                         is uIR(14);           -- When '1' PC++
	
	-- controls the loop counter 2 bit
	alias LC            : std_logic_vector(1 downto 0)      is uIR(13 downto 12);
	


	-- LC allready exist, testing to change name to the 2bit-ctr to LC2BIT



	-- controlls the uPC 4 bit
	alias SEQ           : std_logic_vector(3 downto 0)      is uIR(11 downto 8);
	
	--stores the uPC at jumps 8 bit
	alias uADR          : std_logic_vector(7 downto 0)      is uIR(7 downto 0); 
	
	-- used to halt the processor
	signal halt : std_logic := '1';
	
	-- zero if loop counter=0
	signal L : std_logic := '0';
	
	
	-- LC allready exist, testing to change name to the 8bit-ctr to LC8BIT


	 -- uMem
	type uMem_t is array(0 to 127) of std_logic_vector(31 downto 0); -- Expand to 32 for simplicity.
	constant uMem : uMem_t := ( -- Memory for microprograming code.
		x"0018_4000", -- bus=PC, pc+=1
		x"0005_0000", -- asr=bus
		x"0010_0000", -- bus=pm
		x"0000_0000", -- chill
		x"0001_0000", -- ir=pm, 
		x"0000_0200", -- Upc=k2
		x"002d_0100", -- if direct bus=adr,asr=bus  uPC=k1
		x"0028_0100", -- if immediate jump here bus=adr ,upc=k1 $
		x"0000_0000", -- not used
		x"002d_0000", -- jump here if indirect bus=adr asr=bus @
		x"0000_0000", -- chill
		x"0010_0000", -- bus=pm
		x"0000_0000", -- chill 
		x"0005_0100", -- asr=bus, uPC=K1
		x"0018_0000", -- special adress method bus=pc  %
		x"0005_4100", -- asr=bus, PC=PC+1,uPC=K1
		x"0000_0000", -- not used
		x"0000_0000", -- not used
		x"0010_0000", -- load 0x12 bus=pm
		x"0000_0000", -- chill
		x"0004_0300", -- grx=bus uPC=0
		x"0020_0000", -- store: 0x15 bus=GRx
		x"0000_0000", -- chill
		x"0002_0000", -- pm=bus
		x"0000_0000", -- chill
		x"0000_0300", -- upc=0
		x"0010_0000", -- add: 0x1a bus=pm
		x"0000_0000", -- chill
		x"0040_0000", -- ar=buss
		x"0020_0000", -- buss=grx
		x"0000_0000", -- chill
		x"0000_0000", -- chill
		x"0000_0000", -- chill
		x"0100_0000", -- ar=ar+bus
		x"0030_0000", -- bus=ar
		x"0000_0000", -- chill
		x"0004_0000", -- grx=bus
		x"0000_0300", -- chill upc=0
		x"0010_0000", -- sub: 0x26(38) bus=pm
		x"0000_0000", -- chill
		x"0040_0000", -- ar=buss
		x"0020_0000", -- buss=grx
		x"0000_0000", -- chill
		x"0000_0000", -- chill
		x"0000_0000", -- chill
		x"0140_0000", -- ar=ar-bus
		x"0030_0000", -- bus=ar
		x"0000_0000", -- chill
		x"0004_0000", -- grx=bus
		x"0000_0300", -- chill upc=0
		x"0010_0000", -- and: 0x32(50) bus=pm
		x"0000_0000", -- chill
		x"0040_0000", -- ar=buss
		x"0020_0000", -- buss=grx
		x"0000_0000", -- chill
		x"0000_0000", -- chill
		x"0000_0000", -- chill
		x"0180_0000", -- ar=ar and bus
		x"0030_0000", -- bus=ar
		x"0000_0000", -- chill
		x"0004_0000", -- grx=bus
		x"0000_0300", -- chill upc=0
		x"0020_0000", -- lsr: 0x3e(62) bus=GRx NOT USED
		x"0000_0000", -- chill
		x"0040_0000", -- ar=buss
		x"0200_0000", -- ar=ar<<1
		x"0030_0000", -- bus=ar
		x"0000_0000", -- chill
		x"0004_0000", -- grx=bus
		x"0000_0300", -- chill upc=0
		x"0028_0000", -- bra x46 (70) bus=adr
		x"0003_0300", -- pc=bus upc=0
		x"0000_084b", -- bne x48(72) jmp to 4b if Z=1
		x"0028_0000", -- bus=adr
		x"0003_0300", -- pc=bus upc=0
		x"0000_0300", -- upc=0
		x"0000_0F00", -- halt x4c(76)
		x"0010_0000", -- cmp: 0x4d(77) bus=pm
		x"0000_0000", -- chill
		x"0040_0000", -- ar=buss
		x"0020_0000", -- bus=grx
		x"0000_0000", -- chill
		x"0000_0000", -- chill
		x"0000_0000", -- chill
		x"0140_0300", -- ar=ar-bus upc=0
		x"0000_0957", -- bge 0x55(85) jmp to 57 if N=1
		x"0000_0300", -- upc=0
		x"0028_0000", -- bus=adr
		x"0003_0300", -- pc=bus upc=0
		x"0000_085b", -- beq 0x59(89) jmp to 5b if z=1
		x"0000_0300", -- upc=0
		x"0028_0000", -- bus=adr
		x"0003_0300", -- pc=bus upc=0
		x"0020_0000", -- out 0x5d(93) bus=grx
		x"0000_0000", -- chill
		x"0006_0300", -- out=bus, upc=0
		x"0038_0000", -- in 0x60(96) bus=in
		x"0000_0000", -- chill
		x"0004_0300", -- grx=bus upc=0
		x"0020_0000", -- storev: 0x63 bus=GRx
		x"0000_0000", -- chill
		x"0007_0000", -- gm=bus
		x"0000_0000", -- chill
		x"0000_0300", -- upc=0
		x"0040_0000", -- comb: 0x68 AR=BUS
		x"0020_0000", -- buss=grx
		x"0000_0000", -- chill
		x"0280_0000", -- ar=ar comb bus
		x"0030_0000", -- bus=ar
		x"0000_0000", -- chill
		x"0004_0000", -- grx=bus
		x"0000_0300", -- chill upc=0
		x"0020_0000", -- lsr new: 0x70(112) bus=GRx NOT USED
		x"0000_0000", -- chill
		x"0040_0000", -- ar=buss
		x"0028_0000", -- bus =adr
		x"0200_0000", -- ar=ar<<1
		x"0030_0000", -- bus=ar
		x"0000_0000", -- chill
		x"0004_0000", -- grx=bus
		x"0000_0300", -- chill upc=0
		others => x"0000_0000"
	);

begin
	-- read instruction from micro memory
	uIR <= uMem(conv_integer(uPC));

	--select adress method
	with M select
		K2 <= X"06" when "00",	-- EA Direct, the ADR points the the memory containing the operand
		X"07" when "01",		-- EA Imidiate, the operand is the adr field
		X"09" when "10",		-- EA Indirect the ADR field points to a memory location that contains the memory location for the operand
		X"0e" when others;		-- EA Index

	-- K1 - Go to instruction 
	with OP select
		K1 <= X"12" when "0000", 	-- LOAD		0
		X"15" when "0001", 			-- STORE	1
		X"1A" when "0010", 			-- ADD		2
		X"26" when "0011", 			-- SUB		3
		X"32" when "0100", 			-- AND		4
		X"70" when "0101", 			-- LSR		5
		X"46" when "0110", 			-- BRA		6
		X"48" when "0111", 			-- BNE		7      
		X"4c" when "1000", 			-- HALT		8 
		X"63" when "1001", 			-- STOREV	9
		X"4d" when "1010", 			-- CMP		A  
		X"55" when "1011", 			-- BGE		B
		x"59" when "1100", 			-- BEQ		C 
		x"60" when "1101", 			-- IN		D
		x"5d" when "1110", 			-- OUT		E
		x"68" when "1111", 			-- COMB		F
		X"1D" when others; 			-- Default to LOAD when not implemented. 

	alu_control<=ALU;


	-- seq field
	process(clk) 
	begin
		if rising_edge(clk) and halt='1'  then
			if rst='0'  then
				uPC<=x"00";
				halt<='1';
				L<='0';
			else
				case SEQ is
					when "0000"=>
						--just in case
						if uPC /= "1111111" then
							uPC<=std_logic_vector(to_unsigned(to_integer(unsigned( uPC )) + 1, 8));
						else
							uPC<="00000000";
						end if;
					when "0001"=>
						uPC<=K1;
					when "0010"=>
						uPC<=K2;
					when "0011"=>
						uPC<="00000000";
					when "0100"=>
						if Z='0' then
							uPC<=uADR;
						else
							uPC<=std_logic_vector(to_unsigned(to_integer(unsigned( uPC )) + 1, 8));
						end if;
					when "0101" =>
						uPC<=uADR;
					when "0110"=>
						SuPC<=std_logic_vector(to_unsigned(to_integer(unsigned( uPC )) + 1, 8));
						uPC<=uADR;
					when "0111"=>
						uPC<=SuPC;
					when "1000"=>
						if Z='1' then
							uPC<=uADR;
						else
							uPC<=std_logic_vector(to_unsigned(to_integer(unsigned( uPC )) + 1, 8));
						end if;
					when "1001"=>
						if N='1' then
							uPC<=uADR;
						else
							uPC<=std_logic_vector(to_unsigned(to_integer(unsigned( uPC )) + 1, 8));
						end if;
					when "1011"=>
						if Z='0' then
							uPC<=uADR;
						else
							uPC<=std_logic_vector(to_unsigned(to_integer(unsigned( uPC )) + 1, 8));
						end if;
					when "1100"=>
						if L='1' then
							uPC<=uADR;
						else
							uPC<=std_logic_vector(to_unsigned(to_integer(unsigned( uPC )) + 1, 8));
						end if;
					when "1101"=>
						if C='0' then
							uPC<=uADR;
						else
							uPC<=std_logic_vector(to_unsigned(to_integer(unsigned( uPC )) + 1, 8));
						end if;
					when "1110"=>
						if O='0' then
							uPC<=uADR;
						else
							uPC<=std_logic_vector(to_unsigned(to_integer(unsigned( uPC )) + 1, 8));
						end if;
					when "1111"=>
						uPC<="00000000";
						halt<='0';
					when others=>
						null;
				end case;
			end if;
		end if;
	end process;


	--FB FIELD
	process(clk) 
	begin
		if rising_edge(clk) then
			if rst='0' or halt ='0' then
				IR<=x"0000";
				pm_read<='1';
				PC<=x"00";
				asr_out<=x"00";
				asr_gm_out<=x"00";
				JA<=x"00";
				gm_read<='1';
			else
				case FB is
					--puts the data on the bus into IR and disables asr and pm
					when "001" =>
						IR <= bus_in;
						pm_read<='1';
						gm_read<='1';
					-- tells the PM to read the data into the adress the ASR is pointing to
					when "010"=>
						pm_read<='0';
						gm_read<='1';
					-- reads the data from the bus into PC, also disables pm and asr
					when "011"=>
						PC<=bus_in(7 downto 0);
						pm_read<='1';
						gm_read<='1';
					--tells the asr to read the data from the bus, disables the PM
					when "101"=>
						asr_out<=bus_in(7 downto 0);
						 asr_gm_out<=bus_in(7 downto 0);
						pm_read<='1';
						gm_read<='1';
					-- 	disables PM and asr
					when "111"=>
						gm_read<='0';
						pm_read<='1';
					when "110"=>
						JA<=bus_in(7 downto 0);
						pm_read<='1';
						gm_read<='1';
					when others=>
						pm_read<='1';
						gm_read<='1';
				end case;
				if P='1' then
					PC<=std_logic_vector(to_unsigned(to_integer(unsigned( PC )) + 1, 8));
				end if;
			end if;
		end if;
	end process;    
	      
	      
	--register access
	process(clk) 
	begin
		if rising_edge(clk) then
			if rst='0' or halt='0' then
				select_reg<="00";
				reg_write<='1';
				reg_read<='1';
			else
				if TB="100" or FB="100" then
					if S='0' then
						select_reg<=GRx;
					else
						select_reg<=M;
					end if;
				end if;
				if FB="100" then
					reg_read<='0';
				else
					reg_read<='1';
				end if;
				if TB="100" then
					reg_write<='0';
				else
					reg_write<='1';
				end if;
			end if;
		end if;
	end process;


	--TB field
	process(clk) 
	begin
		if rising_edge(clk) then
			if rst='0' or halt='0' then
				bus_mux<="0000";
				bus_out<=(others => '0');
				pm_write<='1';
				alu_write<='1';
			else
				case TB is
					--put the data in IR on the bus, disable asr and pm
					when "001" =>
						bus_mux<="0001";
						bus_out<=IR;
						pm_write<='1';
						alu_write<='1';
					-- tells the pm write the data that asr point to onto the bus
					when "010"=>
						pm_write<='0';
						bus_mux<="0010";
						alu_write<='1';
					--Puts the data in the PC onto the bus
					when "011"=>
						bus_mux<="0001";
						bus_out<=x"00"& PC;
						pm_write<='1';
						alu_write<='1';
					when "101"=>
						bus_mux<="0001";
						bus_out<=x"00"& ADR;
						pm_write<='1';
						alu_write<='1';
					when "100"=>
						bus_mux<="0011";
						alu_write<='1';
					when "110" =>
						bus_mux<="0100";
						alu_write<='0';
						pm_write<='1';
					when "111" =>
						bus_mux<="0001";
						bus_out<="00000000"& JB(7 downto 0);
						pm_write<='1';
						alu_write<='1';
					when others=>
						pm_write<='1';
						alu_write<='1';
				end case;
			end if;
		end if;
	end process;   
end Behavioral;
