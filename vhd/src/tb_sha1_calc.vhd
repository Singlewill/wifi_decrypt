--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   08:03:55 06/07/2017
-- Design Name:   
-- Module Name:   /home/ll/workdir/fpga_test/VHDL/sha1_core/tb_sha1_calc.vhd
-- Project Name:  sha1_core
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: SHA1_CALC
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_sha1_calc IS
END tb_sha1_calc;
 
ARCHITECTURE behavior OF tb_sha1_calc IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT SHA1_CALC
    PORT(
         Enable : IN  std_logic;
         W : IN  std_logic_vector(31 downto 0);
         Calc_cnt : IN  std_logic_vector(6 downto 0);
         Din : IN  std_logic_vector(159 downto 0);
         Dout : OUT  std_logic_vector(159 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal Enable : std_logic := '0';
   signal W : std_logic_vector(31 downto 0) := (others => '0');
   signal Calc_cnt : std_logic_vector(6 downto 0) := (others => '0');
   signal Din : std_logic_vector(159 downto 0) := (others => '0');

 	--Outputs
   signal Dout : std_logic_vector(159 downto 0);
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
   constant <clock>_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: SHA1_CALC PORT MAP (
          Enable => Enable,
          W => W,
          Calc_cnt => Calc_cnt,
          Din => Din,
          Dout => Dout
        );

   -- Clock process definitions
   <clock>_process :process
   begin
		<clock> <= '0';
		wait for <clock>_period/2;
		<clock> <= '1';
		wait for <clock>_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for <clock>_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
