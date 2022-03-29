library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;


entity TB_FIFO_ASYNC is
end TB_FIFO_ASYNC;

architecture BEHAVOR of TB_FIFO_ASYNC is
	component FIFO_ASYNC
	generic (
			constant DATA_WIDTH	:	integer := 8;
			constant ADDR_WIDTH	:	integer := 4
		);
	port (
			Rst_n			:	in	std_logic;
			--! 写入侧
			Clk_wr			:	in	std_logic;
			Wr_en            :   in  std_logic;
			Din				:	in	std_logic_vector(DATA_WIDTH - 1 downto 0);
			Full			:	out	std_logic;
			Almost_full		:	out std_logic;

			--! 读出侧
			Clk_rd			:	in	std_logic;
			Rd_en        :   in  std_logic;
			Dout			:	out	std_logic_vector(DATA_WIDTH - 1 downto 0);
			Empty			:	out std_logic;
			Almost_empty	:	out std_logic;
			Valid			:	out std_logic
		 );
	end component;


	signal clk_wr 		:	std_logic;
	signal clk_rd 		:	std_logic;
	signal wr_en       :   std_logic;
	signal rd_en       :   std_logic;
	signal rst			:	std_logic;
	signal almost_full 	:	std_logic;
	signal almost_empty	:	std_logic;
	signal full 		:	std_logic;
	signal empty		:	std_logic;
	signal valid		:	std_logic;
    signal din          :   std_logic_vector(15 downto 0);
    signal dout         :   std_logic_vector(15 downto 0);
	type TEST_STATES is (STATES_ONE, STATES_TWO, STATES_THREE, STATES_FOUR);
	signal wr_state : TEST_STATES;
	signal rd_state : TEST_STATES;
	signal index : integer range 0 to 10;
	signal ll_test : std_logic_vector(15 downto 0);
	type ARRAYS is array(10 downto 0) of std_logic_vector(15 downto 0);
	signal ll_array : ARRAYS;
begin
	U_FIFO : FIFO_ASYNC
	generic map(DATA_WIDTH => 16,
			   	ADDR_WIDTH	=> 4)
	port map(
			Rst_n			=>	rst,	
			Clk_wr			=>	clk_wr,
			Wr_en            =>  wr_en,
			Din				=>	din,
			Almost_full =>	full,

			Clk_rd			=> 	clk_rd,
			Rd_en        =>  rd_en,
			Dout			=>	dout,
			Almost_empty =>  empty,
			Valid			=>	valid
	
	);
	
	U_CLK1 : process
	begin
		clk_wr <= '1';
		wait for 10 ns;
		clk_wr <= '0';
		wait for 10 ns;
	end process;

	U_CLK2 : process
	begin
		clk_rd <= '1';
		wait for 2 ns;
		clk_rd <= '0';
		wait for 2 ns;
	end process;

	U_RST : process
	begin
		rst <= '0';
		wait for 20 ns;
		rst <= '1';
		ll_array(0) <= X"1111";
		ll_array(1) <= X"2222";
		ll_array(2) <= X"3333";
		ll_array(3) <= X"4444";
		ll_array(4) <= X"5555";
		ll_array(5) <= X"6666";
		ll_array(6) <= X"7777";
		ll_array(7) <= X"8888";
		ll_array(8) <= X"9999";
		ll_array(9) <= X"1212";
		ll_array(10) <= X"2323";
		wait;
	end process;

	U_WR : process(clk_wr, rst)
	begin
		if rst = '0' then
			index <= 0;
			wr_state <= STATES_ONE;
		elsif clk_wr'event and clk_wr = '1' then
			case wr_state is
				when STATES_ONE =>
					din <= ll_array(index);
					if full = '1' then
						
                        wr_en <= '0';
					   
					else
				       
                        wr_en <= '1';
					end if;
					if index = 8 then		
					   wr_state <= STATES_TWO;
						index <= 0;
					else
					   wr_state <= STATES_ONE;
						index <= index + 1;

					end if;
				when STATES_TWO =>
					 wr_en <= '0';
				when STATES_THREE =>
				when STATES_FOUR =>
			end case;
		end if;
	end process;

	U_RD : process(Clk_rd, rst)
	begin
		if rst = '0' then
			rd_state <= STATES_ONE;
			rd_en <= '0';
		elsif Clk_rd'event and Clk_rd = '1' then
			case rd_state is
				when STATES_ONE =>
					if empty = '0' then
						rd_en <= '1';
					else
						rd_en <= '0';
						
					end if;
					rd_state <= STATES_ONE;
				when STATES_TWO =>
				when STATES_THREE =>
				when STATES_FOUR =>
			end case;
		end if;
	end process;

	U_RD2 : process(Clk_rd, rst)
    begin
		if rst = '0' then
			ll_test <= (others => '0');
		elsif Clk_rd'event and Clk_rd = '1' then

			if valid = '1' then
				ll_test <= dout;
			end if;

		end if;
	end process;
end BEHAVOR;
