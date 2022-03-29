library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity SHA1_FLOW is
end SHA1_FLOW;

architecture BEHAVOR of SHA1_FLOW is
begin
	--! U_0_*, Plantext = key XOR X"36"
	--! 	   DIGEST = DIG_INIT
	U_0_0	:	
	U_0_1	:	
	U_0_2	:	
	U_0_3	:	

	--! U_1_*, Plantext = SSID(补'1'和长度)
	--! 	   DIGEST 来自U_0计算结果
	U_1_0	:	
	U_1_1	:	
	U_1_2	:	
	U_1_3	:	

	--! U_2_*, Plantext = key XOR X"5C"
	--! 	   DIGEST = DIG_INIT
	U_2_0	:	
	U_2_1	:	
	U_2_2	:	
	U_2_3	:	

	--! U_3_*, Plantext = U_1输出
	--!		   DIGEST  = U_2输出
	U_3_0	:	
	U_3_1	:	
	U_3_2	:	
	U_3_3	:	
end BEHAVOR;
