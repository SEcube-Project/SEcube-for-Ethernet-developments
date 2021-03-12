#include <eth_smb.h>
#include "lan9211.h"
#include "inttypes.h"
#include "stm32f4xx_hal.h"
#include "stm32f4xx_hal_tim.h"
#include <string.h>
#include "misc.h"

#define FIFO_SIZE  0x40000
#define DEFAULT_MAC_ADDRESS_HIGH		((uint64_t)0x00aa)
#define DEFAULT_MAC_ADDRESS_LOW			((uint64_t)0xbbccddee)

#define ADDITIONAL_SIZE 14
#define MAC_ADDR_SIZE 6


static uint16_t packet_tag = 0x0;

TIM_Base_InitTypeDef TIM2_Init_Struct;
TIM_HandleTypeDef TIM2_Handle_Struct;
NVIC_InitTypeDef nvicStructure;


void GetMAC_Reg(uint8_t idx, uint32_t *data) {
	uint32_t mac_cmd;
	uint32_t dummy;

	ETH_SMB_PIORead(MAC_CSR_CMD, &mac_cmd);
	while((mac_cmd & MAC_CSR_CMD_CSR_BUSY) == MAC_CSR_CMD_CSR_BUSY) {
		ETH_SMB_PIORead(BYTE_TEST, &dummy);
		ETH_SMB_PIORead(MAC_CSR_CMD, &mac_cmd);
	}

	mac_cmd = MAC_CSR_CMD_CSR_BUSY | MAC_CSR_CMD_RNW | ((uint32_t)idx);

	ETH_SMB_PIOWrite(MAC_CSR_CMD, mac_cmd);
	ETH_SMB_PIORead(MAC_CSR_CMD, &mac_cmd);

	while((mac_cmd & MAC_CSR_CMD_CSR_BUSY) == MAC_CSR_CMD_CSR_BUSY) {
		ETH_SMB_PIORead(BYTE_TEST, &dummy);
		ETH_SMB_PIORead(MAC_CSR_CMD, &mac_cmd);
	}
	ETH_SMB_PIORead(MAC_CSR_DATA, data);
}

void SetMAC_Reg(uint8_t idx, uint32_t data) {
	uint32_t mac_cmd;
	uint32_t dummy;

	ETH_SMB_PIORead(MAC_CSR_CMD, &mac_cmd);
	while((mac_cmd & MAC_CSR_CMD_CSR_BUSY) == MAC_CSR_CMD_CSR_BUSY) {
		ETH_SMB_PIORead(BYTE_TEST, &dummy);
		ETH_SMB_PIORead(MAC_CSR_CMD, &mac_cmd);
	}

	mac_cmd = MAC_CSR_CMD_CSR_BUSY | ((uint32_t) idx);

	ETH_SMB_PIOWrite(MAC_CSR_DATA, data);
	ETH_SMB_PIOWrite(MAC_CSR_CMD, mac_cmd);

	ETH_SMB_PIORead(MAC_CSR_CMD, &mac_cmd);
	while((mac_cmd & MAC_CSR_CMD_CSR_BUSY) == MAC_CSR_CMD_CSR_BUSY) {
		ETH_SMB_PIORead(BYTE_TEST, &dummy);
		ETH_SMB_PIORead(MAC_CSR_CMD, &mac_cmd);
	}
}

void GetPHY_Reg(uint8_t idx, uint32_t *data) {
	uint32_t temp;

	GetMAC_Reg(MAC_MIIACC, &temp);
	while ((temp & (MAC_MIIACC_MII_BUSY)) == MAC_MIIACC_MII_BUSY) {
		GetMAC_Reg(MAC_MIIACC, &temp);
	}

	temp = 0x00000800;
	temp |= (((uint32_t)idx) << 6) ;
	SetMAC_Reg(MAC_MIIACC, temp);
	while ((temp & (MAC_MIIACC_MII_BUSY)) == MAC_MIIACC_MII_BUSY) {
		GetMAC_Reg(MAC_MIIACC, &temp);
	}

	GetMAC_Reg(MAC_MIIDATA, data);
}

