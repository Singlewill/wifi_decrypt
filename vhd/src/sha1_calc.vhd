------------------------------------------------------------------------------
--! 	@file		sha1_calc.vhd
--! 	@function	sha1核心计算
--!		@version	
-----------------------------------------------------------------------------
--		这里的接收数据输入到开始核心计算, 使用了多级寄存器进行前级计算:
--		第0级，Start,　Plaintext, s_num 
--		第1级, w_reg
--		第2级, K, P, A0, B0, C0, D0, E0
--		第3级, A1, B1, C1, D1, E1, F
--		eg : F值属于A1前的组合逻辑
--														对应信号d_*
-----------------------------------------------------------------------------
--! 	核心公式：
--		TEMP = S5(A) + f(t, B, C, D) + E, W, K;
--		E = D;
--		D = C;
--		C = S30(B);
--		B = A;
--		A = TEMP;
-----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.sha1_pkt.all;

entity SHA1_CALC is 
	port (
			Clk			:	in  std_logic;
			Rst_n	:	in std_logic;
			Clr_n		: 	in 	std_logic;
			Start		:	in	std_logic;
			Plaintext	:	--! @brief 被计算的明文,已经补X"80"和长度之后的
							in  std_logic_vector(31 downto 0);
			Textend		:   --! @brieg 已经处理了最后一个明文
							in	std_logic;
			Dout		:   --! @brief 数据输出
							out	std_logic_vector(159 downto 0)  ;
			In_valid	:	--! @brief 模块允许输入
							out std_logic;
			Done 		:	out std_logic
		);
end SHA1_CALC;

architecture BEHAVIOR of SHA1_CALC is 
	-------------------------------------------------------------------------
	--! 任务调度，计数，输出当前应属状态
	-------------------------------------------------------------------------
	component SHA1_SCHEDULE 
	port(
			Clk				:	in std_logic;	
			Rst_n			:	in std_logic;
			Clr_n 			:	in std_logic;
			I_valid			:	in std_logic;
			S_num			:	out integer
		);
	end component;
	-------------------------------------------------------------------------
	--!	内部控制信号定义
	-------------------------------------------------------------------------
	--! 第0级控制信号
	-------------------------------------------------------------------------
	signal 		s_input_0 	:	std_logic;
	signal		s_valid_0	:	std_logic;
	signal 		s_last_0	:	std_logic;
	signal		s_state_0	:	CALC_STATES;
	signal		s_num		:	integer;		--这里加范围0 to 79不行??
	-------------------------------------------------------------------------
	--! 第1级控制信号
	-------------------------------------------------------------------------
	signal 		s_input_1	:	std_logic;
	signal 		s_last_1 	: 	std_logic;
	signal 		s_valid_1	:	std_logic;
	signal 		s_state_1	:	CALC_STATES;

	-------------------------------------------------------------------------
	--! 第2级控制信号
	-------------------------------------------------------------------------
	signal 		s_last_2 	: 	std_logic;
	signal 		s_valid_2	:	std_logic;
	signal 		s_state_2	:	CALC_STATES;

	-------------------------------------------------------------------------
	--! 第2级控制信号
	-------------------------------------------------------------------------
	signal 		s_last_3 	: 	std_logic;
	signal 		s_valid_3	:	std_logic;



	-------------------------------------------------------------------------
	--!	内部数据
	-------------------------------------------------------------------------
	signal 		w_reg	: 	std_logic_vector(511 downto 0);		--16个W缓存
	signal 		W	:	std_logic_vector(31 downto 0);

	--! 加载Hbuffer值信号，应该是s_valid_1 = 1 && s_valid_2　= 0 的一个时钟周期
	signal		H0			:	std_logic_vector(31 downto 0);
	signal		H1			:	std_logic_vector(31 downto 0);
	signal		H2			:	std_logic_vector(31 downto 0);
	signal		H3			:	std_logic_vector(31 downto 0);
	signal		H4			:	std_logic_vector(31 downto 0);


	--------------------------------------------------------------------------
	-- A0,A1参与每一轮sha1_calc计算,A_tmp用于更新A0
	--------------------------------------------------------------------------
	signal A0	:	std_logic_vector(31 downto 0);
	signal B0	:	std_logic_vector(31 downto 0);
	signal C0	:	std_logic_vector(31 downto 0);
	signal D0	:	std_logic_vector(31 downto 0);
	signal E0	:	std_logic_vector(31 downto 0);

	signal A1	:	std_logic_vector(31 downto 0);
	signal B1	:	std_logic_vector(31 downto 0);
	signal C1	:	std_logic_vector(31 downto 0);
	signal D1	:	std_logic_vector(31 downto 0);
	signal E1	:	std_logic_vector(31 downto 0);

	signal A_tmp	:	std_logic_vector(31 downto 0);
	signal B_tmp	:	std_logic_vector(31 downto 0);
	signal C_tmp	:	std_logic_vector(31 downto 0);
	signal D_tmp	:	std_logic_vector(31 downto 0);
	signal E_tmp	:	std_logic_vector(31 downto 0);

	signal K		:	std_logic_vector(31 downto 0);
	signal P		:	std_logic_vector(31 downto 0);
	signal F		:	std_logic_vector(31 downto 0);
	signal o_last 	:	std_logic;

