/**
 *  \file lan9211.h
 *  \author Alberto Carboni, Alessio Ciarcià, Jacopo Grecuccio, Lorenzo Zaia
 *  \brief High-level driver for communication between CPU and LAN9211 in an IP-Manager-based environment
 */
#ifndef SMSC9211_H
#define SMSC9211_H

#include "inttypes.h"
#include "string.h"

/**** DEFINITIONS ****/
#define 	MAC_TIMEOUT 		200
#define 	PHY_TIMEOUT 		200
#define 	FALSE				0
#define 	TRUE				1


/******************************************************************************
 *                            LAN9211 MEMORY MAP
 ******************************************************************************/
/**** MAC CONTROL/STATUS REGISTERS (directly addressable registers) ****/
/** \defgroup LAN9211 PIO registers
 * @{
 */
/** \name LAN9211 PIO registers */
///@{
#define RX_FIFO_PORT                	(uint16_t)(0x00)
#define RX_FIFO_ALIAS_PORTS 			(uint16_t)(0x4)
#define TX_FIFO_PORT					(uint16_t)(0x20)
#define TX_FIFO_ALIAS_PORTS 			(uint16_t)(0x24)
#define RX_STATUS_FIFO_PORT 			(uint16_t)(0x40)
#define RX_STATUS_FIFO_PEEK 			(uint16_t)(0x44)
#define TX_STATUS_FIFO_PORT 			(uint16_t)(0x48)
#define TX_STATUS_FIFO_PEEK 			(uint16_t)(0x4C)
#define TX_STATUS_FIFO_ES 				(uint16_t)(0x8000)
#define TX_STATUS_FIFO_TAG_MSK			(uint16_t)(0xffff0000)

#define ID_REV																									(uint16_t)(0x50)
#define		ID_REV_ID_MASK																						(0xFFFF0000)
#define		ID_REV_REV_MASK																						(0x0000FFFF)

#define IRQ_CFG 																								(uint16_t)(0x54)
#define 	IRQ_CFG_MASTER_INT																				(0x00001000)
#define 	IRQ_CFG_ENABLE																						(0x00000100)
#define 	IRQ_CFG_IRQ_POL_HIGH																			(0x00000010)
#define 	IRQ_CFG_IRQ_TYPE_PUPU																			(0x00000001)

#define INT_STS 																								(uint16_t)(0x58)
#define 	INT_STS_SW_INT																						(0x80000000)
#define 	INT_STS_TXSTOP_INT																				(0x02000000)
#define 	INT_STS_RXSTOP_INT																				(0x01000000)
#define 	INT_STS_RXDFH_INT 																				(0x00800000)
#define 	INT_STS_TIOC_INT  																				(0x00200000)
#define 	INT_STS_GPT_INT 																					(0x00080000)
#define 	INT_STS_PHY_INT 																					(0x00040000)
#define 	INT_STS_PMT_INT 																					(0x00020000)
#define 	INT_STS_TXSO_INT  																				(0x00010000)
#define 	INT_STS_RWT_INT 																					(0x00008000)
#define 	INT_STS_RXE_INT 																					(0x00004000)
#define 	INT_STS_TXE_INT 																					(0x00002000)
#define 	INT_STS_TDFO_INT  																				(0x00000400)
#define 	INT_STS_TDFA_INT  																				(0x00000200)
#define 	INT_STS_TSFF_INT  																				(0x00000100)
#define 	INT_STS_TSFL_INT  																				(0x00000080)
#define 	INT_STS_RDFO_INT  																				(0x00000040)
#define 	INT_STS_RSFF_INT  																				(0x00000010)
#define 	INT_STS_RSFL_INT  																				(0x00000008)
#define 	INT_STS_GPIO2_INT 																				(0x00000004)
#define 	INT_STS_GPIO1_INT 																				(0x00000002)
#define 	INT_STS_GPIO0_INT 																				(0x00000001)

