------------------------------------------------------------------------------
--!	@file		sync_crossclk.vhd
--! @function	在跨时钟环境中，将输入信号经过CLK同步处理
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
entity SYNC_CROSSCLK is
	generic (constant DATA_WIDTH : integer := 8 );
	port (
			Clk		:	in	std_logic; 
			Rst_n	:	in	std_logic;
			Din		:	in	std_logic_vector(DATA_WIDTH - 1 downto 0);
			Dout	:	out	std_logic_vector(DATA_WIDTH - 1 downto 0)
		 );
end SYNC_CROSSCLK;
architecture BEHAVOR OF SYNC_CROSSCLK is
	--! Din在clk下的延迟信号
	signal dout_l1 :  std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal dout_l2 :  std_logic_vector(DATA_WIDTH - 1 downto 0);
begin
	U_DELAY : process(Clk, Rst_n)
	begin
		if Clk'event and Clk = '1' then
			if Rst_n = '0' then
				dout_l1 <= (others => '0');
				dout_l2 <= (others => '0');
			else
				dout_l1 <= Din;
				dout_l2 <= dout_l1;
			end if;
		end if;
	end process;

	Dout <= dout_l2;
end BEHAVOR;
