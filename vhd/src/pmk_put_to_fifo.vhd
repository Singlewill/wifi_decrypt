------------------------------------------------------------------------------
--! 	@file		pmk_put_to_fifo.vhd
--! 	@function	将众多pbkdf2模块计算出的pmk连同key组成一一对应的数据，
--!					放入pmk_fifo
--!		@version	
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

use work.sha1_pkt.all;

entity PMK_PUT_TO_FIFO is
	port (
			Clk			:	in		std_logic; 
			Rst_n		:	in		std_logic;
			Passphrase	:	in		PASSPHRASE_VECTOR;
			Pmk			:	in		PMK_VECTOR;
			In_valid	:	in		std_logic;


			Data_out	:	out 	std_logic_vector(767 downto 0);
			Data_valid	:	out		std_logic;
			Data_out_allow	:	in	std_logic
		 );
end PMK_PUT_TO_FIFO;


architecture BEHAVOR of PMK_PUT_TO_FIFO is
	type 	OUT_STATES  is (OUT_IDLE, OUT_SEND, OUT_OVER);
	signal out_state : OUT_STATES;
	signal index : integer range 0 to PBKDF2_NUM;
	signal data_out_valid : std_logic;
begin
	U_DATA_OUT : process(clk, Rst_n)
	begin
		if Rst_n = '0' then
			index <= 0;
			data_out_valid <= '0';
			out_state <=  OUT_IDLE;
		elsif clk'event and clk = '1' then
			case out_state is
				when OUT_IDLE =>
					if In_valid = '1' and Data_out_allow = '1' then
						index <= 0;
						out_state <= OUT_SEND;
					else
						out_state <= OUT_IDLE;
					end if;
				when OUT_SEND =>
					data_out <= Passphrase(index) & Pmk(index);
					if data_out_allow = '1' then
						data_out_valid <= '1';
					else
						data_out_valid <= '0';
					end if;
					if index = PBKDF2_NUM - 1 then
						index <= 0;
						out_state <= OUT_OVER;
					elsif data_out_allow = '1' then
						index <=  index + 1;
						out_state <= OUT_SEND;
					--! data_out_allow = 0　时,index暂停计数
					else
						index <= index;
						out_state <= OUT_SEND;
					end if;
				when OUT_OVER =>
					data_out_valid <= '0';
					--data_out <= (others => '0');
					out_state <= OUT_IDLE;
				when others =>
			end case;
		end if;
	end process;
	Data_valid <= data_out_valid;
end BEHAVOR;
