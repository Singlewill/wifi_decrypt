--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- A VHDL-Library for reading SD-Cards with a FPGA inside a small test project.
-- Copyright (C) 2017  Simon Aster
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
----------------------------------------------
-- Project:		sd_v3
-- File:			sd_v3.vhd
-- Author:		Simon Aster
-- Created:		2017-05-19
-- Modified:	2017-05-19
-- Version:		1
----------------------------------------------
-- Description:
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
-- sd
use work.sd_const_pkg.all;



entity sd_v3 is
	port(
	clk			: 	in  std_logic;
	Rst_n 		: 	in std_logic;
	Start 		:	in std_logic;
	ready		:	out std_logic;
	--	===========================================
	-- Connections to SD-Card Shield
	--	===========================================
	sd_clk	: out		std_logic;
	sd_cmd	: inout std_logic;
	sd_dat	: inout std_logic_vector(3 downto 0);	
	sd_cd		: in std_logic;
	-------------------------------------------------
	--! SD卡第一个扇区内容,固定顺序,分别为ssid1,ssid2, key2_1(固定长),key2_2,mac_nonce_1(固定长),mac_nonce_2
	ssid1		:	out std_logic_vector(511 downto 0);
	ssid2		:	out std_logic_vector(511 downto 0);
	ssid_len	:	out std_logic_vector(7 downto 0);
	key2_1		:	out std_logic_vector(511 downto 0);
	key2_2		:	out std_logic_vector(511 downto 0);
	key2_2_len	:	out std_logic_vector(7 downto 0);
	mac_nonce_1	: out std_logic_vector(511 downto 0);
	mac_nonce_2 : out std_logic_vector(511 downto 0);
	--! 第一个扇区获取标记
	first_sec_is_refresh : out std_logic;




	--! 一般的数据有效标记，可能会和first_sec_is_refresh重复
	cycle_done	: 	out std_logic;
	data_out	: out std_logic_vector(511 downto 0);
	data_out_valid 	:	out std_logic;
	--! 允许输出
	data_out_allow	:	in std_logic

	------------------
	--	===========================================
	--	===========================================
	-- std IO for debugging purpose
);
end sd_v3;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

architecture sd_v3_a of sd_v3 is
	component count_bin
		generic(
		bits        : natural
	);
	port(
			rst         : in  std_logic;
			clk         : in  std_logic;
			clk_en  : in  std_logic := '1';
			zero        : in  std_logic := '0';
			up          : in  std_logic := '0';
			down        : in  std_logic := '0';
			cnt         : out std_logic_vector(bits-1 downto 0)
		);
	end component;
 
	component simple_sd
		port(
				rst					: in  std_logic;
				clk					: in  std_logic;
				sd_clk			: out		std_logic;
				sd_cmd			: inout	std_logic;
				sd_dat			: inout	std_logic_vector(3 downto 0);
				sd_cd				: in		std_logic := '0';
				sleep				: in  std_logic := '0';
				mode				: in  sd_mode_record := sd_mode_fast;
				mode_fb			: out sd_mode_record;
				dat_address	: in  sd_dat_address_type := (others=>'0');
				ctrl_tick		: in  sd_tick_record := sd_tick_zero;
				fb_tick			: out sd_tick_record;
				dat_block		: out dat_block_type;
				dat_valid		: out std_logic;
				dat_tick		: out std_logic;
				unit_stat		: out sd_controller_stat_type
			);
	end component;


	signal sleep								: std_logic := '0';
	signal mode, mode_fb				: sd_mode_record;
	signal dat_address					: sd_dat_address_type := (others=>'0');
	signal ctrl_tick, fb_tick		: sd_tick_record;
	signal dat_block						: dat_block_type;
	signal dat_valid, dat_tick	: std_logic;
	signal unit_stat						: sd_controller_stat_type;

	attribute keep : string; 
	attribute keep of dat_valid : signal is "TRUE";
	attribute keep of dat_tick: signal is "TRUE";
	attribute keep of Start : signal is "TRUE";
	attribute keep of first_sec_is_refresh: signal is "TRUE";
	-- =================================
	signal index : integer range 0 to 7;
	type 	OUT_STATES  is (OUT_IDLE, OUT_SEND, OUT_OVER);
	signal out_state : OUT_STATES;


