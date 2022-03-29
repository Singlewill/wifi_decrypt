------------------------------------------------------------------------------
--! 	@file		pmk_verify.vhd
--! 	@function	pmk验证
--!		@version	
-----------------------------------------------------------------------------
--		接收pmk和key2包，验证pmk是否匹配，匹配则is_match="01"和当前passphrase
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.sha1_pkt.all;


entity PMK_VERIFY is
	port(
				Clk			:	in	std_logic;	
				Rst_n		:	in	std_logic;
				Start		:	in	std_logic;
				Pmk			:	in	std_logic_vector(255 downto 0);
				Passphrase 	:	in	std_logic_vector(511 downto 0);
				Key2_1		:	in	std_logic_vector(511 downto 0);
				Key2_2		:	in	std_logic_vector(511 downto 0);
				Key2_2_len	:	in	std_logic_vector(7 downto 0);
				Mac_nonce_1	:	--! 必须是64字节
								in	std_logic_vector(511 downto 0);
				Mac_nonce_2	:	--! 必然是35字节,后续计算会加一个字节的counter
								in	std_logic_vector(511 downto 0);
				
				Done		:	out	std_logic;
				Ready		:	out	std_logic;
				Is_match	:	--! 结果是否正确，正确="01",错取="10"
								out std_logic_vector(1 downto 0);
				Right_key	:	out	std_logic_vector(511 downto 0)
			);
end PMK_VERIFY;


architecture BEHAVOR of PMK_VERIFY is
	component HMAC_SHA1_VECTOR is
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

	end component;


	--! hmac_sha1模块数据输出
	signal	hmac_out		: 	std_logic_vector(159 downto 0);
	signal 	hmac_done		:	std_logic;
	--! hmac_sha1模块Addr输入
	signal 	hmac_data		:	HMAC_DATA(1 downto 0);
	signal	hmac_data_len	:	HMAC_DATA_LEN(1 downto 0);
	signal	hmac_key		:	std_logic_vector(511 downto 0);
	signal 	hmac_start		:	std_logic;

	signal kck				:	std_logic_vector(127 downto 0);
	signal mic : std_logic_vector(127 downto 0);

	type PMK_STATES is (PMK_IDLE, PMK_KCK_LOAD, PMK_KCK_OFF, PMK_KCK_CALC, PMK_MIC_LOAD, PMK_MIC_OFF, PMK_VERIFY);
	signal pmk_state : PMK_STATES;

	
begin
	mic 			<= Key2_2(375 downto 248);



	U_HMAC_SHA1_VECTOR : HMAC_SHA1_VECTOR
	generic map(ITEMS => 2)
	port map(
				Clk			=>	Clk,
				Rst_n		=>	Rst_n,
				Start		=>	hmac_start,
				Key			=>	hmac_key,
				Addr		=>	hmac_data,
				Addr_len	=>  hmac_data_len,
				Mac			=>  hmac_out,
				Done		=>  hmac_done
			);

	
	U_STATES : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			Ready <= '1';
			hmac_start <= '0';
			pmk_state <= PMK_IDLE;
		elsif Clk'event and Clk = '1' then
			case pmk_state is
				when PMK_IDLE =>
					Done <= '0';
					if Start = '1' then
						Ready <= '0';
						pmk_state <= PMK_KCK_LOAD;
					else
						Ready <= '1';
					end if;
				when PMK_KCK_LOAD =>
					hmac_key		<= Pmk & conv_std_logic_vector(0, 256);
					hmac_data(0) 	<= Mac_nonce_1;
					hmac_data(1) 	<= Mac_nonce_2;
					hmac_data_len(0) <= conv_std_logic_vector(64, 8);
					--! 这里的长度需要加上8bit的counter
					hmac_data_len(1) <= conv_std_logic_vector(36, 8);
					hmac_start <= '1';
					
					pmk_state <= PMK_KCK_OFF;
				when PMK_KCK_OFF=>
					hmac_start <= '0';
					pmk_state <= PMK_KCK_CALC;
				when PMK_KCK_CALC =>
					if hmac_done = '1' then
						kck <= hmac_out(159 downto 32);
						pmk_state <= PMK_MIC_LOAD;
					else
						pmk_state <= PMK_KCK_CALC;
					end if;
				when PMK_MIC_LOAD =>
					hmac_key		<= kck & conv_std_logic_vector(0, 384);
					hmac_data(0) 	<= Key2_1;
					hmac_data(1) 	<= Key2_2(511 downto 376) & conv_std_logic_vector(0, 128) & Key2_2(247 downto 0);
					hmac_data_len(0) <= conv_std_logic_vector(64, 8);
					--! 这里的长度需要加上8bit的counter
					hmac_data_len(1) <= Key2_2_len;
					hmac_start <= '1';
					
					pmk_state <= PMK_MIC_OFF;
				when PMK_MIC_OFF =>
					hmac_start <= '0';
					pmk_state <= PMK_VERIFY;
				when PMK_VERIFY=>
					if hmac_done = '1' then
						Done <= '1';
						if mic(127 downto 0) = hmac_out(159 downto 32) then
							Is_match <= "01";
							Right_key <= passphrase;
						else
							Right_key <= (others => '0');
							Is_match <= "10";
						end if;
						pmk_state <= PMK_IDLE;
					else
						pmk_state <= PMK_VERIFY;
					end if;
				when others =>
			end case;
		end if;
	end process;

end BEHAVOR;


