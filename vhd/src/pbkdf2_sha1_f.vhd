------------------------------------------------------------------------------
--                              pbkdf2_sha1_f.vhd
--	pbkdf2_sha1的子模块
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.sha1_pkt.all;

entity PBKDF2_SHA1_F is
	port (
			Clk				:	in 	std_logic; 
			Rst_n			:	in 	std_logic;
			Start			:	in	std_logic;
			Ready			:	out	std_logic;
			Passphrase		:	in	std_logic_vector(511 downto 0);
			Data_in			:	--! @brief ssid+counter	
								in	std_logic_vector(511 downto 0);
			Data_len		:	in 	std_logic_vector(7 downto 0);
			Digest			:	out std_logic_vector(159 downto 0);
			Done			:	out std_logic
);

end PBKDF2_SHA1_F;

architecture BEHAVIOR of PBKDF2_SHA1_F is
	component HMAC_SHA1_VECTOR
		generic (ITEMS : integer);
		port (
				Clk				: 	in	std_logic; 
				Rst_n			: 	in	std_logic;
				Start			:	in 	std_logic;
				Key				: 	in 	std_logic_vector(511 downto 0);
				Addr			: 	in  HMAC_DATA(ITEMS - 1 downto 0);
				Addr_len		: 	in	HMAC_DATA_LEN(ITEMS - 1 downto 0);
				Mac				: 	out	std_logic_vector(159 downto 0);
				Done			: 	out std_logic
			 );
	end component;
	--------------------------------------------------------------------------
	-- 内部信号定义
	--------------------------------------------------------------------------


	--! hmac模块data输入
	signal hmac_data		:	HMAC_DATA(0 downto 0);
	signal hmac_data_len	:	HMAC_DATA_LEN(0 downto 0);
	signal hmac_start		:	std_logic := '0';
	--! hmac模块输出
	signal hmac_out			:	std_logic_vector(159 downto 0);
	signal hmac_done		:	std_logic := '0';

	--! 状�?�机定义
	type PBKDF2_F_STATES is (IDLE, PRE_LOAD_ON , PRE_CALC,
		LOAD_ON, LOAD_OFF, CALC, OVER);
	signal current_state 	: 	PBKDF2_F_STATES;

	--! 二段输入预缓�?
	signal digest_in_2		:	std_logic_vector(159 downto 0);
begin


	U_HMAC_SHA1_VECTOR : HMAC_SHA1_VECTOR
	generic map (ITEMS => 1)
	port map(
				Clk			=>	Clk,
				Rst_n		=>	Rst_n, 
				Start		=>	hmac_start,
				Key			=>	Passphrase,
				Addr		=>	hmac_data,
				Addr_len	=> 	hmac_data_len,
				Mac			=> 	hmac_out,
				Done		=>	hmac_done
			);


	U_STATE : process(Clk, Rst_n)
		--! 分别以字节为单位保存�?段二段hmac_sha1_vector输出
		variable  tmp1	: std_logic_vector(159 downto 0);
		variable  tmp2	: std_logic_vector(159 downto 0);

		--! 循环计数，计�?4095�?
		variable  j	: integer range 0 to 4096;
	begin
		if Rst_n = '0' then
			hmac_start		<= '0';
			Done <= '0';
			Ready <= '1';
			current_state <= IDLE;
		elsif Clk'event and Clk = '1' then
			case current_state is 
				when IDLE	=>
					Done <= '0';
					if Start = '1' then
						Ready <= '0';
						hmac_start		<= '0';
						Digest <= (others =>'0');
						current_state <= PRE_LOAD_ON;
					else
						Ready <= '1';
						current_state <= IDLE;
					end if;
				when PRE_LOAD_ON	=>
					hmac_data(0) <= Data_in;
					hmac_data_len(0) <= Data_len;

					hmac_start <= '1';
					current_state <= PRE_CALC;
				when PRE_CALC =>
					hmac_start <= '0';
					if hmac_done = '1' then
						--! 以字节的形式存储，用于后面异或运�?
						tmp1 := hmac_out;

						--! 准备二段计算
						j := 1;
						--!�?�?段的输出是二段的输入
						digest_in_2 <= hmac_out;
						current_state <= LOAD_ON;

					else
						current_state <= PRE_CALC;
					end if;
				when LOAD_ON 	=>
					hmac_data(0)(511 downto 352) <= digest_in_2;
					hmac_data(0)(351 downto 0) <= (others => '0');
					
					hmac_data_len(0) <= conv_std_logic_vector(20, 8);

					hmac_start <= '1';
					current_state <= LOAD_OFF;
				when LOAD_OFF =>
					hmac_start <= '0';
					current_state <= CALC;

				when CALC =>
					if hmac_done = '1' then
						--! 循环次数+1
						j := j + 1;
						digest_in_2 <= hmac_out;
						tmp2 := hmac_out;

						for i in 0 to 19 loop
							tmp1(i * 8 + 7 downto i * 8) :=	tmp1(i * 8 + 7 downto i * 8) XOR tmp2(i * 8 + 7 downto i * 8);
						end loop;
						if j < ITERATIONS 	then
							current_state <= LOAD_ON;
						else
							current_state <= OVER;
						end if;
					else
						current_state <= CALC;
					end if;

				when OVER =>
					--Ready <= '1';
					Done <= '1';
					Digest <= tmp1;
					current_state <= IDLE;
				when others	=>
					current_state <= IDLE;
			end case;
		end if;
	end process;
end BEHAVIOR;
