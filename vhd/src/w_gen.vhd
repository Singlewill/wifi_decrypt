-----------------------------------------------------------------------------------
--         					w_gen.vhd
-- generate W value for sha1 calc, output new W value every clock        
--     
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.sha1_pkt.all;

entity W_GEN is
	port(
			Clk		:	in  	std_logic;
			Rst_n	:	in 		std_logic;
			Load	:	in 		std_logic;
			Din		:	--! @brief 512bit 原始数据数据输入
						WORD_VECTOR(15 downto 0);
			Wout	:	--! @brief W数据输出
						out		WORD_TYPE
		);
end W_GEN;


architecture BEHAVIOR of W_GEN is 
	signal 		w_hold	: 	WORD_TYPE;		--16个W缓存， 

	--------------------------------------------------------------------------
	-- w_tmp和w_gen实现:
	-- 		w_gen = W(t) = S1(W(t-3) XOR W(t-8) XOR W(t-14) XOR W(t-16))
	--------------------------------------------------------------------------
	signal 		w_tmp 	: 	WORD_TYPE;		
	signal 		w_gen 	: 	WORD_TYPE;	
begin
	
	w_gen <= w_tmp(30 downto 0) & w_tmp(31);
	w_tmp <= (w_hold(15) XOR w_hold(13) XOR w_hold(7) XOR w_hold(2)) ;

	Shfit : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			w_hold <=  (others => (others => '0'));		
		elsif Load = '1' then
			w_hold <= Din;
		elsif Clk'event and Clk = '1' then			
			w_hold <= w_hold(14 downto 0) & w_gen;
		else 
			NULL;

		end if;
	end process;
	Wout <= w_hold(15);

end BEHAVIOR;
	
