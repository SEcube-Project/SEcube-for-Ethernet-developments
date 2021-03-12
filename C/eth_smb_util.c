#include "eth_smb_util.h"

size_t eth_composeSampleFrameTypeII(uint8_t *ethFrame, uint8_t *dstMAC, uint8_t *srcMAC, uint16_t etherType, uint8_t *payload, size_t payloadLen) {
	int i;
	size_t frame_byte;

	for(i = 0; i < MAC_ADDR_SIZE; i++) {
		ethFrame[frame_byte] = dstMAC[i];
		frame_byte++;
	}

	for(i = 0; i < MAC_ADDR_SIZE; i++) {
		ethFrame[frame_byte] = srcMAC[i];
		frame_byte++;
	}

	ethFrame[frame_byte++] = ((uint16_t)(etherType & 0xFF00) >> 8);
	ethFrame[frame_byte++] = ((uint16_t)(etherType & 0x00FF));

	ethFrame[frame_byte++] = ((uint16_t)(payloadLen & 0xFF00) >> 8);
	ethFrame[frame_byte++] = ((uint16_t)(payloadLen & 0x00FF));

	for(i = 0; i < payloadLen; i++) {
		ethFrame[frame_byte] = payload[i];
		frame_byte++;
	}

	return frame_byte;
}

int isArpRequest(uint8_t *ethFrame, size_t length) {
	if (length != 64)
		return 0;

	uint16_t etherType, opcode;
	etherType = (ethFrame[12] << 8) | ethFrame[13];
	opcode = (ethFrame[20] << 8) | ethFrame[21];

	if (etherType == 0x0806 && opcode == 0x1)
		return 1;

	return 0;
}

int isArpReply(uint8_t *ethFrame, size_t length) {
	if (length != 64)
		return 0;

	uint16_t etherType, opcode;
	etherType = (ethFrame[12] << 8) | ethFrame[13];
	opcode = (ethFrame[20] << 8) | ethFrame[21];

	if (etherType == 0x0806 && opcode == 0x2)
		return 1;

	return 0;
}

