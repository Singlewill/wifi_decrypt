-----------------------------------------------------------------------------
-- 						hmac_sha1_vector.vhd
--	hmac_sha1_vector算法，接收一组Key值和最大三组Addr值，每一组最大64字节,
--	生成160bit的信息摘要Mac
-- 	整个过程分两次调用sha1_vector电路模块,在这里使用is_round_two区分
-----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.sha1_pkt.all;

entity HMAC_SHA1_VECTOR is
	generic (ITEMS : integer range 0 to 2);
	port (
			
			Clk				: 	in	std_logic; 
			Rst_n			: 	in	std_logic;
			Start			:	in 	std_logic;
			Key				: 	--! @brief 接收Key值	
								in 	std_logic_vector(511 downto 0);
			Addr			: 	--! @biref 明文数据输入
								in  HMAC_DATA(ITEMS - 1 downto  0);
			Addr_len		: 	in	HMAC_DATA_LEN(ITEMS -1 downto 0);
			Mac				: 	--! @brief 信息摘要输出	
								out	std_logic_vector(159 downto 0);
			Done			: 	out std_logic

		 );
end HMAC_SHA1_VECTOR;

architecture BEHAVIOR of HMAC_SHA1_VECTOR is
	component SHA1_CORE is
	port (
			Clk				: 	in	std_logic;	
			Rst_n			: 	in	std_logic;
			Clr_n			: 	in 	std_logic;
			Plaintext		: 	in	std_logic_vector(511 downto 0);
			Plaintext_len	:	in 	std_logic_vector(7 downto 0);
			Start			:	in	std_logic;
			I_last			:	in 	std_logic;
			O_valid			:	out std_logic;
			Digest_out		: 	out std_logic_vector(159 downto 0)
		 );
	end component;

	-------------------------------------------------------------------------
	-- 内部信号定义
	-------------------------------------------------------------------------
	--! hmac计算分两轮，第二轮时is_round_two标记为1
	signal 	is_round_two	: std_logic;

	
	

	--! 给sha1_vector装载数据指令
	signal 	load 		: 	std_logic;
	--! 给sha1_vector的明文数据
	signal 	plaintext	: 	std_logic_vector(511 downto 0);
	--! 给sha1_vector的明文数据长度
	signal	text_len 	:	std_logic_vector(7 downto 0);
	--! 接收sha1_vector的Done信号
	signal	ready		: 	std_logic;
	--! 接收sha1_vector的Digest_out
	signal	digest_tmp	:	std_logic_vector(159 downto 0);
	--! 第二轮sha1_vector的输入mac
	signal 	digest_buff	: 	std_logic_vector(159 downto 0);
	signal last : std_logic;
	--! 状态机
	type HMAC_STATES is (IDLE, 
							KEY_XOR, 
							KEY_LOAD_ON, 
							KEY_LOAD_OFF,
							KEY_CALC,
							ADDR_LOAD_ON,
							ADDR_LOAD_OFF,
							ADDR_CALC);
			signal current_state : HMAC_STATES;

	
begin


	U_SHA1_CORE : SHA1_CORE
	port map (
				Clk				=>	Clk,
				Rst_n			=> 	Rst_n,
				Clr_n			=> 	Rst_n,
				Plaintext		=> 	plaintext,
				Plaintext_len	=> 	text_len,
				Start			=>	load,
				I_last 			=> 	last,
				O_valid 		=> 	ready,
				Digest_out 		=> 	digest_tmp
			 );

	U_STATE : process(Clk, Rst_n)
		--! 正在处理的Addr索引,对应ITEMS
		variable index : integer range 0 to 7;
		--! 两轮计算中异或值，分别为0x36和0x5C
		variable xor_data : std_logic_vector(7 downto 0) := (others => '0');

	begin
		if Rst_n = '0' then
			load <= '0';
			Done <= '0';
			current_state <= IDLE;
		elsif Clk'event and Clk = '1' then
			case current_state is 
				when IDLE =>
					Done <= '0';
					if Start = '1' then
						index := 0;
						load <= '0';
						last <= '0';
						is_round_two <= '0';
						Mac <= (others => '0');

						current_state <= KEY_XOR; 
					else
						current_state <= IDLE;
					end if;
				when KEY_XOR =>
					--! 两轮的异或值不一样
					if is_round_two = '0' then
						xor_data := X"36";
					else
						xor_data := X"5C";
					end if;

					for i in 0 to 63 loop
						plaintext(i * 8 + 7 downto i * 8) <= xor_data XOR Key(i * 8 + 7 downto i * 8);
					end loop;
					text_len <= conv_std_logic_vector(64, 8);
					last <= '0';
					load <= '1';
					current_state <= KEY_CALC;
				when KEY_CALC =>
					if ready = '1' then
						load <= '0';
						current_state <= ADDR_LOAD_ON;
					else
						current_state <= KEY_CALC;
					end if;
						
				when ADDR_LOAD_ON =>
					if is_round_two = '0' then
						--! 为Addr中最后一条数据
						if index = ITEMS - 1 then
							last <= '1';
						end if;
						plaintext <= Addr(index);
						text_len <= Addr_len(index);
					else 
						-- 第二轮sha1_vector的输入为第一轮的输出
						plaintext(511 downto 352) <= digest_buff;
						plaintext(351 downto 0) <= (others => '0');
						text_len <= conv_std_logic_vector(20, 8);
						last <= '1';
					end if;

					load <= '1';
					current_state <= ADDR_CALC;
				when ADDR_CALC	=>
					if ready = '1' then
						load <= '0';
						if is_round_two = '0' then
							-- 第一轮最后一组Addr计算结束需要启动第二轮计算
							-- 并置位第二轮标记is_round_two
							if index = ITEMS - 1 then
								digest_buff <= digest_tmp;
								is_round_two <= '1';
								current_state <= KEY_XOR;
							-- 第一轮非最后一组Addr计算，则进行对下一组Addr的录入
							else
								index := index + 1;
								current_state <= ADDR_LOAD_ON;
							end if;
						-- 第二轮计算结束，则整个hmac_sha1_vector计算结束
						-- 数据输出，回归IDLE
						else
							Mac <= digest_tmp;
							Done <= '1';
							current_state <= IDLE;
						end if;

					-- sha1_vector模块仍在跑83拍
					else
						current_state <= ADDR_CALC;
					end if;
				when others =>
					current_state <= IDLE;
			end case;
		end if;
	end process;



end BEHAVIOR;

