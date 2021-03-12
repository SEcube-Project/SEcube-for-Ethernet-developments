library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Define here all constants related to  the  LAN9211 (e.g.
-- register addresses, bitfields, etc.)

package LAN9211_CONSTANTS is

constant	LAN9211_DATA_WIDTH		: integer	:= 16;
constant	LAN9211_ADDR_WIDTH		: integer	:= 7;

---------------------------------------------------------------------------------
---------------------------- LAN9211 READ CYCLE TIMINGS -------------------------
---------------------------------------------------------------------------------
-- See LAN9211 Datasheet, Table 6-3 and 6-4

constant	LAN9211_PIORD_Tasu		: time		:=  0 ns;
constant	LAN9211_PIORD_Tcsdv		: time		:= 30 ns;
constant	LAN9211_PIORD_Tdoff		: time		:=  7 ns;
constant	LAN9211_PIORD_Tcsh		: time		:= 13 ns;
constant	LAN9211_PIORD_Tadv		: time		:= 40 ns;
constant	LAN9211_PIORD_Tacyc		: time		:= 45 ns;

---------------------------------------------------------------------------------
---------------------------- LAN9211 WRITE CYCLE TIMINGS -------------------------
---------------------------------------------------------------------------------
-- See LAN9211 Datasheet, Table 6-3
constant LAN9211_PIOWR_Tasu     : time := 0 ns;
constant LAN9211_PIOWR_Tdsu     : time := 7 ns;
constant LAN9211_PIOWR_Tcsl		: time := 32 ns;
constant LAN9211_PIOWR_Tcsh		: time := 13 ns;
---------------------------------------------------------------------------------
--------------------------- LAN9211 Hard. RESET TIMINGS -------------------------
---------------------------------------------------------------------------------
constant	LAN9211_HRST_PULSEWIDTH : time		:= 30 ns;

---------------------------------------------------------------------------------
------------------------------ LAN9211  CSR REGISTERs  MAP   --------------------
---------------------------------------------------------------------------------
-- See LAN9211 Datasheet,Table 5-1

constant	LAN9211_REG_OFFSET		: integer	:= 16#00#;	-- Offset start -> 0x50

constant	LAN9211_REG_IDV_REV		: integer	:= 16#50#;  -- 0x50
constant	LAN9211_REG_IRQ_CFG		: integer	:= 16#54#;  -- 0x54
constant	LAN9211_REG_INT_STS		: integer	:= 16#58#;  -- 0x58
constant	LAN9211_REG_INT_EN		: integer	:= 16#5C#;  -- 0x5C
------------------------------------------------------------ ADDRESS 0x60 -> Reserved
constant	LAN9211_REG_BYTE_TEST	: integer	:= 16#64#;  -- 0x64
constant	LAN9211_REG_FIFO_INT	: integer	:= 16#68#;  -- 0x68
constant	LAN9211_REG_RX_CFG		: integer	:= 16#6C#;  -- 0x6C
constant	LAN9211_REG_TX_CFG		: integer	:= 16#70#;  -- 0x70
constant	LAN9211_REG_HW_CFG		: integer	:= 16#74#;  -- 0x74
constant	LAN9211_REG_RX_DP_CTL	: integer	:= 16#78#;  -- 0x78
constant	LAN9211_REG_RX_FIFO_INF : integer	:= 16#80#;  -- 0x80
constant	LAN9211_REG_TX_FIFO_INF	: integer	:= 16#84#;  -- 0x84
constant	LAN9211_REG_GPIO_CFG	: integer	:= 16#88#;  -- 0x88
constant	LAN9211_REG_GPT_CFG		: integer	:= 16#8C#;  -- 0x8C
constant	LAN9211_REG_GPT_CNT		: integer	:= 16#90#;  -- 0x90
------------------------------------------------------------ ADDRESS 0x94 -> Reserved
constant	LAN9211_REG_WORD_SWAP	: integer	:= 16#98#;  -- 0x98
constant	LAN9211_REG_FREE_RUN	: integer	:= 16#9C#;  -- 0x9C
constant	LAN9211_REG_RX_DROP		: integer	:= 16#A0#;  -- 0xA0
constant	LAN9211_REG_MAC_CSR_CMD : integer	:= 16#A4#;  -- 0xA4
constant	LAN9211_REG_MAC_CSR_DATA : integer 	:= 16#A8#;  -- 0xA8
constant	LAN9211_REG_AFC_CFG		: integer	:= 16#AC#;  -- 0xAC
constant	LAN9211_REG_E2P_CMD		: integer	:= 16#B0#;  -- 0xB0
constant	LAN9211_REG_E2P_DATA	: integer	:= 16#B4#;  -- 0xB4
------------------------------------------------------------- ADDRESS 0xB8 - 0xFC -> Reserved
constant	LAN9211_TX_DATAFIFO_PORT : integer	:= 16#20#;  -- 0x20


---------------------------------------------------------------------------------
-------------------------- LAN9211  CSR  DEFAULT VALUES -------------------------
---------------------------------------------------------------------------------
-- Note: reported only those default values that are different from all 0s
-- See LAN9211 Datasheet,Table 5-1


-- ID_REV register
constant	LAN9211_DEF_ID_REV_H		: std_logic_vector(15 downto 0)	:= x"9211";
constant	LAN9211_DEF_ID_REV_L		: std_logic_vector(15 downto 0) := x"0000";
-- BYTE_TEST register
constant	LAN9211_DEF_BYTE_TEST_H		: std_logic_vector(15 downto 0) := x"8765";
constant	LAN9211_DEF_BYTE_TEST_L		: std_logic_vector(15 downto 0) := x"4321";
-- FIFO_INT register
constant	LAN9211_DEF_FIFO_INT_H		: std_logic_vector(15 downto 0)	:= x"4800";
constant	LAN9211_DEF_FIFO_INT_L		: std_logic_vector(15 downto 0)	:= x"0000";
-- HW_CFG register
constant	LAN9211_DEF_HW_CFG_H		: std_logic_vector(15 downto 0)	:= x"0005";
constant	LAN9211_DEF_HW_CFG_L		: std_logic_vector(15 downto 0)	:= x"0000";
-- TX_FIFO_INF register
constant	LAN9211_DEF_TX_FIFO_INF_H	: std_logic_vector(15 downto 0)	:= x"0000";
constant	LAN9211_DEF_TX_FIFO_INF_L	: std_logic_vector(15 downto 0)	:= x"1200";
-- GPT_CFG register
constant	LAN9211_DEF_GPT_CFG_H		: std_logic_vector(15 downto 0)	:= x"0000";
constant	LAN9211_DEF_GPT_CFG_L		: std_logic_vector(15 downto 0)	:= x"FFFF";
-- GPT_CNT register
constant	LAN9211_DEF_GPT_CNT_H		: std_logic_vector(15 downto 0)	:= x"0000";
constant	LAN9211_DEF_GPT_CNT_L		: std_logic_vector(15 downto 0)	:= x"FFFF";


end package LAN9211_CONSTANTS;