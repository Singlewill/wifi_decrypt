-- TestBench Template 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
use ieee.std_logic_textio.all;
--USE ieee.fixed_pkg.all;
library std;
use std.textio.all;


ENTITY TB_WIFI_DECRYPT IS
END TB_WIFI_DECRYPT;

ARCHITECTURE behavior OF TB_WIFI_DECRYPT IS 
	component WIFI_DECRYPT 
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
	end component;

	constant Clk_period : time := 10 ns;
	signal Clk : std_logic := '0';
	signal rst_n : std_logic := '0';
	signal tx_pin: std_logic := '0';
	signal rx_pin: std_logic := '0';
	signal done : std_logic := '0';

	signal sd_cmd	:	std_logic;
	signal sd_clk 	:	std_logic;
	signal sd_cd	:	std_logic;
	signal sd_dat : std_logic_vector(3 downto 0);
	
begin
	U_WIFI : WIFI_DECRYPT 
	port map(
				Clk => Clk,	
				Rst_n => rst_n,

				sd_cmd => sd_cmd,
				sd_clk =>	sd_clk,
				sd_dat	=>	sd_dat,
				sd_cd =>sd_cd,
				Tx_pin => tx_pin
			);

	  -- Clock process definitions
	  Clk_process :process
	  begin
		  Clk <= '0';
		  wait for Clk_period/2;
		  Clk <= '1';
		  wait for Clk_period/2;
	  end process;

	process
	begin
		Rst_n <= '0';
		wait for 20 ns;
		Rst_n <= '1';
		wait;
	end process;

end behavior;

