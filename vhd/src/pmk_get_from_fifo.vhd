------------------------------------------------------------------------------
--! 	@file		pmk_get_from_fifo.vhd
--! 	@function	从pmk_fifo中取数据，一次取一条,拆分为pmk和passphrase,
--!					供给后面模块验证pmk
--!		@version	
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.sha1_pkt.all;

entity PMK_GET_FROM_FIFO is
	port (
			Clk				:	in	std_logic;
			Rst_n			:	in	std_logic;
			Data_in			:	--! 512bit(passphrase) + 256bit(pmk) = 	768
								in	std_logic_vector(767 downto 0);
			In_valid		:	in	std_logic;
			Data_allow_read	:	in	std_logic;

			Data_rd			:	out	std_logic;

			Passphrase		:	out	std_logic_vector(511 downto 0);
			pmk				:	out	std_logic_vector(255 downto 0);
			Out_valid		:	out std_logic;
			Out_allow		:	in	std_logic

		 );
end PMK_GET_FROM_FIFO;
architecture BEHAVOR of PMK_GET_FROM_FIFO is
	type RD_STATES is (RD_READING, RD_OVER);
	signal rd_state : RD_STATES;
	signal out_valid_tmp : std_logic;
begin
	U_RD_CTL : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			Data_rd <= '0';
			rd_state <= RD_READING;
		elsif Clk'event and Clk = '1' then
			case rd_state is
				when RD_READING =>
					--！允许读，并且允许输出
					if Data_allow_read = '1' and Out_allow = '1' then
						--! 一次只持续一个周期
						Data_rd <= '1';
						rd_state <= RD_OVER;
					else
						Data_rd <= '0';
						rd_state <= RD_READING;
					end if;
				when RD_OVER	=>
					Data_rd <= '0';
					--! 等待pbkdf2模块开启, 
					--! 即passphrase_out_allow = 0后在恢复到上一个状态
					if out_valid_tmp = '1' then
						rd_state <= RD_READING;
					else
						rd_state <= RD_OVER;
					end if;
				when others =>
					rd_state <= RD_READING;
				end case;
		end if;
	end process;


	U_RD : process(Clk, Rst_n)
		variable index : integer range 0 to PBKDF2_NUM;
	begin
		if Rst_n = '0' then
			out_valid_tmp <= '0';
		elsif Clk'event and Clk = '1' then
			if In_valid = '1' then
				Passphrase 	<= Data_in(767 downto 256);
				Pmk			<= Data_in(255 downto 0);
				out_valid_tmp <= '1';
			end if;

			--! 起始信号只持续一个时钟
			if out_valid_tmp = '1' then
				out_valid_tmp <= '0';
			end if;
		end if;
	end process;
	
	
	Out_valid <= out_valid_tmp;
end BEHAVOR;
