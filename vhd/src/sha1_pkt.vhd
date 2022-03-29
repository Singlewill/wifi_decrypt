--Filename		: sha1_pkt.vhd
--Author		: kalo
--Description	: something subtype for sha1 use


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

package sha1_pkt is
--	type SHA1_DATA is record
--		key			: std_logic_vector(511 downto 0);
--		pmk			:	std_logic_vector(255 downto 0);
--		round 		:	integer range 0 to 4096;
--		digest_buff	:	std_logic_vector(159 downto 0);
--		resp		: resp_type;
--	end record SHA1_DATA;
	---------------------------- type define ---------------------------------
	constant 	PBKDF2_NUM	: integer := 14;
	--! pbkdf2_sha1传入参数count=4096
	constant 	ITERATIONS	: 	integer := 4096;

	-- 在Calc_cnt不同阶段??赋予K不同�???	
	--	0 <= Calc_cnt <= 19   	----> K = 0x5A827999
	-- 	20 <= Calc_cnt <= 39  	----> K = 0x6ED9EBA1
	-- 	40 <= Calc_cnt <= 59	----> K = 0x8F1BBCDC
	--  60 <= Calc_cnt <= 79	----> K = 0xCA62C1D6
	constant 	K0        	: std_logic_vector(31 downto 0):= X"5A827999";
	constant  	K1        	: std_logic_vector(31 downto 0):= X"6ED9EBA1";
	constant  	K2        	: std_logic_vector(31 downto 0):= X"8F1BBCDC";
	constant  	K3        	: std_logic_vector(31 downto 0):= X"CA62C1D6";

	constant  	H0_INIT     : std_logic_vector(31 downto 0):= X"67452301";
	constant  	H1_INIT     : std_logic_vector(31 downto 0):= X"EFCDAB89";
	constant  	H2_INIT     : std_logic_vector(31 downto 0):= X"98BADCFE";
	constant  	H3_INIT   	: std_logic_vector(31 downto 0):= X"10325476";
	constant  	H4_INIT   	: std_logic_vector(31 downto 0):= X"C3D2E1F0";
	---------------------------------------------------------------------------


	subtype 	BYTE_TYPE 		is std_logic_vector(7 downto 0);
	type      	BYTE_VECTOR    is array (integer range <>) of BYTE_TYPE;
	subtype 	WORD_TYPE 		is std_logic_vector(31 downto 0);
	type      	WORD_VECTOR    is array (integer range <>) of WORD_TYPE;

	type 		HMAC_DATA		is array (integer range <>) of std_logic_vector(511 downto 0);
	type 		HMAC_DATA_LEN		is array(integer range <>) of std_logic_vector(7 downto 0);

	--! sha1的四个阶段
	type 		CALC_STATES is  (CALC_00_19, CALC_20_39, CALC_40_59, CALC_60_79);

	type PASSPHRASE_VECTOR is array(PBKDF2_NUM - 1 downto 0) of std_logic_vector(511 downto 0);
	type PMK_VECTOR is array(PBKDF2_NUM - 1 downto 0) of std_logic_vector(255 downto 0);


	--! ptk各成员位6字节,128	
	subtype KCK_DATA	is	std_logic_vector(127 downto 0);
	--subtype KEK_DATA	is		std_logic_vector(127 downto 0);
	--subtype TK_DATA	is		std_logic_vector(127 downto 0);


	---------------------------------------------------------------------------
	--! 				FUNCTION
	---------------------------------------------------------------------------

	--------------------------------------------------------------------------
	-- Rotl : 将X循环左移N位
	--------------------------------------------------------------------------
	function  Rotl(X:std_logic_vector;N:integer) return std_logic_vector;

end sha1_pkt;
	


	----------------------package body for other types------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;
package body sha1_pkt is 
	function  Rotl(X:std_logic_vector;N:integer) return std_logic_vector is
		alias    result  :    std_logic_vector(X'length-1 downto 0) is X;
	begin
		--return X(X'high-N downto X'low) & X(X'high   downto X'high-N+1);
		return result(result'high-N downto result'low) & result(result'high   downto result'high-N+1);
	end function;

end sha1_pkt;
