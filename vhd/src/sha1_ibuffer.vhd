------------------------------------------------------------------------------
---							sha1_ibuffer.vhd
--!		@function		sha1_core缓冲处理,包括补'1'和补长度,每个时钟周期输出
--!						32bit给后续计算
--!		@version
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.sha1_pkt.all;



entity SHA1_IBUFFER is
	port (
			Clk					:	in	std_logic; 
			Rst_n				:	--! 异步复位	
									in	std_logic;
			Clr_n					:	--! 同步复位	
									in 	std_logic;
			I_valid				:	in	std_logic;
			I_last				:	in	std_logic;
			I_data				: 	--! 明文输入	
									in	std_logic_vector(511 downto 0);
			I_datalen			:	in 	std_logic_vector(7 downto 0);
			I_next				:	in 	std_logic;
			O_valid				:  	--! 输出有效
									out std_logic;
			Text_out			:	out std_logic_vector(31 downto 0);
			O_last				:	out std_logic
		 ) ;
end SHA1_IBUFFER;

architecture BEHAVIOR of SHA1_IBUFFER is 
	---------------------------------------------------------------------------
	--! 第一级处理中间信号
	---------------------------------------------------------------------------
	type SYMBOL_STATES is (SYMBOL_IDLE, SYMBOL_OUT, SYMBOL_WAIT, SYMBOL_UNUSED);
	signal symbol_cur : SYMBOL_STATES;

	--! 原始512bit明文输出，按时钟依次输出一个字
	signal symbol_raw	:	BYTE_VECTOR(3 downto 0);
	--! 4bit,每bit标识symbol_raw中每个字节的有效
	signal symbol_ena		:	  std_logic_vector(3 downto 0);

	--! 输入明文缓存移位
	signal	buffer_work 	: std_logic_vector(511 downto 0);

	--! len_tmp为模块剩余输出数据长度
	signal len_tmp : integer range 0 to 64;


	--! 标识明文输出最有一个有效字
	signal symbol_last : std_logic;

	--! 标识第一个有效字到symbol_last
	signal symbol_valid : std_logic;

	--! 标识明文输出凑满的第16个字
	signal symbol_done : std_logic;


	--! 移位计数
	signal shift_q  : integer range 0 to 15; 


	---------------------------------------------------------------------------
	--! 第二级处理中间信号
	---------------------------------------------------------------------------
	type  VALID_STATES is (VALID_IDLE, VALID_INPUT, VALID_WAIT);
	signal valid_state : VALID_STATES;

	type  IBUFFER_STATES is (IBUFFER_INPUT, IBUFFER_PADDING, IBUFFER_LAST);
	signal ibuffer_cur: IBUFFER_STATES;
	signal ibuffer_next: IBUFFER_STATES;


	signal text_out_d : std_logic_vector(31 downto 0);

	--! O_valid缓存
	signal text_valid_d : std_logic;
	signal text_valid_q : std_logic;
	--! 总的大小
	signal symbol_size : std_logic_vector(63 downto 0);
	--! 每次的16周期剩余输出字数
	signal remain_out_size : integer range 0 to 15;
	--! 标识长度补位完毕
	signal out_last : std_logic;


	--! 标识第一次补位，第一次补X"10",以后补X"00"
	signal padding_done2 	:	boolean;

	signal delimiter_cur : std_logic;
	signal delimiter_next : std_logic;

	--! 补位时需要的数据,0x80和0x00
	constant DELIMITER_SYMBOL : std_logic_vector(7 downto 0) := (7 => '1', others => '0');
	constant PADDING_SYMBOL 	: std_logic_vector(7 downto 0) := (others => '0');



