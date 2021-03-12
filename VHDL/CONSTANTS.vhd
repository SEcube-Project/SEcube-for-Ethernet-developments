library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package CONSTANTS is
 	
 	-- SIZES AND NUMBERS
 	constant DATA_WIDTH	 : integer := 16;
	constant ADD_WIDTH	 : integer := 6;
	constant OPCODE_SIZE : integer := 6;
	constant MEM_SIZE	 : integer := 64;
	constant IPADDR_SIZE : integer := 7;
 	
	constant NUM_IPS : integer := 2;
	constant ETH_SMB_ID : integer := 0;
	constant IP_BLINKER_ID : integer := 1;
		
	-- TYPES
	type data_array   is array (NUM_IPS-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
	type addr_array	  is array (NUM_IPS-1 downto 0) of std_logic_vector(ADD_WIDTH-1 downto 0);
	type opcode_array is array (NUM_IPS-1 downto 0) of std_logic_vector(OPCODE_SIZE-1 downto 0);
	
	-- CONTROL WORD FIELDS
	constant I_P_POS    : integer := 9;
	constant ACK_POS	: integer := 8;	
	constant B_E_POS    : integer := 7;
	constant IPADDR_POS : integer := 6; -- downto 0
	
end package CONSTANTS;
