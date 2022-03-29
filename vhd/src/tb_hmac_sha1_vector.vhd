--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:14:50 06/15/2017
-- Design Name:   
-- Module Name:   /home/ll/workdir/fpga_test/VHDL/sha1_core/tb_hmac_sha1_vector.vhd
-- Project Name:  sha1_core
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: HMAC_SHA1_VECTOR
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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.sha1_pkt.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_hmac_sha1_vector IS
END tb_hmac_sha1_vector;
 
ARCHITECTURE behavior OF tb_hmac_sha1_vector IS 
 
    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT HMAC_SHA1_VECTOR
	 	generic (ITEMS : integer);
    PORT(
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
    END COMPONENT;
    

   --Inputs
   signal Clk : std_logic := '0';
   signal Rst_n : std_logic := '0';
   signal Start : std_logic := '0';
   signal Key : 	std_logic_vector(511 downto 0);
   signal Addr 		: HMAC_DATA(1 downto 0) := (others => (others => '0'));
   signal Addr_len : HMAC_DATA_LEN(1 downto 0) := (others => (others => '0'));

 	--Outputs
   signal ll_digest_tmp : std_logic_vector(159 downto 0);
   signal Done : std_logic;

   -- Clock period definitions
   constant Clk_period : time := 10 ns;

   -- 测试数据

   -- key(pmk, 32字节)
   constant ll_key : std_logic_vector(255 downto 0) := X"992194d7a6158009bfa25773108291642f28a0c32a31ab2556a15dee97ef0dbb";

   constant ll_kck : std_logic_vector(127 downto 0) := X"1783ef7fb116a47b21d7befc7b157050";
   
   --key2的第一部分，　完整64字节
   constant ll_key2_1 : std_logic_vector(511 downto 0) := X"0203007502010a00100000000000000001f5b4d6d2a4b5da5069404a07281e40f3079de18bf3a1ce8674345e5a8694cb5f000000000000000000000000000000";

   --key2的第二部分，57字节
   constant ll_key2_2_tmp : std_logic_vector(455 downto 0) := X"000000000000000000000000000000000000000000000000000000000000000000001630140100000fac020100000fac040100000fac020c00";

   constant ll_key2_2 : std_logic_vector(511 downto 0) := ll_key2_2_tmp & conv_std_logic_vector(0, 56);

   type STATES  is (RESET, LOAD, LOAD_OFF, CALC, OVER);
   signal current_state : STATES := RESET;
   signal ll_last : std_logic_vector(159 downto 0);


 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: HMAC_SHA1_VECTOR 
   generic map (ITEMS => 2 )
   PORT MAP (
          Clk => Clk,
          Rst_n => Rst_n,
          Start => Start,
          Key => Key,
          Addr => Addr,
          Addr_len => Addr_len,
          Mac => ll_digest_tmp,
          Done => Done
        );
		  


   -- Clock process definitions
   Clk_process :process
   begin
		Clk <= '0';
		wait for Clk_period/2;
		Clk <= '1';
		wait for Clk_period/2;
   end process;
 

   -- Stimulus process
--   stim_proc: process
--   begin		
--	   Rst_n <= '0';
--
--      -- hold reset state for 100 ns.
--      wait for 50 ns;	
--	  Rst_n <= '1';
--	  -----------------------------------------------
--	Key(511 downto  384) <= ll_kck(127 downto 0);
--	 Key_len(31 downto 0) <= conv_std_logic_vector(16*8, 32);
--
--	 Addr(0) <=  ll_key2_1;
--	 Addr_len(0) <= conv_std_logic_vector(64*8, 32);
--
--	 Addr(1) <= ll_key2_2 & conv_std_logic_vector(0, 56);
--	 Addr_len(1) <= conv_std_logic_vector(57*8, 32);
--
--	 Start  <= '1';
--      wait for 20 ns;	
--	 Start  <= '0';
--      wait until Done = '1';
--
--	  wait ;	
----	  	 Addr(2) <= ll_key2_2 & conv_std_logic_vector(0, 56);
----	 Addr_len(2) <= conv_std_logic_vector(57*8, 32);
----	 	Start  <= '1';
----      wait for 20 ns;	
----	 Start  <= '0';
----      wait until Done = '1';
--      -- insert stimulus here 
--
--
--   end process;

	U_STATE : process(Clk)
	begin

		if Clk'event and Clk = '1' then
			case current_state is 
				when RESET => 
					Rst_n <= '0';

					current_state <= LOAD;
				when LOAD =>
					Rst_n <= '1';
					Key <= ll_kck & conv_std_logic_vector(0, 384);

					Addr(0) <= ll_key2_1;
					Addr_len(0) <= conv_std_logic_vector(64, 8);

					Addr(1) <= ll_key2_2;
					Addr_len(1) <= conv_std_logic_vector(57, 8);

					Start <= '1';
					current_state <= LOAD_OFF;
				when LOAD_OFF =>
					Start <= '0';
					current_state <= CALC;
				when CALC =>
					if Done = '1' then
						ll_last <= ll_digest_tmp;
						current_state <= OVER;
					else
						current_state <= CALC;
					end if;
				when OVER => 				
			end case;
		end if;
	end process;
   




END;