void SetPHY_Reg(uint8_t idx, uint32_t data) {
	uint32_t temp;

	GetMAC_Reg(MAC_MIIACC, &temp);
	while ((temp & (MAC_MIIACC_MII_BUSY)) == MAC_MIIACC_MII_BUSY) {
		GetMAC_Reg(MAC_MIIACC, &temp);
	}
	SetMAC_Reg(MAC_MIIDATA, data);
	temp = 1 << 11;
	temp |= ((idx << 6) | MAC_MIIACC_MII_WRITE) ;
	SetMAC_Reg(MAC_MIIACC, temp);
	while ((temp & (MAC_MIIACC_MII_BUSY)) == MAC_MIIACC_MII_BUSY) {
		GetMAC_Reg(MAC_MIIACC, &temp);
	}
}

uint8_t lan9211_init() {
		uint32_t data, dummy, data1, timeout;
		char debugMsg[100+1];
		ETH_SMB_PIORead(BYTE_TEST, &data);

		// dummy read on IDRev
		ETH_SMB_PIORead(ID_REV, &data);
		// write BYTE_TEST until device is ready
		ETH_SMB_PIORead(HW_CFG, &data);
		data |= HW_CFG_SRST;
		ETH_SMB_PIOWrite(HW_CFG, data);
		HAL_Delay(10);

		ETH_SMB_PIORead(PWR_MGMT, &data);

		if((data & PWR_MGMT_PM_MODE_MSK) != 0) {
			ETH_SMB_PIOWrite(BYTE_TEST, data);
			ETH_SMB_PIORead(PWR_MGMT, &data);
			while((data & PWR_MGMT_PME_READY) != PWR_MGMT_PME_READY) {
				data = 0;
				ETH_SMB_PIOWrite(BYTE_TEST, data);
				ETH_SMB_PIORead(PWR_MGMT, &data);
			}
		}

		data = 0x008c46af;
		ETH_SMB_PIOWrite(AFC_CFG, data);
		ETH_SMB_PIORead(AFC_CFG, &data);

		// turn on LEDS
		ETH_SMB_PIORead(GPIO_CFG, &data);
		data |= 0x70000000;
		ETH_SMB_PIOWrite(GPIO_CFG, data);
		ETH_SMB_PIORead(GPIO_CFG, &data);

		// disable and clear interrupts
		data = 0x0;
		ETH_SMB_PIOWrite(INT_EN, data);
		ETH_SMB_PIORead(INT_EN, &data);
		data = 0xFFFFFFFF;
		ETH_SMB_PIOWrite(INT_STS, data);
		ETH_SMB_PIORead(INT_STS, &data);
		data = 0x1;
		ETH_SMB_PIOWrite(IRQ_CFG, data);
		ETH_SMB_PIORead(IRQ_CFG, &data);

		SetMAC_Reg(MAC_FLOW, 0xffff0002);

		/****/
		GetMAC_Reg(MAC_CR, &data);

		// set MAC ADDRESSES
		data = (uint32_t)DEFAULT_MAC_ADDRESS_HIGH;
		SetMAC_Reg(2, data);
		GetMAC_Reg(2, &data);
		data = (uint32_t)DEFAULT_MAC_ADDRESS_LOW;
		SetMAC_Reg(3, data);
		GetMAC_Reg(3, &data);

		ETH_SMB_PIORead(TX_CFG, &data);
		while((data & (TX_CFG_STOP_TX | TX_CFG_TX_ON)) == (TX_CFG_TX_ON | TX_CFG_STOP_TX)) {
			ETH_SMB_PIORead(TX_CFG, &data);
		}
		data |= (TX_CFG_TXD_DUMP|TX_CFG_TXS_DUMP);
		ETH_SMB_PIOWrite(TX_CFG, data);
		ETH_SMB_PIORead(BYTE_TEST, &dummy);
		ETH_SMB_PIORead(TX_CFG, &data);
		while((data & (TX_CFG_TXD_DUMP | TX_CFG_TXS_DUMP)) == (TX_CFG_TXD_DUMP | TX_CFG_TXS_DUMP)) {
			ETH_SMB_PIORead(TX_CFG, &data);
		}

		// dump RX FIFO
		ETH_SMB_PIORead(RX_CFG, &data);
		data |= RX_CFG_FORCE_DISCARD;
		ETH_SMB_PIOWrite(RX_CFG, data);
		ETH_SMB_PIORead(RX_CFG, &data);
		while ((data & RX_CFG_FORCE_DISCARD) == RX_CFG_FORCE_DISCARD ){
			ETH_SMB_PIORead(RX_CFG, &data);
		}

		// configure RX_CFG register
		ETH_SMB_PIORead(RX_CFG, &data);
		data |= RX_CFG_END_ALIGN4 ;
		ETH_SMB_PIOWrite(RX_CFG, data);

		// set Must Be On (MBO)
		ETH_SMB_PIORead(HW_CFG, &data);
		data |= HW_CFG_MBO;
		ETH_SMB_PIOWrite(HW_CFG, data);

		// get MAC_CR default value
		GetMAC_Reg(MAC_CR, &data);
		// TX and RX enable
		data |= MAC_CR_TXEN;
		data |= MAC_CR_RXEN;
		// disable promiscuous mode
		//data &= (~MAC_CR_PRMS);
		SetMAC_Reg(MAC_CR, data);
		GetMAC_Reg(MAC_CR, &data);

		// manage RX and TX interrupts
		ETH_SMB_PIORead(FIFO_INT, &data);
		data = (data & 0xffff0000) | 0x00000001;
		ETH_SMB_PIOWrite(FIFO_INT, data);

		ETH_SMB_PIORead(INT_EN, &data);
		data|= (INT_EN_RSFL_INT_EN | INT_EN_RXE_INT_EN | INT_EN_RXDFH_INT_EN | INT_EN_RSFF_INT_EN);
		ETH_SMB_PIOWrite(INT_EN, data);

		ETH_SMB_PIORead(IRQ_CFG, &data);
		data |= IRQ_CFG_ENABLE;
		ETH_SMB_PIOWrite(IRQ_CFG, data);

		// PHY configuration
		SetPHY_Reg(PHY_BCR, PHY_BCR_RST);
		timeout = PHY_TIMEOUT;
		HAL_Delay(50);	// > 50ms
		GetPHY_Reg(PHY_BCR, &data);
		while(timeout-- && ( data & PHY_BCR_RST))
			{
				GetPHY_Reg(PHY_BCR, &data);
				HAL_Delay(1);
			}
		if (timeout == 0) {
			return 2;
		}

		GetPHY_Reg(PHY_ANAR, &data);
		data &= ~PHY_ANAR_PAUSE_OP_MSK;
		data |= PHY_ANAR_PAUSE_OP_BOTH;
		data |= (PHY_ANAR_10_FDPLX | PHY_ANAR_10_ABLE | PHY_ANAR_100_TX_FDPLX | PHY_ANAR_100_TX_ABLE);
		SetPHY_Reg(PHY_ANAR, data);

		HAL_Delay(2);
		GetPHY_Reg(PHY_BCR, &data);
		data |= (PHY_BCR_SS | PHY_BCR_FDPLX);
		SetPHY_Reg(PHY_BCR, data);
		HAL_Delay(2);

		// start autonegotiation
		GetPHY_Reg(PHY_BCR, &data);
		data |= (PHY_BCR_ANE | PHY_BCR_RSTAN);
		SetPHY_Reg(PHY_BCR, data);
		HAL_Delay(2);

		timeout = PHY_TIMEOUT;
		GetPHY_Reg(PHY_BSR, &data);
		while((timeout--) && (( data & PHY_BSR_ANC) == 0)) {
			HAL_Delay(500);
			GetPHY_Reg(PHY_BSR, &data);
		}

		if ((data & PHY_BSR_ANC) == 0) {

			return 3;
		}

		if ((data & PHY_BSR_LINK_STATUS) == 0) {
			return 4;
		}

		GetPHY_Reg(PHY_PHYSCSR, &data);
		switch ((data & PHY_PHYSCSR_SPEED_MSK) >> 2) {
			  case 0x01:
				   strcpy(debugMsg, "10BaseT, half duplex");
					break;
			  case 0x02:
					strcpy(debugMsg, "100BaseTX, half duplex");
					break;
			  case 0x05:
					strcpy(debugMsg, "10BaseT, full duplex");
					break;
			  case 0x06:
					strcpy(debugMsg, "100BaseTX, full duplex");
					break;
			  default:
					strcpy(debugMsg, "Unknown");
					break;
		}

		GetPHY_Reg(PHY_ANAR, &data);
		GetPHY_Reg(PHY_ANLPAR, &data1);
		if ((data & data1) & 0x0140) {
			GetMAC_Reg(MAC_CR, &data);
			SetMAC_Reg(MAC_CR, (data | 0x00100000));
		}

		/* enable transmitter */
		lan9211_CSR_read(TX_CFG, &data);
		data |= (TX_CFG_TX_ON | TX_CFG_TXSAO);
		lan9211_CSR_write(TX_CFG, data);
		lan9211_CSR_read(TX_CFG, &data);

		GetMAC_Reg(MAC_CR, &data);

		return 0;
}

