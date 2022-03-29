------------------------------------------------------------------------------
--! 	@file		key_schedule.vhd
--! 	@function	密码分配
--!		@version	
-----------------------------------------------------------------------------
--		这里从key_fifo中取密码，取出PBKDF2_NUM个后开启pbkdf2模块群组	
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.sha1_pkt.all;
entity KEY_SCHEDULE is
	port (
		 	Clk						:	in std_logic;
			Rst_n					:	in std_logic;

			--! key_fifo控制接口
			key_in					:	in std_logic_vector(511 downto 0);
			key_valid				:	in std_logic;
			key_fifo_empty			:	in std_logic;
			key_fifo_rd				:	out std_logic;

			passphrase				:	out PASSPHRASE_VECTOR;
			passphrase_out_valid	:	out std_logic;
			passphrase_out_allow	:	in std_logic
			
		 );
end KEY_SCHEDULE;

architecture BEHAVOR of KEY_SCHEDULE is
	type RD_STATES is (RD_READING, RD_OVER);
	signal rd_state : RD_STATES;
	signal out_valid_tmp : std_logic;
	signal index :  integer range 0 to PBKDF2_NUM - 1;
begin
	
	U_RD_CTL : process(Clk, Rst_n)
		variable cnt  : integer range 0 to PBKDF2_NUM;
	begin
		if Clk'event and Clk = '1' then
			if Rst_n = '0' then
				cnt := 0;
				rd_state <= RD_READING;
			else

				case rd_state is
					when RD_READING =>
						if key_fifo_empty = '0' and passphrase_out_allow = '1' then
							if cnt = PBKDF2_NUM then
								cnt := 0;
								key_fifo_rd <= '0';
								rd_state <= RD_OVER;
							else
								key_fifo_rd <= '1';
								cnt := cnt + 1;
								rd_state <= RD_READING;
							end if;
						else
							key_fifo_rd <= '0';
							rd_state <= RD_READING;
						end if;
					when RD_OVER	=>
						--! 等待pbkdf2模块开启, 
						--! 即passphrase_out_allow = 0后在恢复到上一个状态
						if out_valid_tmp = '1' then
							cnt := 0;
							rd_state <= RD_READING;
						else
							rd_state <= RD_OVER;
						end if;
					when others =>
						rd_state <= RD_READING;
					end case;
			end if;
		end if;
	end process;


	U_RD : process(Clk, Rst_n)
	begin
		if Clk'event and Clk = '1' then
			if Rst_n = '0' then
				index <= 0;
				out_valid_tmp <= '0';
			else
				if key_valid = '1' then
					passphrase(index) <= key_in;
					if index = PBKDF2_NUM - 1 then
						index <= 0;
						out_valid_tmp <= '1';
					else
						index <= index + 1;
					end if;
				end if;

				--! 起始信号只持续一个时钟
				if out_valid_tmp = '1' then
					out_valid_tmp <= '0';
				end if;
			end if;
		end if;
	end process;
	
	
	passphrase_out_valid <= out_valid_tmp;
end BEHAVOR;
