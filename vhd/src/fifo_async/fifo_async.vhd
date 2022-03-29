-------------------------------------------------------------------------------
--! @file		fifo_async.vhd
--! @function	异步fifo
-------------------------------------------------------------------------------
--!	1,写指针同步到读时钟域 进行判空
--! 2,读指针同步到写时钟域 进行判满
--! 3,使用gray码降低毛刺
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity FIFO_ASYNC is
	generic (
			constant DATA_WIDTH	:	integer := 8;
			constant ADDR_WIDTH	:	integer := 4
		);
	port (
			Rst_n			:	in	std_logic;
			--! 写入侧
			Clk_wr			:	in	std_logic;
			Wr_en           :   in  std_logic;
			Din				:	in	std_logic_vector(DATA_WIDTH - 1 downto 0);
			Full			:	out	std_logic;
			Almost_full		:	out std_logic;

			--! 读出侧
			Clk_rd			:	in	std_logic;
			Rd_en           :   in  std_logic;
			Dout			:	out	std_logic_vector(DATA_WIDTH - 1 downto 0);
			Empty			:	out std_logic;
			Almost_empty	:	out std_logic;
			Valid			:	out std_logic
		 );
end FIFO_ASYNC;

architecture BEHAVOR of FIFO_ASYNC is
	component SYNC_CROSSCLK 
	generic (constant DATA_WIDTH : integer := 8 );
	port (
			Clk		:	in	std_logic; 
			Rst_n	:	in	std_logic;
			Din		:	in	std_logic_vector(DATA_WIDTH - 1 downto 0);
			Dout	:	out	std_logic_vector(DATA_WIDTH - 1 downto 0)
		 );
	end component;

    component BIN2GRAY 
    generic (constant DATA_WIDTH : integer := 8);
    port (
            Din        :    in    std_logic_vector(DATA_WIDTH -1 downto 0) ;
            Dout    :    out    std_logic_vector(DATA_WIDTH -1 downto 0) 
         );
    end component;
	component SIMPLE_DUAL_TWO_CLOCKS
	generic (
			constant DATA_WIDTH	:	integer := 8;
			--! 实际fifo容量为2**ADDR_WIDTH
			constant ADDR_WIDTH	:	integer := 4
		);
	port(
		Clka  : in  std_logic;
		Clkb  : in  std_logic;
		Ena   : in  std_logic;
		Enb   : in  std_logic;
		Addra : in  std_logic_vector(ADDR_WIDTH - 1  downto 0);
		Addrb : in  std_logic_vector(ADDR_WIDTH - 1  downto 0);
		Dia   : in  std_logic_vector(DATA_WIDTH - 1  downto 0);
		Dob   : out std_logic_vector(DATA_WIDTH - 1  downto 0)
	);
	end component;

	--! 写时钟域信号,写指针, 当前写指针，写指针+1, 写指针下一次的更新指针
	signal wp 			: std_logic_vector(ADDR_WIDTH  downto 0);
	signal wp_next 		: std_logic_vector(ADDR_WIDTH  downto 0);
	--! lfsr
	signal wp_gray_next		: std_logic_vector(ADDR_WIDTH  downto 0);
	--! 同步到读时钟域
	signal wp_gray_l1	: std_logic_vector(ADDR_WIDTH  downto 0);
	signal wp_gray_sync	: std_logic_vector(ADDR_WIDTH  downto 0);

	--! 读时钟域
	signal rp 			: std_logic_vector(ADDR_WIDTH  downto 0);
	signal rp_next 		: std_logic_vector(ADDR_WIDTH  downto 0);
	signal rp_gray_next	: std_logic_vector(ADDR_WIDTH  downto 0);
	--! 同步到读时钟域
	signal rp_gray_l1	: std_logic_vector(ADDR_WIDTH  downto 0);
	signal rp_gray_sync	: std_logic_vector(ADDR_WIDTH  downto 0);

	--! 空满信号
	signal full_reg		: std_logic;
	signal full_next 	: std_logic;
	signal empty_reg 	: std_logic;
	signal empty_next 	: std_logic;


	--! 对Wr_en和Rd_en输入进行判断，防止溢出
	signal wr_allow    	:   std_logic;	
	signal rd_allow    	:   std_logic;	
