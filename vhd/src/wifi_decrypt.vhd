-----------------------------------------------------------------------------------
-- 							wifi_decrypt.vhd
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

use work.sha1_pkt.all;


ENTITY WIFI_DECRYPT is
	port (
			Clk		: 	in	std_logic; 
			Rst_n	:	in	std_logic;

			--! SD接口信号
			SD_cmd : inout std_logic;
			SD_clk	: out std_logic;
			SD_dat	: inout std_logic_vector(3 downto 0);
			SD_cd 	: in std_logic;


			Tx_pin	:	--! @brief 串口输出引脚
						out std_logic

		 );
end WIFI_DECRYPT ;

architecture BEHAVIOR of WIFI_DECRYPT is
	component MMCM_BASE_CLK is
	port(
			Clk_in		:	in	std_logic;	
			Rst_n		:	in	std_logic;
			locked		:	out	std_logic;
			Clk_out0	:	out	std_logic;
			Clk_out1	:	out	std_logic
		);
	end component;
	--! 将SD驱动与put to key fifo结合到了�?�?
	component sd_v3
	port(
		clk			: in  std_logic;
		Rst_n 		: in std_logic;
		Start		: in std_logic;
		ready		:	out std_logic;
		---------------------------------------------------
		--! 外部接口
		---------------------------------------------------
		sd_clk	: out		std_logic;
		sd_cmd	: inout std_logic;
		sd_dat	: inout std_logic_vector(3 downto 0);	
		sd_cd		: in std_logic;

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

		cycle_done	: 	out std_logic;
		data_out	: out std_logic_vector(511 downto 0);
		data_out_valid 	:	out std_logic;
		data_out_allow	:	in std_logic

	);
	end component;

	--! �첽fifo,���ڴ�Ŵ�SD��ȡ����key
	component FIFO_ASYNC
	generic (
			constant DATA_WIDTH	:	integer := 8;
			constant ADDR_WIDTH	:	integer := 4
		);
	port (
			Rst_n			:	in	std_logic;
			--! д���
			Clk_wr			:	in	std_logic;
			Wr_en            :   in  std_logic;
			Din				:	in	std_logic_vector(DATA_WIDTH - 1 downto 0);
			Full			:	out	std_logic;
			Almost_full		:	out std_logic;

			--! ������
			Clk_rd			:	in	std_logic;
			Rd_en        :   in  std_logic;
			Dout			:	out	std_logic_vector(DATA_WIDTH - 1 downto 0);
			Empty			:	out std_logic;
			Almost_empty	:	out std_logic;
			Valid			:	out std_logic
		 );
	end component;

	--! 从key fifo中取出passphrase, 并分配给PBKDF2_NUM个pbkdf2模块
	component KEY_SCHEDULE
	port (
		 	Clk						:	in std_logic;
			Rst_n					:	in std_logic;

			key_in					:	in std_logic_vector(511 downto 0);
			key_valid				:	in std_logic;
			key_fifo_empty			:	in std_logic;
			key_fifo_rd				:	out std_logic;

			passphrase				:	out PASSPHRASE_VECTOR;
			passphrase_out_valid	:	out std_logic;
			passphrase_out_allow	:	in std_logic
		 );
	end component;

	--! 生成pmk的算法模�?
    component PBKDF2_SHA1
    port(
			Clk				:	in 	std_logic; 
			Rst_n			:	in 	std_logic;
			Start			:	in	std_logic;
			Ready			:	out	std_logic;
			Passphrase		:	in	std_logic_vector(511 downto 0);
			Ssid			:	in	std_logic_vector(511 downto 0);
			Ssid2			:	in	std_logic_vector(511 downto 0);
			Ssid_len		:	in 	std_logic_vector(7 downto 0);
			Pmk				:	out	std_logic_vector(255 downto 0);
			Done			:	out std_logic
		
        );
    end component;

	--! 将生成的pmk连同对应的passphrase�?起放到pmk fifo�?
	component PMK_PUT_TO_FIFO
	port (
			Clk			:	in		std_logic; 
			Rst_n		:	in		std_logic;
			Passphrase	:	in		PASSPHRASE_VECTOR;
			Pmk			:	in		PMK_VECTOR;
			In_valid	:	in		std_logic;
			Data_out	:	out 	std_logic_vector(767 downto 0);
			Data_valid	:	out		std_logic;
			Data_out_allow	:	in	std_logic
		 );
	end component;



	--! ͬ��fifo�����ڴ�����ɵ�pmk
	component FIFO_SYNC
	generic (
			constant DATA_WIDTH	:	integer := 8;
			--! ʵ��fifo����Ϊ2**ADDR_WIDTH
			constant ADDR_WIDTH	:	integer := 4
		);
	port (
			Clk				:	in	std_logic;
			Rst_n			:	in	std_logic;
			--! д���
			Wr_en			:	in	std_logic;
			Din				:	in	std_logic_vector(DATA_WIDTH - 1 downto 0);
			Full			:	out	std_logic;
			Almost_full		:	out	std_logic;
			
			--! ������
			Rd_en			:	in	std_logic;
			Dout			:	out	std_logic_vector(DATA_WIDTH - 1 downto 0);
			Empty			:	out	std_logic;
			Almost_empty	:	out	std_logic;
			Valid			:	out	std_logic
		 );

	end component;



	--! 从pmk_fifo中取出pmk和passphrase, 给后续模块验�?
	component PMK_GET_FROM_FIFO 
	port (
			Clk				:	in	std_logic;
			Rst_n			:	in	std_logic;
			Data_in			:	in	std_logic_vector(767 downto 0);
			In_valid		:	in	std_logic;
			Data_allow_read	:	in	std_logic;
			Data_rd			:	out	std_logic;
			Passphrase		:	out	std_logic_vector(511 downto 0);
			pmk				:	out	std_logic_vector(255 downto 0);
			Out_valid		:	out std_logic;
			Out_allow		:	in	std_logic
		 );
	end component;

	component PMK_VERIFY
	port(
			Clk			:	in	std_logic;	
			Rst_n		:	in	std_logic;
			Start		:	in	std_logic;
			Pmk			:	in	std_logic_vector(255 downto 0);
			Passphrase 	:	in	std_logic_vector(511 downto 0);
			Key2_1		:	in	std_logic_vector(511 downto 0);
			Key2_2		:	in	std_logic_vector(511 downto 0);
			Key2_2_len	:	in	std_logic_vector(7 downto 0);
			Mac_nonce_1	: 	in	std_logic_vector(511 downto 0);
			Mac_nonce_2	: 	in	std_logic_vector(511 downto 0);
			
			Done		:	out	std_logic;
			Ready		:	out	std_logic;
			Is_match	: 	out std_logic_vector(1 downto 0);
			Right_key	:	out	std_logic_vector(511 downto 0)
		);
	end component;

	--! 控制信号跨时钟同�?
	component SYNC_PULSE
	port (
			Clk_a 		: in std_logic; 
			Clk_b 		: in std_logic;
			Rst_n		:	in std_logic;
			Pulse_a_in 	: in std_logic;
			Pulse_b_out : out std_logic
		 );
		 end component;


	--! 生成串口使用的门控时�?
	component CLKDIV 
	port (
			Clk		: 	in 	std_logic;
			Rst_n		:	in 	std_logic;
			Clk_out		: 	out std_logic
		 );
	end component;

	--! 串口发�??
	component UART_TX 
	port(
			Clk		: in	std_logic;	
			Rst_n	:	in	std_logic;
			Enable	:	in	std_logic;
			Tx_pin	:	out	std_logic;
			Tx_buff	:	in	std_logic_vector(7 downto 0);
			Done 	:	out std_logic
		);
	end component;
	--------------------------------------------------------------------------
	--							END COMPONENT								--
	--------------------------------------------------------------------------



    


	--------------------------------------------------------------------------
	--	内部信号定义
	--------------------------------------------------------------------------
	--! SD相关
	signal clk_50m					:	std_logic := '0';
	signal clk_100m					:	std_logic;
	signal rst						:	std_logic;
	--! *_top信号是顶层频率的脉冲,与之对应的下层低频脉�?
	signal sd_start_top			:	std_logic;
	signal sd_start 				:	std_logic;
	signal sd_data_valid_top		:	std_logic;
	signal sd_data_valid			:	std_logic;
	signal sd_ready		:	std_logic;
	type SD_STATES is (SD_PRE_READING, SD_READING);
	signal sd_state : SD_STATES;
	--------------------------------------------------------------------------
	-- 全局寄存器组
	--------------------------------------------------------------------------
	signal first_sec_is_refresh	: 	std_logic;
	signal ssid1				:	std_logic_vector(511 downto 0);
	signal ssid2				: 	std_logic_vector(511 downto 0);
	signal ssid_len 			: 	std_logic_vector(7 downto 0);
	signal key2_1				: 	std_logic_vector(511 downto 0);
	signal key2_2				: 	std_logic_vector(511 downto 0);
	signal key2_2_len 			: 	std_logic_vector(7 downto 0);
	signal mac_nonce_1			: 	std_logic_vector(511 downto 0);
	signal mac_nonce_2			: 	std_logic_vector(511 downto 0);

	--------------------------------------------------------------------------
	-- key fifo相关
	--------------------------------------------------------------------------
	signal key_fifo_in			:	std_logic_vector(511 downto 0);
	signal key_fifo_out			:	std_logic_vector(511 downto 0);
	signal key_fifo_in_en		:	std_logic;
	signal key_fifo_full		:	std_logic;
	signal key_fifo_empty		:	std_logic;
	signal key_fifo_out_en		:	std_logic;
	signal key_fifo_out_valid 	:	std_logic;

	--! pbkdf2_sha1相关
	--! 8个模块公用一个start信号
	signal pbkdf2_sha1_start	:	std_logic;
	signal pbkdf2_sha1_ready   	:	std_logic;
	signal pbkdf2_sha1_done		:	std_logic;

	--! 以上模块�?终取出来的passphrase和pmk数据对，�?�?对应
	--! 由key_shcedule模块从key_fifo中取出，sd_v3放进key_fifo�?
	signal passphrase 			:	PASSPHRASE_VECTOR;
	--�? 由数个pbkdf2模块生成
	signal pmk					:	PMK_VECTOR;

	--------------------------------------------------------------------------
	-- pmk fifo相关
	--------------------------------------------------------------------------
	signal pmk_fifo_in_en		:	std_logic;
	signal pmk_fifo_out_en		:	std_logic;

	signal pmk_fifo_full		:	std_logic;
	signal pmk_fifo_empty		:	std_logic;
	signal pmk_fifo_cnt			:	std_logic_vector(3 downto 0);
	signal pmk_fifo_data_in		:	std_logic_vector(767 downto 0);
	signal pmk_fifo_data_out	:	std_logic_vector(767 downto 0);
	signal pmk_fifo_out_valid	:	std_logic;
	--! 待验证的pmk与key组合
	signal pmk_to_verify			:	std_logic_vector(255 downto 0);
	signal passphrase_to_verify	:	std_logic_vector(511 downto 0);


	--------------------------------------------------------------------------
	-- pmk veirfy相关
	--------------------------------------------------------------------------
	signal pmk_veify_start		:	std_logic;
	signal pmk_verify_ready 	:	std_logic;
	signal pmk_verify_done 		:	std_logic;
	signal right_key			:	std_logic_vector(511 downto 0);
	signal is_match			:	std_logic_vector(1 downto 0);






	--! 串口相关
	signal 	clk_uart			:	std_logic;
	signal 	tx_enable			:	std_logic;
	signal	tx_done				:	std_logic;
	signal 	tx_buff				:	std_logic_vector(7 downto 0);
	signal 	ll_test1 			:	std_logic_vector(511 downto 0);
	signal 	ll_test2 			:	std_logic_vector(511 downto 0);
	signal 	ll_test3 			:	std_logic_vector(255 downto 0);
	signal 	ll_print 			: 	std_logic;



	--!�?状�?�机3, 控制串口输出模块
	type UART_TX_STATES is (TX_WAIT, TX_SEND1, TX_SEND2, TX_SEND3, TX_SEND4, TX_SEND5, TX_SEND6, TX_SEND_DONE);
	signal uart_tx_state : UART_TX_STATES := TX_WAIT;
	type CTL_STATES is (CTL_ONE, CTL_TWO, CTL_THREE, CTL_FOUR, CTL_FIVE, CTL_SIX, CTL_SEVEN, CTL_EIGHT, CTL_NINE);
	signal ctl_state : CTL_STATES;