#define INT_EN						(uint16_t)(0x5C)
#define 	INT_EN_SW_INT_EN  		(0x80000000)
#define 	INT_EN_TXSTOP_INT_EN	(0x02000000)
#define 	INT_EN_RXSTOP_INT_EN	(0x01000000)
#define 	INT_EN_RXDFH_INT_EN 	(0x00800000)
#define 	INT_EN_TIOC_INT_EN		(0x00200000)
#define 	INT_EN_GPT_INT_EN 		(0x00080000)
#define 	INT_EN_PHY_INT_EN 		(0x00040000)
#define 	INT_EN_PMT_INT_EN 		(0x00020000)
#define 	INT_EN_TXSO_INT_EN		(0x00010000)
#define 	INT_EN_RWT_INT_EN 		(0x00008000)
#define 	INT_EN_RXE_INT_EN 		(0x00004000)
#define 	INT_EN_TXE_INT_EN 		(0x00002000)
#define 	INT_EN_TDFO_INT_EN		(0x00000400)
#define 	INT_EN_TDFA_INT_EN		(0x00000200)
#define 	INT_EN_TSFF_INT_EN		(0x00000100)
#define 	INT_EN_TSFL_INT_EN		(0x00000080)
#define 	INT_EN_RDFO_INT_EN		(0x00000040)
#define 	INT_EN_RSFF_INT_EN		(0x00000010)
#define 	INT_EN_RSFL_INT_EN		(0x00000008)
#define 	INT_EN_GPIO2_EN 		(0x00000004)
#define 	INT_EN_GPIO1_EN 		(0x00000002)
#define 	INT_EN_GPIO0_EN 		(0x00000001)

#define BYTE_TEST		  			(uint16_t)(0x64)
#define 	BYTE_TEST_VAL			(0x87654321)

#define FIFO_INT		  			(uint16_t)(0x68)
#define 	FIFO_INT_TDAL_MSK 		(0xFF000000)
#define 	FIFO_INT_TSL_MSK  		(0x00FF0000)
#define 	FIFO_INT_RSL_MSK  		(0x000000FF)

#define RX_CFG						(uint16_t)(0x6C)
#define 	RX_CFG_END_ALIGN4 		(0x00000000)
#define 	RX_CFG_END_ALIGN16		(0x40000000)
#define 	RX_CFG_END_ALIGN32		(0x80000000)
#define 	RX_CFG_FORCE_DISCARD	(0x00008000)
#define 	RX_CFG_RXDOFF_MSK 		(0x00003C00)

#define TX_CFG						(uint16_t)(0x70)
#define 	TX_CFG_TXS_DUMP 		(0x00008000)
#define 	TX_CFG_TXD_DUMP 		(0x00004000)
#define 	TX_CFG_TXSAO			(0x00000004)
#define 	TX_CFG_TX_ON			(0x00000002)
#define 	TX_CFG_STOP_TX			(0x00000001)

#define HW_CFG						(uint16_t)(0x74)
#define 	HW_CFG_MBO		  		(0x00100000)
#define 	HW_CFG_TX_FIF_SZ_MSK	(0x000F0000)
#define 	HW_CFG_BITMD_MSK  		(0x00000004)
#define 	HW_CFG_BITMD_32 		(0x00000004)
#define 	HW_CFG_SRST_TO			(0x00000002)
#define 	HW_CFG_SRST 	  		(0x00000001)

#define RX_DP_CTL		  			(uint16_t)(0x78)
#define 	RX_DP_FFWD		  		(0x80000000)

#define RX_FIFO_INF 	  			(uint16_t)(0x7C)
#define 	RX_FIFO_RXSUSED_MSK 	(0x00FF0000)
#define 	RX_FIFO_RXDUSED_MSK 	(0x0000FFFF)

#define TX_FIFO_INF 	  			(uint16_t)(0x80)
#define 	TX_FIFO_TXSUSED_MSK 	(0x00FF0000)
#define 	TX_FIFO_TDFREE_MSK		(0x0000FFFF)