begin
	U_SIMPLE_DUAL_TWO_CLOCKS : SIMPLE_DUAL_TWO_CLOCKS
	generic map(
				DATA_WIDTH	=>	DATA_WIDTH,	
				ADDR_WIDTH	=>	ADDR_WIDTH
			   )
	port map(
				Clka  		=>	Clk_wr,
				Clkb  		=>	Clk_rd,
				Ena   		=>	wr_allow,
				Enb   		=>	rd_allow,
				Addra 		=>	wp(ADDR_WIDTH - 1 downto 0),
				Addrb 		=>	rp(ADDR_WIDTH - 1 downto 0),
				Dia   		=>	Din,
				Dob   		=>	Dout
			);

	U_GRAY_WR_NEXT : BIN2GRAY
	generic map (DATA_WIDTH => ADDR_WIDTH + 1)
	port map(
				Din		=>	wp_next,
				Dout	=>	wp_gray_next
			);


	U_GRAY_RD_NEXT : BIN2GRAY
	generic map (DATA_WIDTH => ADDR_WIDTH + 1)
	port map(
				Din		=>	rp_next,
				Dout	=>	rp_gray_next
			);
	U_RP_NEXT_SYNC : SYNC_CROSSCLK
	generic map(DATA_WIDTH => ADDR_WIDTH + 1)
	port map(
				Clk		=>	Clk_wr,			
				Rst_n 	=>	Rst_n,
				Din		=>	rp_gray_next,
				Dout	=>	rp_gray_sync
			);

	U_WP_NEXT_SYNC : SYNC_CROSSCLK
	generic map(DATA_WIDTH => ADDR_WIDTH + 1)
	port map(
				Clk		=>	Clk_wr,			
				Rst_n 	=>	Rst_n,
				Din		=>	wp_gray_next,
				Dout	=>	wp_gray_sync
			);


	--! 在w时钟下更新wp指针和满指针
	U_WCLK_WP : process(Clk_wr, Rst_n)
	begin
		if Clk_wr'event and Clk_wr = '1' then
			if Rst_n = '0' then
				wp <= (others => '0');
				full_reg <= '0';
			else
				wp <= wp_next;
				full_reg <= full_next;
			end if;
		end if;
	end process;

	--! 在r时钟下更新rp和空指针,以及valid
	U_RCLK_RP : process(Clk_rd, Rst_n)
	begin
		if Clk_rd'event and Clk_rd = '1' then
			if Rst_n = '0' then
				rp <= (others => '0');
				empty_reg <= '1';
				Valid <= '0';
			else
				rp <= rp_next;
				empty_reg <= empty_next;
				Valid <= rd_allow;
			end if;
		end if;
	end process;


	--! 判定后的写使能和读使能
	wr_allow <= '1' when Wr_en = '1' and full_reg = '0' else
				'0';
	rd_allow <= '1' when Rd_en = '1' and empty_reg = '0' else
				'0';


	--! 读写指针移动
	wp_next <= wp + 1 when wr_allow = '1' else
			   wp;
	rp_next <= rp + 1 when rd_allow = '1' else
			   rp;


	--! wp和相应格雷码比实际多了一位，在这个条件下判断的满空
	--! 空 : 格雷码完全一致即可
	--! 满 : 格雷码高两位相反，其余位相同(这是格雷码本身特性决定的)
	full_next <= '1' when wp_gray_next(ADDR_WIDTH - 2 downto 0) = rp_gray_sync(ADDR_WIDTH - 2 downto 0) and 
				  wp_gray_next(ADDR_WIDTH  downto ADDR_WIDTH - 1) = not rp_gray_sync(ADDR_WIDTH  downto ADDR_WIDTH - 1) else
				 '0';

	empty_next <= '1' when rp_gray_next = wp_gray_sync else
				  '0';

	--! 部分控制信号输出
	Full 			<= full_reg;
	Almost_full 	<= full_next;
	Empty			<= empty_reg;
	Almost_empty	<= empty_next;
end BEHAVOR;
