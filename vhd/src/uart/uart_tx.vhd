------------------------------------------------------------------------------ 
-- 							uart_tx.vhd
--	串口的数据发送模块
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
--use work.sha1_pkt.all;


entity UART_TX is 
	port(

			Clk		: in	std_logic;	
			Rst_n	:	in	std_logic;
			Enable	:	in	std_logic;
			Tx_pin	:	out	std_logic;
			Tx_buff	:	in	std_logic_vector(7 downto 0);
			Done 	:	out std_logic
		);
end UART_TX;

architecture BEHAVIOR of UART_TX is
	type TRANSMIT_STATES is (X_IDLE, X_START, X_WAIT, X_SHIFT, X_STOP);
	signal transmit_state : TRANSMIT_STATES := X_IDLE; 
	signal done_tmp : std_logic;
begin


	process(Clk, Rst_n)
		--! 16个时钟发送一个bit,cout用于计数
		variable count : std_logic_vector(4 downto 0);
		--! 已发送的bit计数
		variable bitcnt_t: INTEGER range 0 to 8 := 0; 

		variable tx_tmp: std_logic;
	begin
		if Rst_n = '0' then
			transmit_state <= X_IDLE;
			tx_tmp := '1';
			count := "00000";
			bitcnt_t := 0;
			Done <= '0';
		elsif Clk'event and Clk = '1' then
			case transmit_state is
				when X_IDLE =>
						
						
						Done <= '0';

					if Enable  = '1'  then
						count := "00000";
						bitcnt_t := 0;
						transmit_state <= X_START;
					else
						transmit_state <= X_IDLE;
					end if;
				--! 发送16个周期的低电平, start信号
				when X_START =>	
					if count = "01111" then
						transmit_state <= X_SHIFT; 
						count := "00000";
					else
						count := count + 1;
						tx_tmp := '0';		
						transmit_state <= X_START;
					end if;
				--! 在X_SHFIT状态改变状态后持续15个时钟
				when X_WAIT =>	
					if count >= "01110" then
						if bitcnt_t = 8 then
							transmit_state <= X_STOP;
							bitcnt_t := 0;
							count := "00000";
						else 
							transmit_state <= X_SHIFT;
						end if;
						count := "00000";
					else		
						count := count + 1;
						transmit_state <= X_WAIT;
					end if;
				when X_SHIFT => --send bit
					tx_tmp := Tx_buff(bitcnt_t);
					bitcnt_t := bitcnt_t + 1;
					transmit_state <= X_WAIT;

				--! 发送16个周期的'1', stop信号
				--! 之后按需求准备下一次发送
				when X_STOP => --send stop bit 
					if count >= "01111" then
						Done <= '1';							
						if Enable  ='0' then
							
							count := "00000";
							transmit_state <= X_IDLE;
						else 				
							count := count;
							transmit_state <= X_STOP;
						end if;
					else
						count := count + 1;
						tx_tmp := '1';		
						transmit_state <= X_STOP;
					end if;
				when others =>
					transmit_state <= X_IDLE;
			end case;
		end if;
		Tx_pin <= tx_tmp;
	end process;
end BEHAVIOR;
