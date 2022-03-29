
------------------------------------------------------------------------------ 
-- 							uart_rx.vhd
--	串口的数据接收模块,接收一行数据
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity UART_RX is 
	port(
			Clk			: 	in	std_logic;	
			Rst_n		:	in	std_logic;
			Enable		: 	in	std_logic;
			Rx_pin		:	in	std_logic;
			Rx_buff		:	out std_logic_vector(511 downto 0);
			Rx_len		:	out std_logic_vector(7 downto 0);
			Rx_TAG		: 	out std_logic_vector(2 downto 0);
			Done	:	out std_logic

		);
end UART_RX;

architecture BEHAVIOR of UART_RX is
	type RECIEVE_STATES is (R_START, R_CENTER, R_WAIT, R_SAMPLE, R_STOP);
	signal current_state : RECIEVE_STATES := R_START;

	--! 接受的3三个状态
	--! 1, 接收第一个字节，包含7bit TAG, 3bit类型
	--! 2, 接收第二个字节，包含数据段长度(单位字节)
	--! 3, 接收剩余数据
	signal rx_stage : std_logic_vector(1 downto 0);

	signal rRx_len : std_logic_vector(7 downto 0);
begin
	U_STATE : process(Clk, Rst_n, Enable)
		--! 接收的bit计数
		variable bitcnt_r : integer range 0 to 10 := 0; 
		--! 输出缓存
		variable recieve_buff_tmp : std_logic_vector(7 downto 0);
		--! 16个时钟周期接受一位,count用于时钟计数
		variable count : std_logic_vector(4 downto 0);
		variable byte_cnt : integer range 0 to 512;
		variable recieve_bit : std_logic_vector(9 downto 0);
	begin
		if Rst_n = '0' or Enable = '0' then
			Rx_buff <= (others => '0');
			bitcnt_r := 0;
			count := "00000";
			current_state <= R_START;
			Done <= '0';


			rx_stage <= (others => '0');
			byte_cnt := 0;



		elsif Clk'event and Clk = '1' then
				case current_state is
					when R_START =>
						--! 检测到低电平，并且Rx使能,开始检测是否噪声
						if Rx_pin = '0' then	
							Done <= '0';
							bitcnt_r := 0;
							count := "00000";
							current_state <= R_CENTER;
						else 
							current_state <= R_START;
						end if;
					when R_CENTER =>		
						if Rx_pin = '0' then
							--! 低电平持续了8个时钟周期，非噪声
							if count = "00100" then	
								current_state <= R_WAIT;
								count := "00000";
							else 
								count := count + 1;
								current_state <= R_CENTER;
							end if;
						--! 低电平为噪声
						else	
							current_state <= R_START;
						end if;
					--! 等待15个时钟周期，在第16个周期采样
					when R_WAIT =>
						if count >= "01110" then  
							--!已经接收了8bit, 则当前是停止位
							if bitcnt_r = 8 then	
								current_state <= R_STOP;
							else
								current_state  <= R_SAMPLE;
							end if;
							count := "00000";
						else 
							count := count + 1;
							current_state <= R_WAIT;
						end if;
					when R_SAMPLE =>	
						recieve_buff_tmp(bitcnt_r) := Rx_pin;
						bitcnt_r := bitcnt_r + 1;
						current_state <= R_WAIT;
					--! 直接准备接收下一组数据，　等个毛线 !!
					when R_STOP =>	
						--! 第一阶段,检查TAG以及类型是否符合范围
						if rx_stage = "00" and recieve_buff_tmp(7 downto 3) = "11100" then
							Rx_TAG <= recieve_buff_tmp(2 downto 0);
							rx_stage <= "01";
						--! 第二阶段，检查
						elsif rx_stage = "01" then
							
							byte_cnt := 0;
							if recieve_buff_tmp <= conv_std_logic_vector(64, 8) then
								Rx_buff <= (others => '0');
								rRx_len <= recieve_buff_tmp;
								rx_stage <= "10";
							else
								rx_stage <= "00";
							end if;
						--! 第三阶段，接收数据到Rx_buff
						elsif rx_stage = "10" then
							Rx_buff((Rx_buff'length -  byte_cnt * 8 - 1) downto (Rx_buff'length - byte_cnt * 8 - 8)) <= recieve_buff_tmp;
        					byte_cnt := byte_cnt + 1;
							if byte_cnt = conv_integer(rRx_len)  then
								rx_stage <= "00";
								Rx_len <= rRx_len;
								Done <= '1';
							end if;
						end if;

							
						current_state <= R_START;
					when others =>
				end case;
		end if;	--if Rst_n = '0'

	
		

	end process;
end BEHAVIOR;
