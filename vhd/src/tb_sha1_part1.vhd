library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity TB_SHA1_PART1 is
end TB_SHA1_PART1;
architecture BEHAVOR of TB_SHA1_PART1 is
	component SHA1_PART1
	port map(
				Clk		:	in	std_logic;	
				Rst_n	:	in	std_logic;
				Din		:	in	SHA1_DATA;
				Start	:	in	std_logic;

				Ready	:	out	std_logic;
				Done	:	out	std_logic;
				Dout	:	out	std_logic;
			);
	end component;


	signal clk	:	std_logic;
	signal rst	:	std_logic;
	signal start	:	std_logic;
	signal ready:	std_logic;
	signal done:	std_logic;

	signal din	:	SHA1_DATA;
	signal dout	:	SHA1_DATA;
begin
	U_SHA1_PART1 : SHA1_PART1
	port map(
				Clk		=>	clk,	
				Rst_n	=>	rst,
				Din		=>	din,
				Start	=>	start,
				Ready	=>	ready,
				Done	=>	done,
				Dout	=>	dout

			)

	U_CLK : process
	begin
		clk <= '1';
		wait for 5 ns;

		clk <= '0';
		wait for 5 ns;
	end if;

	U_RST : process
	begin
		rst <= '0';
		wait for 100 ns;
		rst <= '1';
		wait for 20 ns;
		din.digest_buff <= H0_INIT & H1_INIT & H2_INIT & H3_INIT & H4_INIT;
		start <= '1';
		wait;
	end process;
end BEHAVOR;
