---------------------------------------------------------------------------------
--! @File:			sd_v3.vhd
--! @Description:	模拟SD输出数据
---------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
-- sd
use work.sd_const_pkg.all;



entity sd_virtual is
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
	--! SD卡第�?个扇区内�?,固定顺序,分别为ssid1,ssid2, key2_1(固定�?),key2_2,mac_nonce_1(固定�?),mac_nonce_2
	ssid1		:	out std_logic_vector(511 downto 0);
	ssid2		:	out std_logic_vector(511 downto 0);
	ssid_len	:	out std_logic_vector(7 downto 0);
	key2_1		:	out std_logic_vector(511 downto 0);
	key2_2		:	out std_logic_vector(511 downto 0);
	key2_2_len	:	out std_logic_vector(7 downto 0);
	mac_nonce_1	: out std_logic_vector(511 downto 0);
	mac_nonce_2 : out std_logic_vector(511 downto 0);
	--! 第一个扇区获取标�?
	first_sec_is_refresh : out std_logic;




	--! �?般的数据有效标记，可能会和first_sec_is_refresh重复
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
end sd_virtual;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

architecture sd_v3_a of sd_virtual is
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
 


	signal dat_address					: sd_dat_address_type := (others=>'0');
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
	type GEN_STATES  is (GEN_ONE, GEN_TWO, GEN_THREE);
	signal gen_state : GEN_STATES;


begin
	--------------------------------------------------

	add_count :  count_bin generic map (bits=>32) port map (rst=>Rst_n, clk=>clk, up=>dat_tick, cnt=>dat_address);

	U_GEN : process(clk, Rst_n)
		variable cnt : integer range 0 to 200;
		variable tmp :std_logic_vector(7 downto 0);
	begin
		if Rst_n = '0' then
			cnt := 0;
			tmp := (others =>'0');
			gen_state <= GEN_ONE;

		elsif clk'event and clk = '1' then
			case gen_state is
				when GEN_ONE =>
					if cnt = 200 then
						cnt := 0;
						gen_state <= GEN_TWO;
					else
						cnt := cnt + 1;
						gen_state <= GEN_ONE;
					end if;
				when GEN_TWO =>
					ready <= '1';
					tmp := tmp + 1;
					for i in 0 to 511 loop
						dat_block(i) <= tmp;
					end loop;
					dat_block(0) <= X"11";
					dat_block(64) <= X"22";
					dat_block(128) <= X"33";
					dat_block(192) <= X"44";
					dat_block(256) <= X"55";
					dat_block(320) <= X"66";
					dat_block(384) <= X"77";
					dat_block(448) <= X"88";
					dat_tick <= '1';
					gen_state <= GEN_THREE;
				when GEN_THREE =>
					dat_tick <= '0';
					if cnt = 100 then
						cnt := 0;
						gen_state <= GEN_TWO;
					else
						cnt := cnt + 1;
						gen_state <= GEN_THREE;
					end if;
			end case;
		end if;

	end process;



	d_ff: process(Rst_n, clk)
	begin
		if Rst_n= '0' then
			first_sec_is_refresh <= '0';
		elsif clk'event and clk = '1' then
			if dat_tick = '1' then
				--! 第一个扇�?,额外读取配置信息
				if dat_address = conv_std_logic_vector(0, 32) then
					first_sec_is_refresh <= '1';

					--! ssid1，第�?个扇区，第一�?64字节,第一个字节为长度,63个字节有�?
					ssid_len <= dat_block(0);
					for i in 63 downto 1 loop
						ssid1(i * 8 + 7 downto i * 8) <= dat_block(64 - i);
					end loop;
					ssid1(7 downto 0) <= (others => '0');

					--! ssid2，第�?个扇区，第二�?64字节
					for i in 63 downto 1 loop
						ssid2(i * 8 + 7 downto i * 8) <= dat_block(128 - i);
					end loop;
					ssid2(7 downto 0) <= (others => '0');

					--! key2_1, 第一个扇区，第三�?64字节，全部字节有�?
					for i in 63 downto 0 loop
						key2_1(i * 8 + 7 downto i * 8) <= dat_block(191 - i);
					end loop;

					--! key2_2，第�?个扇区，第四�?64字节,第一个字节为长度,63个字节有�?
					key2_2_len<= dat_block(192);
					for i in 63 downto 1 loop
						key2_2(i * 8 + 7 downto i * 8) <= dat_block(256 - i);
					end loop;
					key2_2(7 downto 0) <= (others => '0');

					--! mac_nonce_1, 第一个扇区，第五�?64字节，全部字节有�?
					for i in 63 downto 0 loop
						mac_nonce_1(i * 8 + 7 downto i * 8) <= dat_block(319 - i);
					end loop;

					--! mac_nonce_2, 第一个扇区，第六�?64字节，全字节有效
					for i in 63 downto 0 loop
						mac_nonce_2(i * 8 + 7 downto i * 8) <= dat_block(383 - i);
					end loop;


					ssid_len <= conv_std_logic_vector(10, 8);
					key2_2_len <= conv_std_logic_vector(57, 8);
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
					--! data_out_allow = 0�?�?,index暂停计数
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
