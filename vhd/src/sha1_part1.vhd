-------------------------------------------------------------------------------
--!	@file		sha1_part1.vhd
--! @function	sha1计算中的第一部分
--! @describe
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity SHA1_PART1 is
	port map(
				Clk		:	in	std_logic;	
				Rst_n	:	in	std_logic;
				Din		:	in	SHA1_DATA;
				Start	:	in	std_logic;

				Ready	:	out	std_logic;
				Done	:	out	std_logic;
				Dout	:	out	SHA1_DATA;
			);
end SHA1_PART1;

architecture  BEHAVOR of SHA1_PART1 is
	component W_GEN is
	port(
			Clk		:	in  	std_logic;
			Rst_n	:	in 		std_logic;
			Load	:	in 		std_logic;
			Din		: 	in		WORD_VECTOR(15 downto 0);
			Wout	: 	out		WORD_TYPE
		);
	end component;
	--------------------------------------------------------------------------
	-- 计算使用的5个参数
	--------------------------------------------------------------------------
	signal A		: 	std_logic_vector(31 downto 0);
	signal B		: 	std_logic_vector(31 downto 0);
	signal C		: 	std_logic_vector(31 downto 0);
	signal D		: 	std_logic_vector(31 downto 0);
	signal E		: 	std_logic_vector(31 downto 0);

	signal A_reg	: 	std_logic_vector(31 downto 0);
	signal B_reg	: 	std_logic_vector(31 downto 0);
	signal C_reg	: 	std_logic_vector(31 downto 0);
	signal D_reg	: 	std_logic_vector(31 downto 0);
	signal E_reg	: 	std_logic_vector(31 downto 0);

	--------------------------------------------------------------------------
	-- 每一次的中间计算结果
	--------------------------------------------------------------------------
	signal TEMP		: 	std_logic_vector(31 downto 0);
	--------------------------------------------------------------------------
	-- 函数电路结果寄存
	--------------------------------------------------------------------------
	signal F1		: 	std_logic_vector(31 downto 0);
	--------------------------------------------------------------------------
	-- 函数电路结果寄存
	--------------------------------------------------------------------------
	constant K1		: 	std_logic_vector(31 downto 0) := x"5A827999";
	--------------------------------------------------------------------------
	-- A循环左移5位寄存
	--------------------------------------------------------------------------
	signal S5A		: 	std_logic_vector(31 downto 0);
	--------------------------------------------------------------------------
	-- B循环左移30位寄存
	--------------------------------------------------------------------------
	signal S30B		: 	std_logic_vector(31 downto 0);

	-- 流程控制
	signal cnt 		:	integer;
	type CTL_STATES is (CTL_IDLE, CTL_CALC);
	signal state : CTL_STATES;
begin
	F1 	<=	(B_reg and C_reg) OR ((not B_reg) and D_reg);

	A 	<= Rotl(A_reg, 5) + F1 + E_reg + W + K1;
	B 	<= A_reg;
	C 	<= Rotl(B_reg, 30);
	D 	<= C_reg;
	E 	<= D_reg;

	U_CTL : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			cnt <= 0; state <= CTL_IDLE;
			Ready <= '1';
		elsif Clk'event and Clk = '1' then
			case state is
				when CTL_IDLE	=>
					Ready <= '1';
					cnt <= 0;
					if Start = '1' then
						state <= CTL_CALC;
					end if;
				when CTL_CALC	=>
					Ready <= '0';
					if cnt = 19 then
						cnt <= 0;
						Dout.digest_buff(159 dwonto 128) <= A_reg;
						Dout.digest_buff(128 dwonto 96) <= A_reg;
						Dout.digest_buff(95 dwonto 64) <= A_reg;
						Dout.digest_buff(63 dwonto 32) <= A_reg;
						Dout.digest_buff(31 dwonto 0) <= A_reg;
						state <= CTL_IDLE;
					else
						cnt <= cnt + 1;
						state <= CTL_CALC;
					end if;
				when others => 
			end case;
		end if;

	end process;
	U_UPDATE : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
		elsif Clk'event and Clk = '1' then
			if Start = '1' then
				A_reg <= Din.digest_buff(159 downto 128);
				B_reg <= Din.digest_buff(127 downto 96);
				C_reg <= Din.digest_buff(95 downto 64);
				D_reg <= Din.digest_buff(63 downto 32);
				E_reg <= Din.digest_buff(31 downto 0);
			else
				A_reg <= A;
				B_reg <= B;
				C_reg <= C;
				D_reg <= D;
				E_reg <= E;
			end if;
		end if;
	end process;

end BEHAVOR;