int lan9211_receiveFrame(uint8_t *buffer) {
	uint32_t rx_data_tmp;
	uint32_t data, count, int_sts;
	uint32_t rx_status_port;
	uint32_t rx_frame_length;

	lan9211_CSR_read(INT_STS, &int_sts);
	lan9211_CSR_read(RX_FIFO_INF, &data);

	count = 0;

	if ((data & 0x00ff0000) != 0) {
		lan9211_CSR_read(RX_STATUS_FIFO_PORT, &rx_status_port);
		rx_frame_length = (rx_status_port & 0x3FFF0000) >> 16;

		// CHECKING ERRORS...

		if(rx_status_port & 0x4000000) {
			// FILTERING FAIL
			return -1;
		}
		if(rx_status_port & 0x00008000) {
			// ERROR STATUS
			return -2;
		}
		if(rx_status_port & 0x00001000) {
			// LENGTH ERROR
			return -3;
		}
		if(rx_status_port & 0x00000080) {
			// FRAME TOO LONG
			return -4;
		}
		if(rx_status_port & 0x00000040) {
			// LATE COLLISION
			return -5;
		}
		if(rx_status_port & 0x00000010) {
			// WATCHDOG TIMEOUT
			return -6;
		}
		if(rx_status_port & 0x00000008) {
			// MII ERROR
			return -7;
		}
		if(rx_status_port & 0x00000004) {
			// DRIBBLING BIT
			return -8;
		}
		if(rx_status_port & 0x00000002) {
			// CRC ERROR
			return -9;
		}

		while(count < rx_frame_length) {
			lan9211_CSR_read(RX_FIFO_PORT, &rx_data_tmp);

			buffer[count] = (rx_data_tmp & 0xFF);
			count++;
			if (count >= rx_frame_length) {
				break;
			}
			buffer[count] = (rx_data_tmp & 0x0000FF00) >> 8;
			count++;
			if (count >= rx_frame_length) {
				break;
			}

			buffer[count] = (rx_data_tmp & 0x00FF0000) >> 16;
			count++;
			if (count >= rx_frame_length) {
				break;
			}
			buffer[count] = (rx_data_tmp & 0xFF000000) >> 24;
			count++;
		}
	}
	else {
		return 0;
	}

	return count;
}

