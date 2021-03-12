#include "Fpgaipm.h"
#include "blinker.h"

void LEDS_on(uint8_t byte) {

	uint8_t opcode;
	FPGA_IPM_DATA polling_semaphore = 0x0000;

	opcode	= 0x38 ;

	FPGA_IPM_open(BLINKER_CORE_ID, opcode, 0, 0);
	FPGA_IPM_write(BLINKER_CORE_ID, 1, &byte);
	// close the polling transaction
	FPGA_IPM_close(BLINKER_CORE_ID);

}