--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
begin
	--------------------------------------------------
	sleep <= '0';
	mode.fast <= '1';
	mode.wide_bus <= '1';

	ctrl_tick.read_single		<= '1' when Start = '1' else '0';
	ctrl_tick.read_multiple	<= '0';
	ctrl_tick.stop_transfer	<= '0';


	ready <= '1' when unit_stat = s_ready else
				 '0';

	u_simple_sd:	simple_sd port map (rst=>Rst_n, clk=>clk, sd_clk=>sd_clk, sd_cmd=>sd_cmd, sd_dat=>sd_dat, sd_cd=>sd_cd,
									sleep=>sleep, mode=>mode, mode_fb=>mode_fb, dat_address=>dat_address, ctrl_tick=>ctrl_tick, fb_tick=>fb_tick,
									dat_block=>dat_block, dat_valid=>dat_valid, dat_tick=>dat_tick, unit_stat=>unit_stat);
	add_count :  count_bin generic map (bits=>32) port map (rst=>Rst_n, clk=>clk, up=>dat_tick, cnt=>dat_address);



	d_ff: process(Rst_n, clk)
	begin
		if Rst_n= '0' then
			first_sec_is_refresh <= '0';
		elsif clk'event and clk = '1' then
			if dat_tick = '1' then
				--! 第一个扇区,额外读取配置信息
				if dat_address = conv_std_logic_vector(0, 32) then
					first_sec_is_refresh <= '1';

					--! ssid1，第一个扇区，第一个64字节,第一个字节为长度,63个字节有效
					ssid_len <= dat_block(0);
					for i in 63 downto 1 loop
						ssid1(i * 8 + 7 downto i * 8) <= dat_block(64 - i);
					end loop;
					ssid1(7 downto 0) <= (others => '0');

					--! ssid2，第一个扇区，第二个64字节
					for i in 63 downto 1 loop
						ssid2(i * 8 + 7 downto i * 8) <= dat_block(128 - i);
					end loop;
					ssid2(7 downto 0) <= (others => '0');

					--! key2_1, 第一个扇区，第三个64字节，全部字节有效
					for i in 63 downto 0 loop
						key2_1(i * 8 + 7 downto i * 8) <= dat_block(191 - i);
					end loop;

					--! key2_2，第一个扇区，第四个64字节,第一个字节为长度,63个字节有效
					key2_2_len<= dat_block(192);
					for i in 63 downto 1 loop
						key2_2(i * 8 + 7 downto i * 8) <= dat_block(256 - i);
					end loop;
					key2_2(7 downto 0) <= (others => '0');

					--! mac_nonce_1, 第一个扇区，第五个64字节，全部字节有效
					for i in 63 downto 0 loop
						mac_nonce_1(i * 8 + 7 downto i * 8) <= dat_block(319 - i);
					end loop;

					--! mac_nonce_2, 第一个扇区，第六个64字节，全字节有效
					for i in 63 downto 0 loop
						mac_nonce_2(i * 8 + 7 downto i * 8) <= dat_block(383 - i);
					end loop;
				end if;

			end if;
		end if;
	end process;


	U_DATA_OUT : process(clk, Rst_n)
	begin
		if Rst_n = '0' then
			index <= 0;
			data_out_valid <= '0';
			out_state <= OUT_IDLE;
		elsif clk'event and clk = '1' then
			case out_state is
				when OUT_IDLE =>
					if dat_tick = '1' and dat_address /= conv_std_logic_vector(0, 32) then
						index <= 0;
						out_state <= OUT_SEND;
					else
						out_state <= OUT_IDLE;
					end if;
				when OUT_SEND =>
					for i in 63 downto 0 loop
						data_out(i * 8 + 7 downto i * 8) <= dat_block(index * 64 + 63 - i);
					end loop;
				
					if data_out_allow = '1' then
						data_out_valid <= '1';
					else
						data_out_valid <= '0';
					end if;
					if index = 7 then
						index <= 0;
						out_state <= OUT_OVER;
					elsif data_out_allow = '1' then
						index <=  index + 1;
						out_state <= OUT_SEND;
					--! data_out_allow = 0　时,index暂停计数
					else
						index <= index;
						out_state <= OUT_SEND;
					end if;
				when OUT_OVER =>
					data_out_valid <= '0';
					data_out <= (others => '0');
					out_state <= OUT_IDLE;
				when others =>
			end case;
		end if;
	end process;

	cycle_done <= '1' when (dat_tick = '1' and dat_address = conv_std_logic_vector(0, 32)) or out_state = OUT_OVER else
				  '0';


end sd_v3_a;