int lan9211_sendFrame(const uint8_t *frame, uint16_t length) {
	uint8_t eth_frame[1518];
	int i, frame_byte = 0;
	int padding;
	uint32_t status;
	uint32_t data, tx_cmd_a, tx_cmd_b;
	nvicStructure.NVIC_IRQChannelCmd = DISABLE;

	for(i = 0; i < length; i++) {
		eth_frame[frame_byte] = frame[i];
		frame_byte++;
	}

	padding = frame_byte%4;
	for(i = 0; i < padding; i++) {
		eth_frame[frame_byte + i] = 0xE; // pad
	}

	tx_cmd_a = (3 << 12) | (frame_byte);
	tx_cmd_b = (((uint32_t)packet_tag) << 16) | (frame_byte);

	ETH_SMB_PIOWrite(TX_FIFO_PORT, tx_cmd_a);
	ETH_SMB_PIOWrite(TX_FIFO_PORT, tx_cmd_b);

	for(i = 0; i < (frame_byte + padding); i+=4) {
		data=(((uint32_t)eth_frame[i+3]) << 24) | (((uint32_t)eth_frame[i+2]) << 16) |
				(((uint32_t)eth_frame[i+1]) << 8) | (((uint32_t)eth_frame[i]));
		ETH_SMB_PIOWrite(TX_FIFO_PORT,data);
	}

	nvicStructure.NVIC_IRQChannelCmd = ENABLE;

	// control TX_STATUS_FIFO
	ETH_SMB_PIORead(TX_STATUS_FIFO_PORT, &status);
	if ((status & 0xFFFF) != 0) {
		return -1;
	}
	else if ((status >> 16) != packet_tag) {
		return -1;
	}
	else {
		packet_tag++;
		return length;
	}

}