#define PWR_MGMT		  			(uint16_t)(0x84)
#define 	PWR_MGMT_PM_MODE_MSK	(0x00003000)
#define 	PWR_MGMT_PM_MODE_MSK_LE (0x00000003)
#define 	PWR_MGMT_PM__D0 		(0x00000000)
#define 	PWR_MGMT_PM__D1 		(0x00010000)
#define 	PWR_MGMT_PM__D2 		(0x00020000)
#define 	PWR_MGMT_PHY_RST  		(0x00000400)
#define 	PWR_MGMT_WOL_EN 		(0x00000200)
#define 	PWR_MGMT_ED_EN			(0x00000100)
#define 	PWR_MGMT_PME_TYPE_PUPU	(0x00000040)
#define 	PWR_MGMT_WUPS_MSK 		(0x00000030)
#define 	PWR_MGMT_WUPS_NOWU		(0x00000000)
#define 	PWR_MGMT_WUPS_D2D0		(0x00000010)
#define 	PWR_MGMT_WUPS_D1D0		(0x00000020)
#define 	PWR_MGMT_WUPS_UNDEF 	(0x00000030)
#define 	PWR_MGMT_PME_IND_PUL	(0x00000008)
#define 	PWR_MGMT_PME_POL_HIGH	(0x00000004)
#define 	PWR_MGMT_PME_EN 		(0x00000002)
#define 	PWR_MGMT_PME_READY		(0x00000001)

#define GPIO_CFG		  			(uint16_t)(0x88)
#define 	GPIO_CFG_LEDx_MSK 		(0x70000000)
#define 	GPIO_CFG_LED1_EN  		(0x10000000)
#define 	GPIO_CFG_LED2_EN  		(0x20000000)
#define 	GPIO_CFG_LED3_EN  		(0x40000000)
#define 	GPIO_CFG_GPIOBUFn_MSK	(0x00070000)
#define 	GPIO_CFG_GPIOBUF0_PUPU	(0x00010000)
#define 	GPIO_CFG_GPIOBUF1_PUPU	(0x00020000)
#define 	GPIO_CFG_GPIOBUF2_PUPU	(0x00040000)
#define 	GPIO_CFG_GPDIRn_MSK 	(0x00000700)
#define 	GPIO_CFG_GPIOBUF0_OUT	(0x00000100)
#define 	GPIO_CFG_GPIOBUF1_OUT	(0x00000200)
#define 	GPIO_CFG_GPIOBUF2_OUT	(0x00000400)
#define 	GPIO_CFG_GPIOD_MSK		(0x00000007)
#define 	GPIO_CFG_GPIOD0 		(0x00000001)
#define 	GPIO_CFG_GPIOD1 		(0x00000002)
#define 	GPIO_CFG_GPIOD2 		(0x00000004)

#define GPT_CFG 					(uint16_t)(0x8C)
#define 	GPT_CFG_TIMER_EN  		(0x20000000)
#define 	GPT_CFG_GPT_LOAD_MSK	(0x0000FFFF)

#define	GPT_CNT 					(uint16_t)(0x90)
#define 	GPT_CNT_MSK 	  		(0x0000FFFF)

#define FPGA_REV		  			(uint16_t)(0x94)

#define ENDIAN						(uint16_t)(0x98)
#define 	ENDIAN_BIG		  		(0xFFFFFFFF)

#define FREE_RUN		  			(uint16_t)(0x9C)
#define 	FREE_RUN_FR_CNT_MSK 	(0xFFFFFFFF)

#define RX_DROP 					(uint16_t)(0xA0)
#define 	RX_DROP_RX_DFC_MSK		(0xFFFFFFFF)

