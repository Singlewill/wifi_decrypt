------------------------------------------------------------------------------
---							sha1_schedule.vhd
--! 	@file		sha1_schedule.vhd
--! 	@function	单纯相应I_valid然后计数
--!		@version	
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.sha1_pkt.all;

entity SHA1_SCHEDULE is 
	port(
			Clk				:	in std_logic;	
			Rst_n			:	in std_logic;
			Clr_n 			:	in std_logic;
			I_valid			:	in std_logic;
			S_num			:	out integer
		);
end SHA1_SCHEDULE;
architecture BEHAVIOR of SHA1_SCHEDULE is
	signal 		rS_num:	integer range 0 to 79;
begin

	U_CALC_COUNT : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
				rS_num <= 0;
		elsif Clk'event and Clk = '1'  then
			if Clr_n = '0' then
				rS_num <= 0;
			elsif  rS_num < 79 and (I_valid = '1' or  rS_num > 0) then
				rS_num <= rS_num + 1;
			else
				rS_num <= 0;
			end if;
		end if;
	end process;

	----------------------------------------------------
	-- 输出
	----------------------------------------------------
	S_num <= rS_num;

end BEHAVIOR;

