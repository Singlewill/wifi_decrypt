
-- TestBench Template 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


use ieee.std_logic_textio.all;
	--USE ieee.fixed_pkg.all;
library std;
use std.textio.all;

use work.sha1_pkt.all;

ENTITY TB_PBKDF2_SHA1 IS
END TB_PBKDF2_SHA1;

ARCHITECTURE behavior OF TB_PBKDF2_SHA1 IS 
	component PBKDF2_SHA1 is
	port(
			Clk				:	in 	std_logic; 
			Rst_n			:	in 	std_logic;
			Start			:	in	std_logic;
			Passphrase		:	in	std_logic_vector(511 downto 0);
			Ssid			:	in	std_logic_vector(511 downto 0);
			Ssid2			:	in	std_logic_vector(511 downto 0);
			Ssid_len		:	in 	std_logic_vector(7 downto 0);
			Pmk				:	--! @brief 32Bytes输出
								out	std_logic_vector(255 downto 0);
			Done			:	out std_logic
		
		);
		end component;
		          SIGNAL Clk :  std_logic;
          SIGNAL Rst_n:  std_logic;
   		constant Clk_period : time := 10 ns;

		  -- input 
          SIGNAL start :  std_logic;
		  signal passphrase_input	: std_logic_vector(511 downto 0);

		  constant ssid_len : std_logic_vector(7 downto 0) := conv_std_logic_vector(10, 8);
		  signal ssid_input1 : std_logic_vector(511 downto 0);
		  signal ssid_input2: std_logic_vector(511 downto 0);
		  -- output 
		  signal done : std_logic;
		  signal pmk: std_logic_vector(255 downto 0);

		  type M_PBKDF2_STATE is (PBKDF2_WAIT, PBKDF2_WAIT2, PBKDF2_CALC, PBKDF2_PRINT1, PBKDF2_PRINT2, PBKDF2_LAST);
		signal 	pbkdf2_state : M_PBKDF2_STATE := PBKDF2_WAIT;

begin
	U_PBKDF2_SH1 : PBKDF2_SHA1
	port map(
				Clk				=> Clk,
				Rst_n			=> Rst_n,
				Start			=> start,
				Passphrase		=> passphrase_input,
				Ssid			=> ssid_input1,
				Ssid2			=> ssid_input2,
				Ssid_len		=> ssid_len,
				Pmk				=> pmk,
				Done			=> done
			
			);

	   -- Clock process definitions
	   Clk_process :process
	   begin
			Clk <= '0';
			wait for Clk_period/2;
			Clk <= '1';
			wait for Clk_period/2;
	   end process;
		
		
	   Rst_process :process
	   begin
			Rst_n <= '0';
			wait for 50 ns;
			Rst_n <= '1';
			wait ;
	   end process;

	P_PBKDF2 : process(Clk, Rst_n)
		variable cnt : integer range 0 to 511;
	begin
		if Rst_n = '0' then
			pbkdf2_state <= PBKDF2_WAIT;
		elsif Clk'event and Clk = '1' then
			case pbkdf2_state is 
				when PBKDF2_WAIT =>
				ssid_input1 <= X"54504C494E4B00000001" & conv_std_logic_vector(0, 432);
				ssid_input2 <= X"54504C494E4B00000002" & conv_std_logic_vector(0, 432);
				--ssid_len <= conv_std_logic_vector(48, 32);
				passphrase_input <= X"3132333435363738" & conv_std_logic_vector(0, 448);
				--passphrase_len <= conv_std_logic_vector(64, 32);
				start <= '1';
				pbkdf2_state <= PBKDF2_WAIT2;
--					if ssid_len /= conv_std_logic_vector(0, 32) and passphrase_len /=  conv_std_logic_vector(0, 32) then
--						pbkdf2_enable <= '1';
--						pbkdf2_state <= PBKDF2_WAIT2;
--					else
--						pbkdf2_state <= PBKDF2_WAIT;
--					end if;
				when PBKDF2_WAIT2 =>
					start <= '0';
					pbkdf2_state <= PBKDF2_CALC;

				when PBKDF2_CALC=>
					if done = '1' then
						cnt := 0;
						pbkdf2_state <= PBKDF2_PRINT1;
					else
						pbkdf2_state <= PBKDF2_CALC;
					end if;
				when PBKDF2_PRINT1 =>
			
				when PBKDF2_PRINT2 =>

				when PBKDF2_LAST=>
				end case;
		end if;
	end process;















--	   sim_proc : process
--			file file_read : text;
--			variable fstatus : FILE_OPEN_STATUS;
--		   	variable line_read : LINE;
--			
--			--! 密码12345678长度为64,ssid TPLINK长度为48
--			variable passphrase : std_logic_vector(63  downto 0);
--			variable ssid	:	std_logic_vector(47 downto 0);
--			
--	   begin
--			file_open(fstatus, file_read, "config.txt", read_mode);
--			readline(file_read, line_read);
--			hread(line_read, ssid);
--			readline(file_read, line_read);
--			hread(line_read, passphrase);
--			file_close(file_read);
--
--		   Rst_n <= '0';
--		   wait for 50 ns;
--		   Rst_n <= '1';
--		   wait for 20 ns;
--			passphrase_input <= passphrase & conv_std_logic_vector(0, 448);
--			ssid_input <= ssid & conv_std_logic_vector(0, 464);
--		   	start <= '1';
--		   	wait for 20 ns;
--		   	start <= '0';
--		   wait until done = '1';
--		   wait;
--	   end process;




end behavior;
