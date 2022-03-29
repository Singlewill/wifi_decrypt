-------------------------------------------------------------------------------
--!	@file		simple_dual_one_clock.vhd 
--! @function	简单单时钟双口RAM
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity SIMPLE_DUAL_ONE_CLOCK is
	generic (
			constant DATA_WIDTH	:	integer := 8;
			--! 实际fifo容量为2**ADDR_WITH
			constant ADDR_WIDTH	:	integer := 4
		);
	port(
		Clk   : in  std_logic;
		Ena   : in  std_logic;
		Enb   : in  std_logic;
		Addra : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
		Addrb : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
		Dia   : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
		Dob   : out std_logic_vector(DATA_WIDTH - 1 downto 0)
	);
end simple_dual_one_clock;

architecture BEHAVOR of SIMPLE_DUAL_ONE_CLOCK is
	type ram_type is array (2**ADDR_WIDTH - 1 downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal RAM : ram_type;

	attribute ram_style : string;
	--! block -> block RAM
	--! distributed -> distribed RAM
	attribute ram_style of RAM : signal is "block";
begin
	
	process(Clk)
	begin
		if Clk'event and Clk = '1' then
			if Ena = '1' then
				RAM(conv_integer(Addra)) <= Dia;
			end if;
		end if;
	end process;

	process(Clk)
	begin
		if Clk'event and Clk = '1' then
			if Enb = '1' then
				Dob <= RAM(conv_integer(Addrb));
			end if;
		end if;
	end process;


end BEHAVOR;
