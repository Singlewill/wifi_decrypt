------------------------------------------------------------------------------
--! 	@file		sha1_core.vhd
--! 	@function	sha1主控电路,512bit明文数据输入,160bit信息摘要输出
--!		@version	
-----------------------------------------------------------------------------
--! 	@SHA1_PRE_PROC作为数据输入缓存，以及状态控制
--! 	@SHA1_CALC进行sha1计算
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.sha1_pkt.all;
entity SHA1_CORE is 
	port(
			Clk				: 	in	std_logic;	
			Rst_n			: 	in	std_logic;
			Clr_n			: 	in 	std_logic;
			Plaintext		: 	--! @brief 512bits明文输入
								in	std_logic_vector(511 downto 0);
			Plaintext_len	:	in 	std_logic_vector(7 downto 0);
			Start			:	--! @brief Start和Plaintext一同置位
								in	std_logic;
			I_last			:	--! @brief 是否最后一条数据
								in 	std_logic;
			
			O_valid			:	out std_logic;
			Digest_out		: 	--! @brief 160bits消息摘要输出
								out std_logic_vector(159 downto 0)
		);
end SHA1_CORE;								
	
architecture BEHAVIOR of SHA1_CORE is 
	component SHA1_IBUFFER is
	port (
			Clk					:	in	std_logic; 
			Rst_n				: 	in	std_logic;
			Clr_n				: 	in 	std_logic;
			I_valid				:	in	std_logic;
			I_last				:	in	std_logic;
			I_data				: 	in	std_logic_vector(511  downto 0);
			I_datalen			:	in 	std_logic_vector(7 downto 0);
			I_next				:	in 	std_logic;
			O_valid				:  	out std_logic;
			Text_out			:	out std_logic_vector(31 downto 0);
			O_last				:	out std_logic
		 ) ;
end component;

	---------------------------------------------------------------------------
	-- 核心运算模块
	---------------------------------------------------------------------------
	component SHA1_CALC is 
	port (
			Clk			:	in  std_logic;
			Rst_n		:	in std_logic;
			Clr_n		: 	in 	std_logic;
			Start		:	in	std_logic;
			Plaintext	: 	in  std_logic_vector(31 downto 0);
			Textend		:  	in	std_logic;
			Dout		:  	out	std_logic_vector(159 downto 0)  ;
			In_valid	: 	out std_logic;
			Done 		:	out std_logic
		);
	end component;
	-----------------------------------------------------------------------------
	--! 内部信号定义
	-----------------------------------------------------------------------------
	signal s_in_valid 		: 	std_logic;
	signal s_text		:	WORD_TYPE;


	--! sha1_ibuffer模块输出有效
	signal text_valid  : std_logic;

	--! sha1_calc完成信号
	signal sha1_done : std_logic;
	signal digest_tmp: std_logic_vector(159 downto 0);

	signal last_symbol : std_logic;
	signal rO_valid : std_logic;

begin
	U_SHA1_IBUFFER 	: SHA1_IBUFFER
	port map(
				Clk			=>	Clk,
				Rst_n		=>	Rst_n,
				Clr_n		=>	Clr_n,
				I_valid		=>	Start,
				I_last		=>	I_last,
				I_data		=>	Plaintext,
				I_datalen	=> 	Plaintext_len,
				I_next		=>	s_in_valid,
				O_valid		=>	text_valid,
				Text_out	=>	s_text,
				O_last 		=>	last_symbol
			);


	U_SHA1_CALC : SHA1_CALC
	port map(
				Clk			=>	Clk,
				Rst_n 		=> 	Rst_n,
				Clr_n		=>	Clr_n,
				Start		=> 	text_valid,
				Plaintext 	=>	s_text,
				Textend 	=>	last_symbol,
				Dout		=>	digest_tmp, 
				In_valid 	=>	s_in_valid,	
				Done		=>	sha1_done
		 	);





	U_DIGEST_BUFFER : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
		elsif Clk'event and Clk = '1' then
			if Clr_n = '0' then
				--rO_valid <= '0';
			else
				if (sha1_done = '1' and last_symbol = '1' and I_last = '1') or 
				(sha1_done = '1' and I_last = '0') then
				--	rO_valid <= '1' ;
				else
				--	rO_valid <= '0' ;
				end if;

			end if;
		end if;
	end process;

			   

	Digest_out <= digest_tmp when sha1_done = '1' and last_symbol = '1' else
				  (others => '0');
	rO_valid <= '1' when (sha1_done = '1' and last_symbol = '1' and I_last = '1') or
				(sha1_done = '1' and last_symbol = '0' and I_last = '0') else
				'0';

	O_valid <= rO_valid ;


end BEHAVIOR;


