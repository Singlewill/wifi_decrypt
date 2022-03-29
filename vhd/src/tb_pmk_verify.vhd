LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.ALL;
use work.sha1_pkt.all;

ENTITY test IS
END test;

architecture BEHAVOR of test is
	component PMK_VERIFY
	port (
				Clk			:	in	std_logic;	
				Rst_n		:	in	std_logic;
				Start		:	in	std_logic;
				Pmk			:	in	std_logic_vector(255 downto 0);
				Passphrase 	:	in	std_logic_vector(511 downto 0);
				Key2_1		:	in	std_logic_vector(511 downto 0);
				Key2_2		:	in	std_logic_vector(511 downto 0);
				Key2_2_len	:	in	std_logic_vector(7 downto 0);
				Mac_nonce_1	:	--! 必须�?64字节
								in	std_logic_vector(511 downto 0);
				Mac_nonce_2	:	--! 必然�?35字节,后续计算会加�?个字节的counter
								in	std_logic_vector(511 downto 0);
				
				Done		:	out	std_logic;
				Ready		:	out	std_logic;
				Is_match	:	--! 结果是否正确，正�?="01",错取="10"
								out std_logic_vector(1 downto 0);
				Right_key	:	out	std_logic_vector(511 downto 0)
		 );
	end component;
	signal key2_1 : std_logic_vector(511 downto 0) := X"0103007502010a000000000000000000014c564ef1970b4dcfe90fbce75cac1899bf9a8370942ceb3f44cd824c410d2b5e000000000000000000000000000000";

	signal key2_2 : std_logic_vector(511 downto 0) := X"0000000000000000000000000000000000f8374767412ca60a82ec32b832d0e3ec001630140100000fac020100000fac040100000fac02000000000000000000";
	signal key2_2_len : std_logic_vector(7 downto 0) := conv_std_logic_vector(57, 8);
	signal mac_nonce_1 : std_logic_vector(511 downto 0) := X"5061697277697365206b657920657870616e73696f6e00803773f913e0f043478f63314c564ef1970b4dcfe90fbce75cac1899bf9a8370942ceb3f44cd824c41";
	signal mac_nonce_2 : std_logic_vector(511 downto 0) := X"0d2b5e9896a92396bf67ca4de53a3f345299a7d4d87e727418e1baa78d4f417ae7fa3d0000000000000000000000000000000000000000000000000000000000";
	signal pmk : std_logic_vector(255 downto 0) := X"9cdb45bcfbdd52b50e3f7e39c5e7a2648af63e9aca6162e91ae648c56631e520";


	signal passphrase : std_logic_vector(511 downto 0) := (others => '1');
	signal right_key :  std_logic_vector(511 downto 0);
	signal start : std_logic;
	signal done : std_logic;
	signal ready : std_logic;
	signal is_match : std_logic_vector(1 downto 0);

	signal clk : std_logic;
	signal rst: std_logic;
begin
	U_PMK_VERIFY : PMK_VERIFY
	port map(
				Clk				=>	clk,
				Rst_n			=>	rst,
				Start			=>	start,
				Pmk				=>	pmk,
				Passphrase 		=>	passphrase,
				Key2_1			=> key2_1,
				Key2_2			=> key2_2,
				Key2_2_len		=> key2_2_len,
				Mac_nonce_1		=>	mac_nonce_1,
				Mac_nonce_2		=> mac_nonce_2,
				Done			=> done,
				Ready			=> ready,
				Is_match		=> is_match,
				Right_key		=> right_key
			
			);

	U_clk : process
	begin
		clk <= '0';
		wait for 5 ns;
		clk <= '1';
		wait for 5 ns;
	end process;

	U_RST : process
	begin
		rst <= '0';
		wait for 100 ns;
		rst <= '1';
		wait;
	end process;
	U_MAIN : process
	begin
		start <= '0';
		wait for 150 ns;
		start <= '1';
		wait for 10 ns;
		start <= '0';
		
		wait until done = '1';
		
		start <= '1';
        wait for 10 ns;
        start <= '0';
        
        wait until done = '1';
		wait;

	end process;
end BEHAVOR;



