library IEEE;
use IEEE.std_logic_1164.all;
entity TB_FIFO_SYNC is
end TB_FIFO_SYNC;

architecture BEHAVOR of TB_FIFO_SYNC is
	component FIFO_SYNC
	generic (
            constant DATA_WITH	:	integer := 16;
            --! 实际fifo容量为2**ADDR_WITH
            constant ADDR_WITH	:	integer := 10
        );
    port (
            Clk        :    in    std_logic;
            Rst_n    :    in    std_logic;
            --! 写入侧
            Din        :    in    std_logic_vector(DATA_WITH - 1 downto 0);
            Wr_en    :    in    std_logic;
            Full    :    out    std_logic;
			Almost_full	:	out	std_logic;
			Almost_empty	:	out	std_logic;
            
            --! 读出侧
            Dout    :    out    std_logic_vector(DATA_WITH - 1 downto 0);
            Valid    :    out    std_logic;
            Rd_en    :    in    std_logic;
            Empty    :    out    std_logic
         );
	end component;


	signal clk 	:		std_logic;
	signal rst	:		std_logic;

	signal din	:	std_logic_vector(15 downto 0);
	signal dout	:	std_logic_vector(15 downto 0);
	signal wr_en	:	std_logic;
	signal rd_en	:	std_logic;
	signal full		:	std_logic;
	signal empty	:	std_logic;
	signal valid	:	std_logic;

	type TEST_STATES is (STATES_ONE, STATES_TWO, STATES_THREE, STATES_FOUR);
	signal wr_state : TEST_STATES;
	signal rd_state : TEST_STATES;
	type ARRAYS is array(10 downto 0) of std_logic_vector(15 downto 0);
	signal ll_array : ARRAYS;
	signal ll_test : std_logic_vector(15 downto 0);
	signal index : integer range 0 to 10;
	

begin
	U_FIFO : FIFO_SYNC
	generic map(DATA_WITH => 16,
			    ADDR_WITH => 4)
	port map(
				Clk => clk,	
				Rst_n => rst,
				Din	=>	din,
				Wr_en => wr_en,
				Almost_full =>	full,
				Dout 	=>	dout,
				Valid	=>	valid,
				rd_en 	=>	rd_en,
				Almost_empty => empty
			);
	U_CLK : process
	begin
		clk <= '1';
		wait for 5 ns;
		clk <= '0';
		wait for 5 ns;
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

	U_WR : process(Clk, rst)
	begin
		if rst = '0' then
			index <= 0;
			wr_state <= STATES_ONE;
		elsif Clk'event and Clk = '1' then
			case wr_state is
				when STATES_ONE =>
					din <= ll_array(index);
					if full = '0' then
					   wr_state <= STATES_ONE;
					   wr_en <= '1';
					else
					   wr_state <= STATES_TWO;
					   wr_en <= '0';
					end if;
					if index = 10 then		
						index <= 0;
					else
						index <= index + 1;

					end if;
				when STATES_TWO =>
					 wr_en <= '0';
				when STATES_THREE =>
				when STATES_FOUR =>
			end case;
		end if;
	end process;

	U_RD : process(Clk, rst)
	begin
		if rst = '0' then
			rd_state <= STATES_ONE;
			rd_en <= '0';
		elsif Clk'event and Clk = '1' then
			case rd_state is
				when STATES_ONE =>
					if empty = '0' and wr_state = STATES_TWO then
						rd_en <= '1';
					else
						rd_en <= '0';
						rd_state <= STATES_ONE;
					end if;
				when STATES_TWO =>
				when STATES_THREE =>
				when STATES_FOUR =>
			end case;
		end if;
	end process;
	
	U_RD2 : process(Clk, rst)
    begin
        if rst = '0' then
            ll_test <= (others => '0');
        elsif Clk'event and Clk = '1' then

                       if valid = '1' then
                        ll_test <= dout;
                        end if;

        end if;
    end process;

end BEHAVOR;