begin

	---------------------------------------------------------------------------
	--! 第一级处理，接收模块输入，输出16个时钟的symbol_raw, symbol_valid, 
	--! symbol_ena, symbol_last
	---------------------------------------------------------------------------


	---------------------------------------------------------------------------
	--! 第一级的组合逻辑部分
	---------------------------------------------------------------------------
	U_COMBINE_1 : symbol_valid <= '1' when len_tmp > 0  and I_valid = '1' else
									'0';
																
	U_COMBINE_2  : symbol_ena <= "0000" when len_tmp = 0 else
					"1000" when len_tmp = 1 else
					"1100" when len_tmp = 2 else
					"1110" when len_tmp = 3 else
					"1111";
	U_COMBINE_4 : symbol_last <= '1' when len_tmp <= 4 and len_tmp > 0 and I_last = '1'  else
					'0';

	U_COMBINE_5 : symbol_done <= '1' when shift_q = 15  else
							'0';


	U_COMBINE_3: for i in 3 downto 0 generate
		--! symbol_raw取buffer_work的高32位
		symbol_raw(i) <= buffer_work(487 + i *8    downto 480 + i * 8);
	end generate;


	--! 这里最好也别用组合逻辑了
	U_SEQUEN_1: process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			symbol_cur <= SYMBOL_IDLE;
		elsif Clk'event and Clk = '1' then
			case symbol_cur is
				when SYMBOL_IDLE =>
					if I_valid = '1' then
						--! 这三个都应该是寄存器，而非组合逻辑
						shift_q <= 0;				
						buffer_work <= I_data;
						len_tmp <= conv_integer(I_datalen);
						symbol_cur <= SYMBOL_OUT;
					else
						symbol_cur <= SYMBOL_IDLE;
					end if;
				when SYMBOL_OUT =>
					buffer_work(511 downto 0) <= buffer_work(479 downto 0) & buffer_work(511 downto 480);


					--! 这里的逻辑不好，同时判断>=4和<=4,乱,好在不是什么关键路径，以后再说
					if len_tmp >= 4 then
						len_tmp <= len_tmp - 4;
					else
						len_tmp <= 0;
					end if;



					if shift_q = 15 then
						shift_q <= 0;
						symbol_cur <= SYMBOL_WAIT;
					else
						shift_q <= shift_q + 1;
						symbol_cur <= SYMBOL_OUT;
					end if;
				when SYMBOL_WAIT =>
					shift_q <= 0;
					buffer_work <= (others => '0');
					if I_valid = '0' then
						symbol_cur <= SYMBOL_IDLE;
					else
						symbol_cur <= SYMBOL_WAIT;
					end if;
				when others =>
					buffer_work <= (others => '0');
			end case;
		end if;


	end process;

	-----------------------------------------------------------------------
	--!　二级处理,　接收一级处理的数据，输出text_out, o_valid, o_last
	-----------------------------------------------------------------------


	--! 将一个symbol_raw展开成4个word,
	--! 如果单个symbol_raw里不满4个有效word，则补'1',其余补'0'
	U_SYMBOL_OUT : process(symbol_raw, symbol_ena, symbol_last, symbol_valid, delimiter_cur, ibuffer_cur, remain_out_size, symbol_size)
		--! 这俩需要用变量，而不是信号,　因为一次进程中有for循环多次更新prev_valid的值，
		--! 信号只能在进程结束改变一次
		variable prev_valid 	: 	boolean;
		variable padding_done	:	boolean;
		variable data_tmp 		:	BYTE_VECTOR(3 downto 0);
	begin
		--------------------------------------------------------------------
		--! 对data_tmp赋值
		--------------------------------------------------------------------
			for i in data_tmp'range loop
				if symbol_ena(i) = '1' then
					data_tmp(i) := symbol_raw(i);
					prev_valid := TRUE;
					padding_done := FALSE;
				elsif prev_valid  then		--这是针对４字节中前几个数字有效，需要在后几个数据中补'1'的情况,这里会置位padding_done1
					data_tmp(i) := DELIMITER_SYMBOL;
					prev_valid := FALSE;
					padding_done := TRUE;
				else
					data_tmp(i) := PADDING_SYMBOL;
					prev_valid := FALSE; 
					padding_done := TRUE; 
				end if; 
			end loop; 

			--------------------------------------------------------------------
			--! 更新边界符号,只当最后一个symbol_raw的4个字全是有效数据，需要在其后一个symbol_raw里补X'80'的情况
			--! 与上面的data_tmp(i) := DELIMITER_SYMBOL一起构成的补X'80'的两种情况
			--------------------------------------------------------------------
			if ibuffer_cur = IBUFFER_INPUT and symbol_last = '1' and prev_valid then
				delimiter_next <= '1' ;
			else
				delimiter_next <= '0' ;
			end if;

			--------------------------------------------------------------------
			--! 更新数据输出text_out_d
			--------------------------------------------------------------------
			case ibuffer_cur is
				when IBUFFER_INPUT =>
					text_valid_d <= symbol_valid;
					text_out_d(31 downto 0) <= data_tmp(3) & data_tmp(2) & data_tmp(1) & data_tmp(0);
					--! symbol_last = 1时，必然涉及到是否补'1'的问题
					--! (1) symbol_last = 1 &&  padding_done1 = 1 && remain_out_size = 2,　非常凑巧的一个情况
					--!		补完X'80'的完整字之后，正好有8个字节，用于补最后的长度，直接跳到IBUFFER_LAST状态
					--! (2) 其余情况，直接跳到IBUFFER_PADDING状态，进一步用X'80'或者X'00'填充
					if symbol_last = '1' then		
						if remain_out_size = 2 and padding_done then
							ibuffer_next <= IBUFFER_LAST;
						else
							ibuffer_next <= IBUFFER_PADDING;
						end if;
					else
						ibuffer_next <= IBUFFER_INPUT;
					end if;
				when IBUFFER_PADDING =>
					text_valid_d <= '1';

					--! 使用delimiter_cur 来灵活判定到底是补X'80'还是X'00'
					text_out_d <= delimiter_cur & (text_out_d'high - 1 downto 0 => '0');
					if remain_out_size = 2 then
						ibuffer_next <= IBUFFER_LAST;
					else 
						ibuffer_next <= IBUFFER_PADDING;
					end if;
				when IBUFFER_LAST =>
					if remain_out_size = 1 then
						text_valid_d <= '1';
						text_out_d <= symbol_size(63 downto 32);
						ibuffer_next <= IBUFFER_LAST;
					else
						text_valid_d <= '1';
						text_out_d <= symbol_size(31 downto 0);
						ibuffer_next <= IBUFFER_INPUT;
					end if;
			end case ;

	end process;

	-----------------------------------------------------------------------
	--! 时序逻辑,　寄存器缓存
	-----------------------------------------------------------------------
	U_2_MAIN : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			delimiter_cur <= '0';
			Text_out <= (others => '0');
			ibuffer_cur <= IBUFFER_INPUT;
			text_valid_q <= '0';
		elsif Clk'event and Clk = '1' and I_next = '1' then
			delimiter_cur <= delimiter_next;
			Text_out <= text_out_d;
			ibuffer_cur <= ibuffer_next;
			text_valid_q <= text_valid_d;
		end if;
	end process;


		-----------------------------------------------------------------------
		--!　remain_out_size
		-----------------------------------------------------------------------
		U_REMAIN_OUT_SIZE : process(Clk, Rst_n)
		begin
			if Rst_n = '0' then
				remain_out_size <= 15;
			elsif Clk'event and Clk = '1' then
				if Clr_n = '0' then
					remain_out_size <= 15;
				elsif text_valid_d = '1'  then
					if remain_out_size = 0 or symbol_done = '1' then
						remain_out_size <= 15;
					elsif I_next = '1' then
						remain_out_size <= remain_out_size - 1;
					end if;
				end if;
			end if;
		end process;
	-----------------------------------------------------------------------
	--!　symbol_size
	-----------------------------------------------------------------------
	U_SYMBOL_SIZE : process(Clk, Rst_n)
		variable in_size : integer range 0 to 32;
		subtype  SYMBOL_COUNT_TYPE is integer range 0 to 4;
		function COUNT_BIT_1(ARG:std_logic_vector) return SYMBOL_COUNT_TYPE is
			alias    ENA : std_logic_vector(ARG'length-1 downto 0) is ARG;
		begin
			if  (ENA'length = 1) then
				if (ENA(0) = '1') then
					return 1;                                                                                                                                      
				else
					return 0;
				end if;
			else
				return COUNT_BIT_1(ENA(ENA'high         downto (ENA'high+1)/2))
				+ COUNT_BIT_1(ENA((ENA'high+1)/2-1 downto ENA'low       ));
			end if;
		end function;

	begin
		if Rst_n = '0' then
			symbol_size <= (others => '0');
		elsif Clk'event and Clk = '1' then
			--! 明文最后补完长度了，symbol_size没什么用，可以清0了
			if Clr_n = '0' then
				symbol_size <= (others => '0');
			elsif I_next = '0' and out_last = '1' then
				symbol_size <= (others => '0');
			elsif ibuffer_cur = IBUFFER_INPUT and symbol_valid = '1' then
				in_size := COUNT_BIT_1(symbol_ena) * 8;
				symbol_size <= symbol_size + in_size;
			end if;
		end if;
	end process;

	--! 寄存器输出O_last信号，组合逻辑输出会造成尖刺
	U_O_LAST : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			out_last <= '0';
		elsif Clk'event and Clk = '1' then
			if Clr_n = '0' then
				out_last <= '0';
			else
				if I_valid = '0' then
					out_last <= '0';
				elsif ibuffer_cur = IBUFFER_LAST and remain_out_size = 0 then
					out_last <= '1';
				end if;
			end if;
		end if;

	end process;

	O_last <= out_last;
	O_valid <= text_valid_q;



end BEHAVIOR;
