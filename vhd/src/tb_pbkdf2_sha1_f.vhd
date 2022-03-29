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

  use work.sha1_pkt.all;

  ENTITY TB_PBKDF2_SHA1_F IS
  END TB_PBKDF2_SHA1_F;

  ARCHITECTURE behavior OF TB_PBKDF2_SHA1_F IS 

  -- Component Declaration
          COMPONENT PBKDF2_SHA1_F
          PORT(
				Clk				:	in 	std_logic; 
				Rst_n			:	in 	std_logic;
				Start			:	in	std_logic;
				Passphrase		:	in	std_logic_vector(511 downto 0);
				Passphrase_len	:	in	std_logic_vector(31 downto 0);
				Ssid			:	in	std_logic_vector(511 downto 0);
				Ssid_len		:	in 	std_logic_vector(31 downto 0);
				Counter			:	--! @brief counter计数,4字节，小端字节序	
									in 	std_logic_vector(31 downto 0);

				Digest			:	out std_logic_vector(159 downto 0);
				Done			:	out std_logic
                  );
          END COMPONENT;


          SIGNAL Clk :  std_logic;
          SIGNAL Rst_n:  std_logic;
		   -- Clock period definitions
		   constant Clk_period : time := 10 ns;


		  -- input 
          SIGNAL start :  std_logic;
		  constant passphrase_len	: std_logic_vector(31 downto 0) := conv_std_logic_vector(64, 32);
		  signal passphrase_input	: std_logic_vector(511 downto 0);

		  constant ssid_len : std_logic_vector(31 downto 0) := conv_std_logic_vector(48, 32);
		  signal ssid_input : std_logic_vector(511 downto 0);


		  signal counter : std_logic_vector(31 downto 0) := conv_std_logic_vector(0, 24) & "00000001";


		  -- output 
		  signal done : std_logic;
		  signal digest : std_logic_vector(159 downto 0);

		  
		
		  
			 
  BEGIN

          uut:PBKDF2_SHA1_F PORT MAP(
				Clk				=> Clk,
				Rst_n			=> Rst_n,
				Start			=> start,
				Passphrase		=> passphrase_input,
				Passphrase_len	=> passphrase_len,
				Ssid			=> ssid_input,
				Ssid_len		=> ssid_len,
				Counter			=> counter,
				Digest			=> digest,
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

	   sim_proc : process
			file file_read : text;
			variable fstatus : FILE_OPEN_STATUS;
		   	variable line_read : LINE;
			
			--! 密码12345678长度为64,ssid TPLINK长度为48
			variable passphrase : std_logic_vector(63  downto 0);
			variable ssid	:	std_logic_vector(47 downto 0);
			
	   begin
			file_open(fstatus, file_read, "config.txt", read_mode);
			readline(file_read, line_read);
			hread(line_read, ssid);
			readline(file_read, line_read);
			hread(line_read, passphrase);
			file_close(file_read);

		   Rst_n <= '0';
		   wait for 50 ns;
		   Rst_n <= '1';
		   wait for 20 ns;
			passphrase_input <= passphrase & conv_std_logic_vector(0, 448);
			ssid_input <= ssid & conv_std_logic_vector(0, 464);
		   	start <= '1';
		   	wait for 20 ns;
		   	start <= '0';
		   wait until done = '1';
		   wait;
	   end process;
	   

  END;
