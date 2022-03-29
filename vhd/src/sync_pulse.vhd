library IEEE;
use ieee.std_logic_1164.all;

entity SYNC_PULSE is
	port (
			Clk_a 		: in std_logic; 
			Clk_b 		: in std_logic;
			Rst_n		:	in std_logic;
			Pulse_a_in 	: in std_logic;
			Pulse_b_out : out std_logic
		 );
end SYNC_PULSE;


architecture BEHAVOR of SYNC_PULSE is
	signal	signal_a	: std_logic;
	signal	signal_b 	: std_logic;
	signal	signal_b_r1 : std_logic;
	signal	signal_b_r2 : std_logic;
	signal	signal_b_a1	: std_logic;
	signal	signal_b_a2	: std_logic;
begin
	--在时钟域clk_a下，生成展宽信号signal_a
	process(Clk_a, Rst_n)
	begin
		if Clk_a'event and Clk_a = '1' then
			if Rst_n = '0' then
				signal_a <= '0';
			else
				--检测到到输入信号 pulse_a_in被拉高，则拉高signal_a
				if Pulse_a_in = '1' then
					signal_a <= '1';
				-- 检测到signal_b1_a2 被拉高 ，则拉低signal_a
				elsif signal_b_a2 = '1' then
					signal_a <= '0';
				end if;
			end if;
		end if;
	end process;


	--在时钟域clk_b下，采集signal_a，生成signal_b
	process(Clk_b, Rst_n)
	begin
		if Clk_b'event and Clk_b = '1' then
			if Rst_n = '0' then
				signal_b <= '0';
			else
				signal_b <= signal_a;
			end if;
		end if;
	end process;


	--多级触发器处理
	process(Clk_b, Rst_n)
	begin
		if Clk_b'event and Clk_b = '1' then
			if Rst_n = '0' then
				signal_b_r1 <= '0';
				signal_b_r2 <= '0';
			else
				signal_b_r1 <= signal_b;	 --对signal_b打两拍
				signal_b_r2 <= signal_b_r1;
			end if;
		end if;
	end process;

	--在时钟域clk_a下，采集signal_b_r1，用于反馈来拉低展宽信号signal_a
	process(Clk_a, Rst_n)
	begin
		if Clk_a'event and Clk_a = '1' then
			if Rst_n = '0' then
				signal_b_a1 <= '0';
				signal_b_a2 <= '0';
			else
				--对signal_b_r1打两拍，因为同样涉及到跨时钟域
				signal_b_a1 <= signal_b_r1;
				signal_b_a2 <= signal_b_a1;
			end if;
		end if;
	end process;


	Pulse_b_out <= '1' when signal_b_r1 = '1' and signal_b_r2 = '0' else
				   '0';



end BEHAVOR;

