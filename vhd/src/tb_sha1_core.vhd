--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:09:52 06/02/2017
-- Design Name:   
-- Module Name:   /home/ll/workdir/fpga_test/VHDL/sha1_core/project/sha1_test/tb_sha1_core.vhd
-- Project Name:  sha1_test
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: SHA1_CORE
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- unsigned for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.sha1_pkt.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_sha1_core IS
END tb_sha1_core;
 
ARCHITECTURE behavior OF tb_sha1_core IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT SHA1_CORE
    PORT(
			Clk				: 	in	std_logic;	
			Rst_n			: 	in	std_logic;
			Clr_n			: 	in	std_logic;
			Plaintext		: 	in	std_logic_vector(511 downto 0);
			Plaintext_len	:	in 	std_logic_vector(7 downto 0);
			Start			: 	in	std_logic;
			I_last			: 	in 	std_logic;
			O_valid			:	out std_logic;
			Digest_out		: 	out std_logic_vector(159 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal Clk : std_logic := '0';
   signal Rst_n : std_logic := '0';
   signal Start : std_logic := '0';

 	--Outputs
   signal Done : std_logic;
   signal Digest_out : std_logic_vector(159 downto 0);
   -- Clock period definitions
   constant Clk_period : time := 10 ns;


	signal 	y_source			:	std_logic_vector(511 downto 0);

	type STATES is (RESET,LOAD2, LOAD, CALC, LL_DONE);
	signal state : STATES := RESET;
	signal last : std_logic;
	signal clr_n: std_logic;
	signal y_len : std_logic_vector(7 downto 0);
 
BEGIN

   -- Instantiate the Unit Under Test (UUT)
	uut: SHA1_CORE PORT MAP (
								Clk  => Clk,
								Rst_n  => Rst_n,
								Clr_n	=> clr_n,
								Plaintext => y_source,
								Plaintext_len => y_len,
								Start => Start,
								I_last => last,
								O_valid => Done,
								Digest_out => Digest_out
							);

   -- Clock process definitions
	Clk_process :process
	begin
		Clk <= '0';
		wait for Clk_period/2;
		Clk <= '1';
		wait for Clk_period/2;
	end process;






--	 测试版本一
	ustim_proc: process
		variable y_tmp : std_logic_vector(511 downto 0);
	begin		

		Rst_n <= '0';
		clr_n <= '0';
		-- hold reset state for 100 ns.
		wait for 100 ns;	
		Rst_n <= '1';
		clr_n <= '1';
		last <= '0';

		wait for 90 ns;	
		
		--! 第一次64字节明文输入
		y_tmp := X"30313233343536373031323334353637303132333435363730313233343536373031323334353637303132333435363730313233343536373031323334353637";
		y_source <= y_tmp;
		y_len <= conv_std_logic_vector(64, 8);

		Start <= '1';
		--last <= '1';
		wait until Done = '1';
		Start <= '0';
	 	wait until (Clk'event and Clk = '1');
		wait for 10 ns;
		--! 第2次64字节明文输入
		y_tmp := X"30313233343536373031323334353637303132333435363730313233343536373031323334353637303132333435363730313233343536373031323334353637";
		y_source <= y_tmp;
		y_len <= conv_std_logic_vector(64, 8);

		Start <= '1';
		--last <= '1';
		wait until Done = '1';
		Start <= '0';
	 	wait until (Clk'event and Clk = '1');
		wait for 10 ns;
		
		--! 第三次
		y_tmp := X"6162636462636465636465666465666765666768666768696768696a68696a6b696a6b6c6a6b6c6d6b6c6d6e6c6d6e6f6d6e6f706e6f707155" & conv_std_logic_vector(0, 56);
		y_source <= y_tmp;
		y_len <= conv_std_logic_vector(57, 8);
		Start <= '1';
		last <= '1';
		wait until Done = '1';
		Start <= '0';
		wait until (Clk'event and Clk = '1');
		wait for 10 ns;

--     --! 第三次
--         y_tmp := X"616263" & conv_std_logic_vector(0, 488);
--			y_source <= y_tmp;
--         y_len <= conv_std_logic_vector(3, 8);
--         Start <= '1';
--         last <= '1';
--         wait until Done = '1';
--         Start <= '0';           
--	wait until (Clk'event and Clk = '1');			
--         wait for 10 ns;


		wait;
	end process;


END;