-----------------------------------------------------------------------------
	signal pmk_fifo_in_allow : std_logic;
	signal pmk_fifo_out_allow : std_logic;
	signal key_fifo_in_allow : std_logic;
	signal key_schedule_allow : std_logic;

begin
	key_fifo_in_allow <= not key_fifo_full;
	pmk_fifo_in_allow <= not pmk_fifo_full;
	pmk_fifo_out_allow <= not pmk_fifo_empty;
	--key_schedule_allow <= '1' when pbkdf2_sha1_ready = '1' and rst_50m = '1' else
	--					  '0';
-----------------------------------------------------------------------------
	U_MMCM_BASE_50M : MMCM_BASE_CLK
	port map(
				Clk_in		=>	Clk,
				Rst_n		=>	Rst_n,
				locked		=>	rst,
				Clk_out0	=>	clk_100m,
				Clk_out1	=>	clk_50m
			);
-------------------------------------------------------------------------------

	U_SD : sd_v3
	port map(
				clk				=>	clk_50m,
				Rst_n 			=>	rst,
				Start			=>	sd_start,
				ready			=>	sd_ready,

				sd_clk			=> 	SD_clk,
				sd_cmd			=>	SD_cmd,
				sd_dat			=>	SD_dat,
				sd_cd			=>	SD_cd,


				ssid1			=>	ssid1,
				ssid2			=>	ssid2,
				ssid_len		=>	ssid_len,
				key2_1			=>	key2_1,
				key2_2			=>	key2_2,
				key2_2_len		=>	key2_2_len,
				mac_nonce_1 	=>	mac_nonce_1,
				mac_nonce_2 	=>	mac_nonce_2,
				first_sec_is_refresh => first_sec_is_refresh,

				cycle_done 		=> 	sd_data_valid,
				--! fifo接口
				data_out		=>	key_fifo_in,
				data_out_valid 	=>	key_fifo_in_en,
				data_out_allow	=>	key_fifo_in_allow

			);

	--! SD使能信号跨时钟同�?
	U_SD_START_SYNC : SYNC_PULSE
	port map(
				Clk_a 			=>	clk_100m,
				Clk_b 			=>	clk_50m,
				Rst_n			=>	rst,
				Pulse_a_in 		=>	sd_start_top,
				Pulse_b_out		=>	sd_start
			
			);

	U_SD_VALID_SYNC : SYNC_PULSE
	port map(
				Clk_a 			=>	clk_50m,
				Clk_b 			=>	clk_100m,
				Rst_n			=>	rst,
				Pulse_a_in 		=>	sd_data_valid,
				Pulse_b_out		=>	sd_data_valid_top
			);

	U_KEY_FIFO : FIFO_ASYNC
	generic map(DATA_WIDTH => 512,
			   ADDR_WIDTH => 5)		-- ����Ϊ2**5 = 32
	port map(
				Rst_n 			=>	rst,
				Clk_wr 			=>	clk_50m,
				Wr_en			=>	key_fifo_in_en,
				Din 			=>  key_fifo_in,
				Almost_full		=>	key_fifo_full,


				Clk_rd 			=>	clk_100m,
				Rd_en			=>	key_fifo_out_en,
				Dout 			=>	key_fifo_out,
				Almost_empty	=>	key_fifo_empty,
				valid			=>	key_fifo_out_valid
			);

	U_KEY_SCHEDULE : KEY_SCHEDULE
	port map(
				Clk						=>	clk_100m,
				Rst_n					=>	rst,

				key_in					=>	key_fifo_out,
				key_valid				=>	key_fifo_out_valid,
				key_fifo_empty			=>	key_fifo_empty,
				key_fifo_rd				=>	key_fifo_out_en,

				passphrase				=>	passphrase,
                passphrase_out_valid	=>	pbkdf2_sha1_start,
				passphrase_out_allow	=>	pbkdf2_sha1_ready
				
			);

	--! 八个pbkdf2_sha1模块，控制信号只拿第�?个就�?
	U_PBKDF2_SHA1_0 : PBKDF2_SHA1
	port map(
				Clk				=> clk_100m,
				Rst_n			=> rst,
				Start			=> pbkdf2_sha1_start,
				Ready			=> pbkdf2_sha1_ready,
				Passphrase		=> passphrase(0),
				Ssid			=> ssid1,
				Ssid2			=> ssid2,
				Ssid_len		=> ssid_len,
				Pmk				=> pmk(0),
				Done			=> pbkdf2_sha1_done
			);
	PBKDF2_SHA1_GEN : for i in 1 to PBKDF2_NUM - 1 generate begin
		U_PBKDF2_SHA1_i : PBKDF2_SHA1
		port map(
					Clk				=> clk_100m,
					Rst_n			=> rst,
					Start			=> pbkdf2_sha1_start,
					Passphrase		=> passphrase(i),
					Ssid			=> ssid1,
					Ssid2			=> ssid2,
					Ssid_len		=> ssid_len,
					Pmk				=> pmk(i)
				
				);
	end generate;

	U_PMK_PUT_TO_FIFO : PMK_PUT_TO_FIFO
	port map(
				Clk					=>	clk_100m,
				Rst_n				=> rst,
				Passphrase			=>	passphrase,
				Pmk					=>	pmk,
				In_valid			=>	pbkdf2_sha1_done,
				Data_out			=>	pmk_fifo_data_in,
				Data_valid			=>	pmk_fifo_in_en,
				Data_out_allow		=>	pmk_fifo_in_allow
			);

	U_PMK_FIFO : FIFO_SYNC
	generic map(DATA_WIDTH => 768,
			   ADDR_WIDTH => 4) 	-- ����Ϊ2**4 - 1 = 15
	port map(
				Clk					=>	clk_100m,
				Rst_n 				=>	rst,

				Wr_en				=>	pmk_fifo_in_en,
				Din 				=>	pmk_fifo_data_in,
				Almost_full			=>	pmk_fifo_full,

				Rd_en				=>	pmk_fifo_out_en,
				Dout 				=>	pmk_fifo_data_out,
				Almost_empty		=>	pmk_fifo_empty,
				valid				=>	pmk_fifo_out_valid
			);

	U_PMK_GET_FROM_FIFO : PMK_GET_FROM_FIFO
	port map(
				Clk					=>	clk_100m,
				Rst_n				=>	rst,
				Data_in				=>	pmk_fifo_data_out,
				In_valid			=>	pmk_fifo_out_valid,
				Data_allow_read		=>	pmk_fifo_out_allow,
				Data_rd				=>	pmk_fifo_out_en,
				Passphrase			=>	passphrase_to_verify,
				pmk					=>	pmk_to_verify,
				Out_valid			=>	pmk_veify_start,
				Out_allow			=>	pmk_verify_ready
			
			);


	U_PMK_VERIFY : PMK_VERIFY
	port map(
				Clk					=>	clk_100m,
				Rst_n				=>	rst,
				Start				=>	pmk_veify_start,
				Pmk					=>	pmk_to_verify,
				Passphrase 			=> 	passphrase_to_verify,
				Key2_1				=>	key2_1,
				Key2_2				=>	key2_2,
				Key2_2_len			=>	key2_2_len,
				Mac_nonce_1			=>	mac_nonce_1,
				Mac_nonce_2			=>	mac_nonce_2,
				
				Done				=>	pmk_verify_done,
				Ready				=>	pmk_verify_ready,
				Is_match			=>	is_match,
				Right_key			=>	right_key
			
			);

	U_CLKDIV : CLKDIV
	port map(
				Clk		=> 	clk_100m,
				Rst_n		=>	rst,
				Clk_out		=> 	clk_uart
			);

	U_UART_TX : UART_TX
	port map(
				Clk			=> 	clk_uart,
				Rst_n		=>	rst,
				Enable		=> 	tx_enable,
				Tx_pin		=>	Tx_pin,
				Tx_buff		=>	tx_buff,
				Done		=> 	tx_done
			);





	-------------------------------------------------------------------------
	--! SD控制
	-------------------------------------------------------------------------
	U_SD_START : process(clk_100m, rst)
	begin
		if clk_100m'event and clk_100m = '1' then
			if rst = '0' then
				sd_state <= SD_PRE_READING;
				sd_start_top <= '0';
			else
				case sd_state is
					when SD_PRE_READING =>
						--! 读SD信号�?�?
						if key_fifo_full = '0' and sd_ready = '1' and uart_tx_state = TX_WAIT then
							sd_start_top <= '1';
							sd_state <= SD_READING;
						else
							sd_start_top <= '0';
							sd_state <= SD_PRE_READING;
						end if;
					when SD_READING =>
						sd_start_top <= '0';
						if sd_data_valid_top = '1' then
							sd_state <= SD_PRE_READING;
						else
							sd_state <= SD_READING;
						end if;
					when others =>
						sd_state <= SD_PRE_READING;
						sd_start_top <= '0';
				end case;
			end if;
		end if;
	end process;



	------------------------------------------------------------------------
	------------------------------------------------------------------------
	--�?�?�?	调试区域
	-------------------------------------------------------------------------
	-------------------------------------------------------------------------
	P_CTL_STATE : process(clk_100m, rst_n)
	begin
		if clk_100m'event and clk_100m= '1' then
			if rst = '0' then
				ctl_state <= CTL_ONE;
			else
				case ctl_state is
					when CTL_ONE 	=>
					when CTL_TWO 	=>
					when CTL_THREE 	=>
					when CTL_FOUR 	=>
					when CTL_FIVE	=>
					when CTL_SIX	=>
					when others =>
				end case;
			end if;
		end if;
	end process;
	

	P_UART_TX : process(clk_100m, rst)
		variable cnt : integer range 0 to 512;
	begin
		if rst= '0' then
			uart_tx_state <= TX_WAIT;
		elsif clk_100m'event and clk_100m= '1' then
			case uart_tx_state is 
				when TX_WAIT =>
					if is_match = "01"  then	
						ll_test1 <=  right_key;
						--ll_test2 <=  passphrase(0);
						ll_test3 <= pmk_to_verify;
						cnt := 0;
						uart_tx_state <= TX_SEND1;
					else
						uart_tx_state <= TX_WAIT;
					end if;
				when TX_SEND1 =>
					if  tx_done = '0' then
						tx_buff(7 downto 0) <= ll_test1((ll_test1'length - cnt  - 1) downto  (ll_test1'length - cnt - 8));
						--tx_buff(7 downto 0) <= pmk_verify((512 - cnt  - 1) downto  (512 - cnt - 8));
						tx_enable <= '1';
						cnt := cnt + 8;
						uart_tx_state <= TX_SEND2;
					else
						uart_tx_state <= TX_SEND1;
					end if;
				when TX_SEND2 =>
					if tx_done = '1' then
						tx_enable <= '0';
						if cnt >=  ll_test1'length then
							cnt := 0;
							uart_tx_state <= TX_SEND_DONE;
						else
							uart_tx_state <= TX_SEND1;
						end if;
					else	
						uart_tx_state <= TX_SEND2;
					end if;

				when TX_SEND3 =>
					if  tx_done = '0' then
						tx_buff(7 downto 0) <= ll_test3((ll_test3'length - cnt  - 1) downto  (ll_test3'length - cnt - 8));
						--tx_buff(7 downto 0) <= pmk_verify((512 - cnt  - 1) downto  (512 - cnt - 8));
						tx_enable <= '1';
						cnt := cnt + 8;
						uart_tx_state <= TX_SEND4;
					else
						uart_tx_state <= TX_SEND3;
					end if;
				when TX_SEND4 =>
					if tx_done = '1' then
						tx_enable <= '0';
						if cnt >=  ll_test3'length then
							uart_tx_state <= TX_SEND_DONE;
						else
							uart_tx_state <= TX_SEND3;
						end if;
					else	
						uart_tx_state <= TX_SEND4;
					end if;
				when TX_SEND_DONE =>
				when others =>
				end case;
		end if;
	end process;







end BEHAVIOR;