#define MAC_CSR_CMD 	  			(uint16_t)(0xA4)
#define 	MAC_CSR_CMD_CSR_BUSY	(0x80000000)
#define 	MAC_CSR_CMD_RNW 		(0x40000000)
#define 	MAC_RD_CMD(Reg)   		((Reg & 0x000000FF) | \
									 (MAC_CSR_CMD_CSR_BUSY | MAC_CSR_CMD_RNW))
#define 	MAC_WR_CMD(Reg)   		((Reg & 0x000000FF) | \
									 (MAC_CSR_CMD_CSR_BUSY))

#define MAC_CSR_DATA				(uint16_t)(0xA8)

#define AFC_CFG 					(uint16_t)(0xAC)
#define 	AFC_CFG_AFC_HI_MSK		(0x00FF0000)
#define 	AFC_CFG_AFC_LO_MSK		(0x0000FF00)

#define E2P_CMD 					(uint16_t)(0xB0)
#define E2P_DATA		  			(uint16_t)(0xB4)
///@}
/** @} */
/**** MAC CONTROL/STATUS REGISTERS (accessed through MAC_CSR_CMD/_DATA registers) ****/
/** \defgroup MAC MAC Registers
 * @{
 */
/** \name MAC registers addresses */
///@{
#define MAC_CR						(uint16_t)(0x01)
#define 	MAC_CR_RXALL			(0x80000000)
#define 	MAC_CR_HBDIS			(0x10000000)
#define 	MAC_CR_RCVOWN			(0x00800000)
#define 	MAC_CR_LOOPBK			(0x00200000)
#define 	MAC_CR_FDPX 	  		(0x00100000)
#define 	MAC_CR_MCPAS			(0x00080000)
#define 	MAC_CR_PRMS 	  		(0x00040000)
#define 	MAC_CR_INVFILT			(0x00020000)
#define 	MAC_CR_PASSBAD			(0x00010000)
#define 	MAC_CR_HFILT			(0x00008000)
#define 	MAC_CR_HPFILT			(0x00002000)
#define 	MAC_CR_LCOLL			(0x00001000)
#define 	MAC_CR_BCAST			(0x00000800)
#define 	MAC_CR_DISRTY			(0x00000400)
#define 	MAC_CR_PADSTR			(0x00000100)
#define 	MAC_CR_BOLMT_MSK  		(0x000000C0)
#define 	MAC_CR_BOLMT_10 		(0x00000000)
#define 	MAC_CR_BOLMT_8			(0x00000040)
#define 	MAC_CR_BOLMT_4			(0x00000080)
#define 	MAC_CR_BOLMT_1			(0x000000C0)
#define 	MAC_CR_DFCHK			(0x00000020)
#define 	MAC_CR_TXEN 	  		(0x00000008)
#define 	MAC_CR_RXEN 	  		(0x00000004)

#define MAC_ADDRH		  			(uint16_t)(0x02)
#define 	MAC_ADDRH_MSK			(0x0000FFFF)

#define MAC_ADDRL		  			(uint16_t)(0x03)
#define 	MAC_ADDRL_MSK			(0xFFFFFFFF)

#define MAC_HASHH		  			(uint16_t)(0x04)
#define 	MAC_HASHH_MSK			(0xFFFFFFFF)

#define MAC_HASHL		  			(uint16_t)(0x05)
#define 	MAC_HASHL_MSK			(0xFFFFFFFF)

#define MAC_MIIACC		  			(uint16_t)(0x06)
#define 	MAC_MIIACC_MII_WRITE	(0x00000002)
#define 	MAC_MIIACC_MII_BUSY 	(0x00000001)
#define 	MAC_MII_RD_CMD(Addr,Reg)	(((Addr & 0x1f) << 11) | \
										 ((Reg & 0x1f)) << 6)
#define 	MAC_MII_WR_CMD(Addr,Reg)	(((Addr & 0x1f) << 11) | \
							  			 ((Reg & 0x1f) << 6) | \
							  			 MAC_MIIACC_MII_WRITE)

