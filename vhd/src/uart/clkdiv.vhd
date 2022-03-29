------------------------------------------------------------------------------
-- 								clkdiv.vhd
--	uart时钟分频，产生一个9600波特率的16倍时钟,9600 * 16 = 153600
--	50 000 0000 / 153600 = 326, 即对系统50M时钟进行326分频
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;


entity CLKDIV is 
	port (
			Clk		: 	in 	std_logic;
			Rst_n		:	in 	std_logic;
			Clk_out		: 	out std_logic
		 );
end CLKDIV;

architecture BEHAVIOR of CLKDIV is
begin
	process(Clk, Rst_n)
		constant  division : integer := 651;
		variable clk_cnt : integer range 0 to division;
	begin
		if Rst_n = '0' then
			clk_cnt := 0;
		elsif Clk'event and Clk = '1' then
			if clk_cnt = division / 2 then
				Clk_out <= '1';
				clk_cnt := clk_cnt + 1;
			elsif clk_cnt = division - 1 then
				Clk_out <= '0';
				clk_cnt := 0;
			else
				clk_cnt := clk_cnt + 1;
			end if;
		end if;
	end process;
end BEHAVIOR;



