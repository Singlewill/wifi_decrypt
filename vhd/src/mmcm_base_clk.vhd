library IEEE;
Library UNISIM;
use IEEE.std_logic_1164.all;
use UNISIM.vcomponents.all;

entity MMCM_BASE_CLK is
	port(
			Clk_in		:	in	std_logic;	
			Rst_n		:	in	std_logic;
			locked		:	out	std_logic;
			Clk_out0	:	out	std_logic;
			Clk_out1	:	out	std_logic
		);
end MMCM_BASE_CLK;
architecture BEHAVOR of MMCM_BASE_CLK is
	signal clkin_buf	:	std_logic;
	signal clkout0_buf	:	std_logic;
	signal clkout1_buf	:	std_logic;
	signal clkout0 :   std_logic;
	signal clkout1 :    std_logic;
	signal clkfb		:	std_logic;
	signal clkfb_buf	:	std_logic;

	signal reset_high	:	std_logic;
begin
    U_MMCME2_BASE : MMCME2_BASE
	generic map (
					BANDWIDTH => "OPTIMIZED",  -- Jitter programming (OPTIMIZED, HIGH, LOW)
					CLKFBOUT_MULT_F => 8.0,    -- Multiply value for all CLKOUT (2.000-64.000).
					CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB (-360.000-360.000).
					CLKIN1_PERIOD => 10.0,      -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
					--! CLKOUT0	
					CLKOUT0_DIVIDE_F  => 8.0,
					CLKOUT0_DUTY_CYCLE => 0.5,
					CLKOUT0_PHASE => 0.0,

					--! CLKOUT0	
					CLKOUT1_DIVIDE  => 16,
					CLKOUT1_DUTY_CYCLE => 0.5,
					CLKOUT1_PHASE => 0.0,


					DIVCLK_DIVIDE => 1,        -- Master division value (1-106)
					REF_JITTER1 => 0.0,        -- Reference input jitter in UI (0.000-0.999).
					CLKOUT4_CASCADE => FALSE,  -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
					STARTUP_WAIT => FALSE      -- Delays DONE until MMCM is locked (FALSE, TRUE)
				)
	port map (
				 CLKIN1 => clkin_buf,       -- input clk
				 CLKFBIN => clkfb_buf,
				 PWRDWN => '0',
				 RST => reset_high,        

				 CLKFBOUT => clkfb,   -- 1-bit output: Feedback clock
				 CLKOUT0 => clkout0,     -- 1-bit output: CLKOUT1
				 CLKOUT1 => clkout1,     -- 1-bit output: CLKOUT1
				 LOCKED => locked		-- 0 --> 1


			 );

	U_CLKIN_IBUF : IBUF
	port map(
				I =>	Clk_in,
				O => 	clkin_buf
			);

	U_CLKF_BUF : BUFG
	port map(
				O =>	clkfb_buf,
				I =>	clkfb
			);

	U_CLKOUT0_BUF : BUFG 
	port map(
				O   =>clkout0_buf,
				I   =>clkout0

			);

	U_CLKOUT1_BUF : BUFG 
	port map(
				O   =>clkout1_buf,
				I   =>clkout1

			);

	reset_high <= not Rst_n;
	Clk_out0  <= clkout0_buf;
	Clk_out1  <= clkout1_buf;
end BEHAVOR;
