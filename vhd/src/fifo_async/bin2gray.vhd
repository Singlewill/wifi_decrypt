------------------------------------------------------------------------------
--! @file		bin2gray.vhd
--! @function	二进制转格雷码
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity BIN2GRAY is
	generic (constant DATA_WIDTH : integer := 8);
	port (
			Din		:	in	std_logic_vector(DATA_WIDTH -1 downto 0) ;
			Dout	:	out	std_logic_vector(DATA_WIDTH -1 downto 0) 
		 );
end BIN2GRAY;
architecture BEHAVOR of BIN2GRAY is
    --signal tmp : std_logic_vector(DATA_WIDTH - 1 downto 0);
begin
    --tmp <= '0' & Din(DATA_WIDTH - 1 downto 1);
	--Dout <= tmp XOR Din;
	Dout(DATA_WIDTH - 1) <= Din(DATA_WIDTH - 1);
	G_OUT : for i in DATA_WIDTH - 2 downto 0 generate
		Dout(i) <= Din(i + 1) XOR Din(i);
	end generate;
end BEHAVOR;

