#include <eth_smb.h>

void ETH_SMB_TX(uint8_t frame[], uint16_t array_length, uint32_t txA, uint32_t txB) {
	int i;
	uint16_t word_i;
	FPGA_IPM_UINT8 dBuffAddr;

	// Open TX transaction
	FPGA_IPM_open(ETH_SMB_CORE_ID, OPC_TX_LAN, 0, 0);

	// Write frame length
	FPGA_IPM_write(ETH_SMB_CORE_ID, ETH_SMB_TX_FRAME_LENGTH_REG, array_length+4);

	// Start writing
	dBuffAddr = 2;
	word_i = (uint16_t)(txA & 0x0000FFFF);
	FPGA_IPM_write(ETH_SMB_CORE_ID, dBuffAddr, word_i);
	dBuffAddr++;
	HAL_Delay(50);
	word_i = (uint16_t)((txA & 0xFFFF0000) >> 16);
	FPGA_IPM_write(ETH_SMB_CORE_ID, dBuffAddr, word_i);
	dBuffAddr++;
	HAL_Delay(50);
	word_i = (uint16_t)(txB & 0x0000FFFF);
	FPGA_IPM_write(ETH_SMB_CORE_ID, dBuffAddr, word_i);
	dBuffAddr++;
	HAL_Delay(50);
	word_i = (uint16_t)((txB & 0xFFFF0000) >> 16);
	FPGA_IPM_write(ETH_SMB_CORE_ID, dBuffAddr, word_i);
	dBuffAddr++;
	HAL_Delay(50);

	for(i = 0; i < array_length*2; i += 4) {
		word_i = (((uint16_t)frame[i]) << 8) | ((uint16_t)frame[i+1]);
		FPGA_IPM_write(ETH_SMB_CORE_ID,dBuffAddr,word_i);
		if(dBuffAddr == 62) {
			dBuffAddr = 2;
		}
		else {
			dBuffAddr++;
		}
		HAL_Delay(50);
		word_i = (((uint16_t) frame[i+2]) << 8) | ((uint16_t) frame[i+3]);
		FPGA_IPM_write(ETH_SMB_CORE_ID,dBuffAddr,word_i);
		if(dBuffAddr == 62) {
			dBuffAddr = 2;
		}
		else {
			dBuffAddr++;
		}
		HAL_Delay(50);
	}

	// Close TX transaction
	FPGA_IPM_close(ETH_SMB_CORE_ID);
}

void ETH_SMB_PIORead(uint16_t lan9211_reg, uint32_t *data) {
  FPGA_IPM_DATA polling_semaphore = CPU_LOCK_WORD;
  FPGA_IPM_DATA tmp = 0x1010;

  // Open polling transaction
  FPGA_IPM_open(ETH_SMB_CORE_ID, OPC_CSR_READ, 0, 0);
  FPGA_IPM_write(ETH_SMB_CORE_ID, ETH_SMB_ADDREG, &lan9211_reg);
  FPGA_IPM_write(ETH_SMB_CORE_ID, ETH_SMB_LOCKREG, &polling_semaphore);

  // Wait
  while(polling_semaphore != CPU_UNLOCK_WORD) {
    FPGA_IPM_read(ETH_SMB_CORE_ID, ETH_SMB_LOCKREG, &polling_semaphore);
  }

  // Read result low
  FPGA_IPM_read(ETH_SMB_CORE_ID, ETH_SMB_DATAH, &tmp);
  *data = ((uint32_t)tmp) << 16;

  // Read result high
  FPGA_IPM_read(ETH_SMB_CORE_ID, ETH_SMB_DATAL, &tmp);
  *data = *data | ((uint32_t)tmp);

  // Close polling transaction
  FPGA_IPM_close(ETH_SMB_CORE_ID);
}

void ETH_SMB_PIOWrite(uint16_t lan9211_reg, uint32_t data) {
  FPGA_IPM_DATA polling_semaphore = CPU_LOCK_WORD;
  FPGA_IPM_DATA tmp = 0x1010;
  uint16_t data_high = data >> 16;
  uint16_t data_low = data & 0xFFFF;

  // Open polling transaction
  FPGA_IPM_open(ETH_SMB_CORE_ID, OPC_CSR_WRITE, 0, 0);

  // Write reg address
  FPGA_IPM_write(ETH_SMB_CORE_ID, ETH_SMB_ADDREG, &lan9211_reg);

  // Write data high
  FPGA_IPM_write(ETH_SMB_CORE_ID, ETH_SMB_DATAH, &data_high);

  // Write data low
  FPGA_IPM_write(ETH_SMB_CORE_ID, ETH_SMB_DATAL, &data_low);

  // Lock
  FPGA_IPM_write(ETH_SMB_CORE_ID, ETH_SMB_LOCKREG, &polling_semaphore);

  // Wait
  while(polling_semaphore != CPU_UNLOCK_WORD) {
    FPGA_IPM_read(ETH_SMB_CORE_ID, ETH_SMB_LOCKREG, &polling_semaphore);
  }

  // Close polling transaction
  FPGA_IPM_close(ETH_SMB_CORE_ID);
}