void lan9211_CSR_read(uint16_t lan9211_reg, uint32_t *data) {
	 //nvicStructure.NVIC_IRQChannelCmd = DISABLE;
	ETH_SMB_PIORead(lan9211_reg, data);
	// nvicStructure.NVIC_IRQChannelCmd = ENABLE;
}

void lan9211_CSR_write(uint16_t lan9211_reg, uint32_t data) {
	 //nvicStructure.NVIC_IRQChannelCmd = DISABLE;
	ETH_SMB_PIOWrite(lan9211_reg, data);
//	 nvicStructure.NVIC_IRQChannelCmd = ENABLE;
}

void CSR_regsDump(){
	ETH_SMB_PIORead(ID_REV, &(regs.ID_REV_REG));
	ETH_SMB_PIORead(IRQ_CFG, &(regs.IRQ_CFG_REG));
	ETH_SMB_PIORead(INT_STS, &(regs.INT_STS_REG));
	ETH_SMB_PIORead(INT_EN, &(regs.INT_EN_REG));
	ETH_SMB_PIORead(BYTE_TEST, &(regs.BYTE_TEST_REG));
	ETH_SMB_PIORead(FIFO_INT, &(regs.FIFO_INT_REG));
	ETH_SMB_PIORead(RX_CFG, &(regs.RX_CFG_REG));
	ETH_SMB_PIORead(TX_CFG, &(regs.TX_CFG_REG));
	ETH_SMB_PIORead(HW_CFG, &(regs.HW_CFG_REG));
	ETH_SMB_PIORead(RX_DP_CTL, &(regs.RX_DP_CTL_REG));
	ETH_SMB_PIORead(RX_FIFO_INF, &(regs.RX_FIFO_INF_REG));
	ETH_SMB_PIORead(TX_FIFO_INF, &(regs.TX_FIFO_INF_REG));
	//ETH_SMB_PIORead(PMT_CTRL, &(regs.PMT_CTRL_REG));
	ETH_SMB_PIORead(GPIO_CFG, &(regs.GPIO_CFG_REG));
	ETH_SMB_PIORead(GPT_CFG, &(regs.GPT_CFG_REG));
	ETH_SMB_PIORead(GPT_CNT, &(regs.GPT_CNT_REG));
	//ETH_SMB_PIORead(WORD_SWAP, &(regs.WORD_SWAP_REG));
	ETH_SMB_PIORead(FREE_RUN, &(regs.FREE_RUN_REG));
	ETH_SMB_PIORead(RX_DROP, &(regs.RX_DROP_REG));
	ETH_SMB_PIORead(MAC_CSR_CMD, &(regs.MAC_CSR_CMD_REG));
	ETH_SMB_PIORead(MAC_CSR_DATA, &(regs.MAC_CSR_DATA_REG));
	ETH_SMB_PIORead(AFC_CFG, &(regs.AFC_CFG_REG));
	//ETH_SMB_PIORead(E2P_CMD_REG, &(regs.E2P_CMD_REG_REG));
	//ETH_SMB_PIORead(E2P_DATA_REG, &(regs.E2P_DATA_REG_REG));
}