#define MAC_MIIDATA 	  			(uint16_t)(0x07)
#define 	MAC_MIIDATA_MSK 		(0x0000FFFF)
#define 	MAC_MII_DATA(Data)		(Data & MAC_MIIDATA_MSK)

#define MAC_FLOW		  			(uint16_t)(0x08)
#define 	MAC_FLOW_FCPT_MSK 		(0xFFFF0000)
#define 	MAC_FLOW_FCPASS 		(0x00000004)
#define 	MAC_FLOW_FCEN			(0x00000002)
#define 	MAC_FLOW_FCBSY			(0x00000001)

#define MAC_VLAN1		  			(uint16_t)(0x09)
#define MAC_VLAN2		  			(uint16_t)(0x0A)
#define MAC_WUFF		  			(uint16_t)(0x0B)

#define MAC_WUCSR		  			(uint16_t)(0x0C)
#define 	MAC_WUCSR_GUE			(0x00000200)
#define 	MAC_WUCSR_WUFR			(0x00000040)
#define 	MAC_WUCSR_MPR			(0x00000020)
#define 	MAC_WUCSR_WUEN			(0x00000004)
#define 	MAC_WUCSR_MPEN			(0x00000002)

#define MAC_COE_CR					(uint16_t)(0x0D)
#define MAC_COE_CR_TXCOE_EN			(0x00010000)
#define MAC_COE_CR_RXCOE_MODE		(0x00000002)
#define MAC_COE_CR_RXCOE_EN			(0x00000001)
///@}
/** @} */

/**** PHY CONTROL/STATUS REGISTERS (accessed through MAC_MIIACC/_MIIDATA registers) ****/
/** \defgroup PHY PHY Registers
 * @{
 */
/** \name PHY register addresses */
///@{
#define PHY_BCR 					(uint16_t)(0x00)
#define 	PHY_BCR_RST 	  		(0x8000)
#define 	PHY_BCR_LOOPBK			(0x4000)
#define 	PHY_BCR_SS		  		(0x2000)
#define 	PHY_BCR_ANE 	  		(0x1000)
#define 	PHY_BCR_PWRDN			(0x0800)
#define 	PHY_BCR_RSTAN			(0x0200)
#define 	PHY_BCR_FDPLX			(0x0100)
#define 	PHY_BCR_COLLTST 		(0x0080)

#define PHY_BSR 					(uint16_t)(0x01)
#define 	PHY_BSR_100_T4_ABLE 	(0x8000)
#define 	PHY_BSR_100_TX_FDPLX	(0x4000)
#define 	PHY_BSR_100_TX_HDPLX	(0x2000)
#define 	PHY_BSR_10_FDPLX  		(0x1000)
#define 	PHY_BSR_10_HDPLX  		(0x0800)
#define 	PHY_BSR_ANC 	  		(0x0020)
#define 	PHY_BSR_REM_FAULT 		(0x0010)
#define 	PHY_BSR_AN_ABLE 		(0x0008)
#define 	PHY_BSR_LINK_STATUS 	(0x0004)
#define 	PHY_BSR_JAB_DET 		(0x0002)
#define 	PHY_BSR_EXT_CAP 		(0x0001)

#define PHY_ID1 					(uint16_t)(0x02)
#define 	PHY_ID1_MSK 	  		(0xFFFF)
#define 	PHY_ID1_LAN9118 		(0x0007)
#define 	PHY_ID1_LAN9218 		(PHY_ID1_LAN9118)

#define PHY_ID2 					(uint16_t)(0x03)
#define 	PHY_ID2_MSK 	  		(0xFFFF)
#define 	PHY_ID2_MODEL_MSK 		(0x03F0)
#define 	PHY_ID2_REV_MSK 		(0x000F)
#define 	PHY_ID2_LAN9118 		(0xC0D1)
#define 	PHY_ID2_LAN9218 		(0xC0C3)