begin
	U_SHA1_SCHEDULE : SHA1_SCHEDULE
	port map(
				Clk				=>	Clk,
				Rst_n			=>	Rst_n,
				Clr_n 			=>	Rst_n,
				I_valid			=>	Start,
				S_num			=>	s_num
			);


	--------------------------------------------------------------------------
	--! 阶段0
	--------------------------------------------------------------------------

	U_PHASE_0 : process(s_num)
	begin
		if s_num >= 0 and s_num < 20 then
			s_state_0 <= CALC_00_19;
		elsif s_num >= 20 and s_num < 40 then
			s_state_0 <= CALC_20_39;
		elsif s_num >= 40 and s_num < 60 then
			s_state_0 <= CALC_40_59;
		else
			s_state_0 <= CALC_60_79;
		end if;

	end process;
	s_input_0 <= '1' when s_num < 16 and Start = '1' else 
			   '0';
	--! 0阶段有效标识
	--! 有毛刺
	s_valid_0 <= '1' when s_input_0 = '1' or (s_num >= 16 and s_num <= 79)  else	
			   '0';
	s_last_0 <= '1' when (s_num = 79) else 
			  '0';
	In_valid <= '1' when s_num < 16 else
				'0';

	--------------------------------------------------------------------------
	--! 1阶段信号更新：s_valid_1,s_input_1,s_state_1,s_last_1均落后0阶段一个时钟
	--------------------------------------------------------------------------
	U_W_STATE_UPDATE : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			s_valid_1 <= '0';
			s_input_1 <= '0';
			s_state_1 <= CALC_00_19;
			s_last_1 <= '0';
		elsif Clk'event and Clk = '1' then
			if Clr_n = '0' then
				s_valid_1 <= '0';
				s_input_1<= '0';
				s_state_1 <= CALC_00_19;
				s_last_1 <= '0';
			else
				s_valid_1 <= s_valid_0;
				s_input_1<= s_input_0;
				s_state_1 <= s_state_0;
				s_last_1 <= s_last_0;
			end if;
		end if;
	end process;

	--------------------------------------------------------------------------
	--! 1阶段数据输出,带移位的，不要使用纯组合
	--------------------------------------------------------------------------
	U_W_OUT : process(Clk, Rst_n)
		--! 17个W缓存,比w_reg多一个32
		variable w_work : 	std_logic_vector(543 downto 0);
	begin
		if  Rst_n = '0' then
			w_reg <= (others => '0');
		elsif Clk'event and Clk = '1' then
			if  Clr_n = '0' then
				w_reg <= (others => '0');
			elsif s_valid_0 = '1' then
				w_work(511 downto 0) := w_reg(511 downto 0);
				if s_input_0 = '1' then
					w_work(543 downto 512) := Plaintext(31 downto 0);
				else
					w_work(543 downto 512) := Rotl(w_work(447 downto 416)  xor
										w_work(287 downto 256) xor
										w_work(95 downto 64) xor
										w_work(31 downto 0), 1);
				end if;
				w_reg(511 downto 0) <= w_work(543 downto 32);
			else
				w_reg <= (others => '0');
			end if;

		end if;
	end process;
	W <= w_reg(511 downto 480);




	--------------------------------------------------------------------------
	--! 2阶段信号更新：p_valid,p_state,p_last均落后w_*一个时钟
	--------------------------------------------------------------------------

	U_STATE_UPDATE_2 : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			s_state_2 <= CALC_00_19;
			s_valid_2 <= '0';
			s_valid_3 <= '0';
			s_last_2 <= '0';

		elsif Clk'event and Clk = '1' then
			if Clr_n = '0' then
				s_state_2 <= CALC_00_19;
				s_valid_2 <= '0';
				s_valid_3 <= '0';
				s_last_2 <= '0';
			else
				s_state_2 <= s_state_1;
				s_valid_2 <= s_valid_1;
				s_valid_3 <= s_valid_2;
				s_last_2 <= s_last_1;
			end if;
		end if;
	end process;
	---------------------------------------------------------------------------
	-- 2阶段的K值更新,(P = k + w,K是组合逻辑，，, 所以Ｋ应该和Ｐ一样，参考s_state_1的逻辑)
	---------------------------------------------------------------------------
	K <= K0 when s_state_1 = CALC_00_19 else
		 K1 when s_state_1 = CALC_20_39 else
		 K2 when s_state_1 = CALC_40_59 else
		 K3;
	--------------------------------------------------------------------------
	--! 2阶段P值生成,P = W + K;
	--------------------------------------------------------------------------
	U_P_GEN: process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			P <= (others => '0');
		elsif Clk'event and Clk = '1' then
			if Clr_n = '0' then
				P <= (others => '0');
			else
				P <= W + K;
			end if;
		end if;
	end process;


	--------------------------------------------------------------------------
	--! 3阶段控制信号更新
	--------------------------------------------------------------------------
	U_STATE_UPDATE_3 : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			s_last_3 <= '0';

		elsif Clk'event and Clk = '1' then
			if Clr_n = '0' then
				s_last_3 <= '0';
			else
				s_last_3 <= s_last_2;
			end if;
		end if;
	end process;
	----------------------------------------------------------------------------
	--! 3阶段的F值更新,这里敏感列表其实应该加上s_num_3
	----------------------------------------------------------------------------
	process(B0, C0, D0)		
	begin
		if s_state_2 = CALC_00_19 then
			F 	<=	(B0 and C0) OR ((not B0) and D0);
		elsif s_state_2 = CALC_40_59 then
			F <= (B0 and C0) OR (B0 and D0) OR (C0 and D0);
		else
			F <= B0 XOR C0 XOR D0 ;
		end if;
	end process;



	---------------------------------------------------------------------------
	--! 组合控制
	---------------------------------------------------------------------------
	A0 	<= A_tmp;
	B0 	<= B_tmp;
	C0 	<= C_tmp;
	D0 	<= D_tmp;
	E0 	<= E_tmp;

	A1 	<= Rotl(A0,5) + F + E0 + P;
	B1 	<= A0;
	C1 	<= Rotl(B0,30);
	D1 	<= C0;
	E1 	<= D0;

	U_DOUT : process(Clk, Rst_n)
		variable H0_next		:	std_logic_vector(31 downto 0);
		variable H1_next		:	std_logic_vector(31 downto 0);
		variable H2_next		:	std_logic_vector(31 downto 0);
		variable H3_next		:	std_logic_vector(31 downto 0);
		variable H4_next		:	std_logic_vector(31 downto 0);
	begin
		if Rst_n = '0' then
				H0 <= H0_INIT;
				H1 <= H1_INIT;
				H2 <= H2_INIT;
				H3 <= H3_INIT;
				H4 <= H4_INIT;

				A_tmp <= H0_INIT;
				B_tmp <= H1_INIT;
				C_tmp <= H2_INIT;
				D_tmp <= H3_INIT;
				E_tmp <= H4_INIT;
		elsif Clk'event and Clk = '1'  then
			if Clr_n = '0' then
				H0 <= H0_INIT;
				H1 <= H1_INIT;
				H2 <= H2_INIT;
				H3 <= H3_INIT;
				H4 <= H4_INIT;

				A_tmp <= H0_INIT;
				B_tmp <= H1_INIT;
				C_tmp <= H2_INIT;
				D_tmp <= H3_INIT;
				E_tmp <= H4_INIT;

			--! 阶段性结束，未收到最后的包含数据长度的明文
			elsif s_last_2 = '1' then
				H0_next		:= H0	+ A1;
				H1_next 	:= H1 	+ B1;
				H2_next 	:= H2	+ C1;
				H3_next		:= H3 	+ D1;
				H4_next 	:= H4 	+ E1;
				Dout <= H0_next & H1_next & H2_next & H3_next & H4_next;

				--! 真正的结束，恢复H缓存池
				if Textend = '1' then
					H0 <= H0_INIT;
					H1 <= H1_INIT;
					H2 <= H2_INIT;
					H3 <= H3_INIT;
					H4 <= H4_INIT;
					A_tmp <= H0_INIT;
					B_tmp <= H1_INIT;
					C_tmp <= H2_INIT;
					D_tmp <= H3_INIT;
					E_tmp <= H4_INIT;
				else
					H0 <= H0_next;
					H1 <= H1_next;
					H2 <= H2_next;
					H3 <= H3_next;
					H4 <= H4_next;

					A_tmp <= H0_next;
					B_tmp <= H1_next;
					C_tmp <= H2_next;
					D_tmp <= H3_next;
					E_tmp <= H4_next;
				end if;
	

			elsif s_valid_2 = '1' then
				A_tmp <= A1;
				B_tmp <= B1;
				C_tmp <= C1;
				D_tmp <= D1;
				E_tmp <= E1;
			end if;

		end if;


	end process;


	o_last <= '1' when s_last_2 = '1' and Textend = '1' else
			  '0';


	U_OUT_DONE : process(Clk, Rst_n)
	begin
		if Rst_n = '0' then
			Done <= '0';
		elsif Clk'event and Clk = '1' then
			if Clr_n = '0' then
				Done <= '0';
			else
				Done <= s_last_2;
			end if;
		end if;
	end process;


	
end BEHAVIOR;
