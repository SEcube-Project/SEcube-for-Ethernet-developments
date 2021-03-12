library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CONSTANTS.all;

-- Define here all constants related to ETH_SMB functionalities  (e.g.
-- opcodes, addresses, etc.)


package ETH_SMB_CONSTANTS is

----------------------------   ETH SMB OPCODES  ---------------------------------
constant	MAIN_OPC_NOP			: std_logic_vector(5 downto 0) := "000000";
constant	MAIN_OPC_CSR_RD			: std_logic_vector(5 downto 0) := "000001";
constant	MAIN_OPC_CSR_WR			: std_logic_vector(5 downto 0) := "000010";
constant	MAIN_OPC_HRST	 		: std_logic_vector(5 downto 0) := "111111";


constant  PIO_OPC_SIZE    : integer := 2;
constant	PIO_OPC_CSR_RD			: std_logic_vector(1 downto 0) := "00";
constant	PIO_OPC_CSR_WR			: std_logic_vector(1 downto 0) := "01";

---------------------------- DATA BUFFER ADDRESSES ------------------------------
-- Address register used to point to the target LAN9211 CSR
constant	ETH_SMB_ADDRREG			: integer	:= 1;

-- Data registers used to exchange  data between the CPU and ETH_SMB
constant 	ETH_SMB_DATAREG_H		: integer	:= 2;	-- Higher 16 bits
constant	ETH_SMB_DATAREG_L		: integer	:= 3;	-- Lower 16 bits

-- Lock register used for polling transactions
constant	ETH_SMB_LOCKREG			: integer	:= 63;

-----------------------------  CONTROL WORDS  -------------------------------------
--Unlock control word for polling transaction
constant	ETH_SMB_UNLOCK_CWD		: std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '1');
constant	ETH_SMB_LOCK_CWD		: std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

------------------------------  TIMING CONSTANTS  --------------------------------
-- READ CYCLE Timing diagram (see LAN9211 datasheet - Table 6-3)

-- Minimum assertion time
constant	rd_Tcsl_WAIT_CYCLES		: integer	:=	6;
-- Minimum deassertion time (between two consecutive reads)
constant	rd_Tcsh_WAIT_CYCLES		: integer	:=	6;
-- Minimum nRD to Data Valid time
constant	rd_Tcsdv_WAIT_CYCLES	: integer	:=	6;
-- Minimum nRD to Data Valid time
constant	rd_Tadv_WAIT_CYCLES		: integer	:=	6;
-- Minimum address setup to nRD valid time
constant	rd_Tasu_WAIT_CYCLES		: integer	:=	6;
-- Minimum address hold time
constant	rd_Tah_WAIT_CYCLES		: integer	:=	0;
-- Minimum data buffer turn on cycles
constant	rd_Tdon_WAIT_CYCLES		: integer	:=	0;
-- Minimum data buffer turn off cycles
constant	rd_Tdoff_WAIT_CYCLES	: integer	:=	2;
-- Minimum data hold time
constant	rd_Tdoh_WAIT_CYCLES		: integer	:=	0;


-- WRITE CYCLE Timing diagram (see LAN9211 datasheet - Table 6-3

constant	wr_Tcsh_WAIT_CYCLES		: integer	:= 6;

constant	wr_Tcsl_WAIT_CYCLES		: integer	:= 6;

constant	hrst_PULSEWIDTH_CYCLES	: integer	:= 3;

---------------------------- PROCEDURE CALLS ------------------------------
------------------------------ MISC ---------------------------------------
constant	TX_MAX_CNT_WIDTH	:	integer := 11;

end package ETH_SMB_CONSTANTS;