#define PHY_ANAR		  			(uint16_t)(0x04)
#define 	PHY_ANAR_NXTPG_CAP		(0x8000)
#define 	PHY_ANAR_REM_FAULT		(0x2000)
#define 	PHY_ANAR_PAUSE_OP_MSK	(0x0C00)
#define 	PHY_ANAR_PAUSE_OP_NONE	(0x0000)
#define 	PHY_ANAR_PAUSE_OP_ASLP	(0x0400)
#define 	PHY_ANAR_PAUSE_OP_SLP	(0x0800)
#define 	PHY_ANAR_PAUSE_OP_BOTH	(0x0C00)
#define 	PHY_ANAR_100_T4_ABLE	(0x0200)
#define 	PHY_ANAR_100_TX_FDPLX	(0x0100)
#define 	PHY_ANAR_100_TX_ABLE	(0x0080)
#define 	PHY_ANAR_10_FDPLX 		(0x0040)
#define 	PHY_ANAR_10_ABLE  		(0x0020)

#define PHY_ANLPAR		  			(uint16_t)(0x05)
#define 	PHY_ANLPAR_NXTPG_CAP	(0x8000)
#define 	PHY_ANLPAR_ACK			(0x4000)
#define 	PHY_ANLPAR_REM_FAULT	(0x2000)
#define 	PHY_ANLPAR_PAUSE_CAP	(0x0400)
#define 	PHY_ANLPAR_100_T4_ABLE	(0x0200)
#define 	PHY_ANLPAR_100_TX_FDPLX (0x0100)
#define 	PHY_ANLPAR_100_TX_ABLE	(0x0080)
#define 	PHY_ANLPAR_10_FDPLX 	(0x0040)
#define 	PHY_ANLPAR_10_ABLE		(0x0020)

#define PHY_ANEXPR		  			(uint16_t)(0x06)
#define 	PHY_ANEXPR_PARDET_FAULT (0x0010)
#define 	PHY_ANEXPR_LP_NXTPG_CAP (0x0008)
#define 	PHY_ANEXPR_NXTPG_CAP	(0x0004)
#define 	PHY_ANEXPR_NEWPG_REC	(0x0002)
#define 	PHY_ANEXPR_LP_AN_ABLE	(0x0001)

#define PHY_MCSR		  			(uint16_t)(0x11)
#define 	PHY_MCSR_EDPWRDOWN		(0x2000)
#define 	PHY_MCSR_ENERGYON 		(0x0002)

#define PHY_SPMODES 	  			(uint16_t)(0x12)

#define PHY_CSIR		  			(uint16_t)(0x1B)
#define 	PHY_CSIR_SQEOFF 		(0x0800)
#define 	PHY_CSIR_FEFIEN 		(0x0020)
#define 	PHY_CSIR_XPOL			(0x0010)

#define PHY_ISR 					(uint16_t)(0x1D)
#define 	PHY_ISR_INT7			(0x0080)
#define 	PHY_ISR_INT6			(0x0040)
#define 	PHY_ISR_INT5			(0x0020)
#define 	PHY_ISR_INT4			(0x0010)
#define 	PHY_ISR_INT3			(0x0008)
#define 	PHY_ISR_INT2			(0x0004)
#define 	PHY_ISR_INT1			(0x0002)

#define PHY_IMR 					(uint16_t)(0x1E)
#define 	PHY_IMR_INT7			(0x0080)
#define 	PHY_IMR_INT6			(0x0040)
#define 	PHY_IMR_INT5			(0x0020)
#define 	PHY_IMR_INT4			(0x0010)
#define 	PHY_IMR_INT3			(0x0008)
#define 	PHY_IMR_INT2			(0x0004)
#define 	PHY_IMR_INT1			(0x0002)

