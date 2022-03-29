--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- A VHDL-Library for reading SD-Cards with a FPGA inside a small test project.
-- Copyright (C) 2017  Simon Aster
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
----------------------------------------------
-- Library:		vhdl_lib
-- File:			count_bin.vhd
-- Author:		Simon Aster
-- Created:		2016
-- Modified:	2017-04-02
-- Version:		2.2
----------------------------------------------
-- Description:
-- This unit will count the std_logic_vector signal 'cnt'
-- with 'bits' bit. when 'zero' is '1' and 'clk_en' = '1' 
-- the output 'cnt' will be set to 0.	When 'up' or 'down' is '1'
-- and 'clk_en' = '1' this unit will count up or down at a
-- rising clk-edge. 'up' overrides 'clk_en_db'.
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

library work;
use work.de0_nano_const_pkg.all;

entity count_bin is
generic(
	bits		: natural
);
port(
	rst			: in  std_logic;
	clk			: in  std_logic;
	clk_en	: in  std_logic := '1';
	zero		: in  std_logic := '0';
	up			: in  std_logic := '0';
	down		: in  std_logic := '0';
	cnt			: out std_logic_vector(bits-1 downto 0)
);
end count_bin;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

architecture count_bin_a of count_bin is
	signal tmp : std_logic_vector(bits - 1 downto 0);
begin
	cnt <= tmp;

	p_count_bin: process(rst, clk)
	begin
	
	if rst = '0' then
		tmp <= (others=>'0');

	elsif clk'event and clk = '1' then
		if clk_en = '1' then

			if zero = '1' then
				tmp <= (others=>'0');

			elsif up = '1' then
				tmp <= tmp + 1;

			elsif down = '1' then
				tmp <= tmp - 1;
				
			end if;
		end if;
	end if;
	end process;

end count_bin_a;
