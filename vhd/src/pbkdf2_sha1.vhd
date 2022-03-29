------------------------------------------------------------------------------
--                              pbkdf2_sha1.vhd
--	使用指定ssid和密码生成pmk
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.sha1_pkt.all;
 
entity PBKDF2_SHA1 is 
	port(
			Clk				:	in 	std_logic; 
			Rst_n			:	in 	std_logic;
			Start			:	in	std_logic;
			Ready			:	out std_logic;
			Passphrase		:	in	std_logic_vector(511 downto 0);
			Ssid			:	in	std_logic_vector(511 downto 0);
			Ssid2			:	in	std_logic_vector(511 downto 0);
			Ssid_len		:	in 	std_logic_vector(7 downto 0);
			Pmk				:	--! @brief 32Bytes输出
								out	std_logic_vector(255 downto 0);
			Done			:	out std_logic
		
		);
end PBKDF2_SHA1;


architecture BEHAVIOR of PBKDF2_SHA1 is
	component PBKDF2_SHA1_F is
	port (
			Clk				:	in 	std_logic; 
			Rst_n			:	in 	std_logic;
			Start			:	in	std_logic;
			Ready			:	out	std_logic;
			Passphrase		:	in	std_logic_vector(511 downto 0);
			Data_in			:	in	std_logic_vector(511 downto 0);
			Data_len		:	in 	std_logic_vector(7 downto 0);
			Digest			:	out std_logic_vector(159 downto 0);
			Done			:	out std_logic
	);
	end component;
	--------------------------------------------------------------------------
	-- 内部信号定义
	--------------------------------------------------------------------------

	--! pbkdf2_sha1_f模块相关
	signal pbkdf2_sha1_f_done1	: std_logic;
	signal pbkdf2_sha1_f_done2	: std_logic;
	signal pbkdf2_sha1_f_out1	:	std_logic_vector(159 downto 0);
	signal pbkdf2_sha1_f_out2	:	std_logic_vector(159 downto 0);

	signal done_tmp	:	std_logic;
	--! 状态机
	type PBKDF2_STATES is (IDLE, CALC, DATA_OUT);
	signal current_state : PBKDF2_STATES := IDLE;
begin

	U_PBKDF2_SHA1_F_ONE: PBKDF2_SHA1_F 
	port map(
				Clk				=> 	Clk,
				Rst_n			=> 	Rst_n,
				--! 直接复用pbkdf2_sha1的start
				Start			=>	Start,
				Ready			=>	Ready,
				Passphrase		=> 	Passphrase,
				Data_in			=>	Ssid,
				Data_len 		=>	Ssid_len,
				Digest			=>	pbkdf2_sha1_f_out1,
				Done			=>	pbkdf2_sha1_f_done1
			);

	U_PBKDF2_SHA1_F_TWO: PBKDF2_SHA1_F 
	port map(
				Clk				=> 	Clk,
				Rst_n			=> 	Rst_n,
				--! 直接复用pbkdf2_sha1的start
				Start			=>	Start,
				--! 两个pbk_df2_f的运行机制一致，所以没必要再拿一个Ready
				--Ready			=>	Ready,
				Passphrase		=> 	Passphrase,
				Data_in			=>	Ssid2,
				Data_len 		=>	Ssid_len,
				Digest			=>	pbkdf2_sha1_f_out2,
				Done			=>	pbkdf2_sha1_f_done2
			);
	process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			done_tmp <= '0';
			Pmk <= (others => '0');
		elsif Clk'event and Clk = '1' then
			if pbkdf2_sha1_f_done1 = '1' and pbkdf2_sha1_f_done2 = '1' then
				Pmk  <= pbkdf2_sha1_f_out1 & pbkdf2_sha1_f_out2(159 downto 64);
				done_tmp <= '1';
			end if;


			if done_tmp = '1' then
				done_tmp <= '0';
			end if;
		end if;
	end process;
	Done <= done_tmp;

--! 这里不使用组合逻辑，是因为Done置位后,上级模块不一定能第一时间取出pmk，所以pmk不能随便变
--	Pmk  <= pbkdf2_sha1_f_out1 & pbkdf2_sha1_f_out2(159 downto 64) when pbkdf2_sha1_f_done1 = '1' and pbkdf2_sha1_f_done2 = '1' else
--			(others => '0');

--	Done <= '1' when pbkdf2_sha1_f_done1 = '1' and pbkdf2_sha1_f_done2 = '1' else
--			'0';

end BEHAVIOR;