#define PHY_PHYSCSR 	  			(uint16_t)(0x1F)
#define 	PHY_PHYSCSR_ANDONE		(0x1000)
#define 	PHY_PHYSCSR_4B5B_EN 	(0x0040)
#define 	PHY_PHYSCSR_SPEED_MSK	(0x001C)
#define 	PHY_PHYSCSR_SPEED_10HD	(0x0004)
#define 	PHY_PHYSCSR_SPEED_10FD	(0x0014)
#define 	PHY_PHYSCSR_SPEED_100HD (0x0008)
#define 	PHY_PHYSCSR_SPEED_100FD (0x0018)
///@}
/** @} */

typedef struct {
	uint32_t ID_REV_REG;
	uint32_t IRQ_CFG_REG;
	uint32_t INT_STS_REG;
	uint32_t INT_EN_REG;
	uint32_t BYTE_TEST_REG;
	uint32_t FIFO_INT_REG;
	uint32_t RX_CFG_REG;
	uint32_t TX_CFG_REG;
	uint32_t HW_CFG_REG;
	uint32_t RX_DP_CTL_REG;
	uint32_t RX_FIFO_INF_REG;
	uint32_t TX_FIFO_INF_REG;
	uint32_t PMT_CTRL_REG;
	uint32_t GPIO_CFG_REG;
	uint32_t GPT_CFG_REG;
	uint32_t GPT_CNT_REG;
	uint32_t WORD_SWAP_REG;
	uint32_t FREE_RUN_REG;
	uint32_t RX_DROP_REG;
	uint32_t MAC_CSR_CMD_REG;
	uint32_t MAC_CSR_DATA_REG;
	uint32_t AFC_CFG_REG;
	uint32_t E2P_CMD_REG;
	uint32_t E2P_DATA_REG;
} CSR_regs;

CSR_regs regs;

// FUNCTION PROTOTYPES
/**
 * @brief  This Function initializes the LAN9211 controller with a default configuration
 * @return Error Code.
 */
uint8_t lan9211_init();
/**
 * @brief This Function is used to read an internal register of the MAC
 * 
 * @param idx The Address of the target MAC register 
 * @param data Pointer to the memory location where the data will be stored
 */
void GetMAC_Reg(uint8_t idx, uint32_t *data);
/**
 * @brief This Function is used to write an internal register of the MAC
 * 
 * @param idx The Address of the target MAC register
 * @param data The Value to be written
 */
void SetMAC_Reg(uint8_t idx, uint32_t data);
/**
 * @brief This Function is used to read an internal register of the PHY
 * 
 * @param idx The Address of the target PHY register
 * @param data Pointer to the memory location where the data will be stored
 */
void GetPHY_Reg(uint8_t idx, uint32_t *data);
/**
 * @brief This Function is used to write an internal register of the PHY
 * 
 * @param idx The Address of the target PHY register
 * @param data The Value to be written
 */
void SetPHY_Reg(uint8_t idx, uint32_t data);
/**
 * @brief This Function is used to write a value into a CSR (Control and Status Register) of the LAN9211.
 * 
 * @param lan9211_reg The address of the target PIO register
 * @param data The Value to be written
 */
void lan9211_CSR_read(uint16_t lan9211_reg, uint32_t *data);
/**
 * @brief This Function is used to read a value into a CSR (Control and Status Register) of the LAN9211.
 * 
 * @param lan9211_reg The address of the target PIO register
 * @param data The value to be written
 */
void lan9211_CSR_write(uint16_t lan9211_reg, uint32_t data);
/**
 * @brief This Function is used to receive an Ethernet frame
 * 
 * @param buffer Th buffer where the receive frame will be stored
 * @return Error Code
 */
int lan9211_receiveFrame(uint8_t *buffer);
/**
 * @brief This Function is used to send an Ethernet frame
 * @param frame Pointer to the frame to send
 * @param length Length of the frame
 */
int lan9211_sendFrame(const uint8_t *frame, uint16_t length);
/**
 * @brief This Function stores all the PIO register's values into the 'regs' struct variable 
 * 
 */
void CSR_regsDump();

#endif //SMSC9211_H
