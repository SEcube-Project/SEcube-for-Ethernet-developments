#ifndef ETH_SMB_UTIL_H
#define ETH_SMB_UTIL_H

#include "stdio.h"
#include "inttypes.h"

#define ADDITIONAL_SIZE 14
#define MAC_ADDR_SIZE 6

static const uint8_t simple_arp_packet[] = {
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 	// Destination MAC
		0x00, 0xaa, 0xbb, 0xcc, 0xdd, 0xee,		// Source MAC
		0x08, 0x06, 							// ARP
		0x00, 0x01, 							// Hardware type: Ethernet
		0x08, 0x00, 							// Protocol type: IPv4
		0x06,									// Hardware size: 6
		0x04,									// Protocol size: 4
		0x00, 0x01,								// Opcode: request
		0x00, 0xaa, 0xbb, 0xcc, 0xdd, 0xee,		// Sender MAC address
		0x00, 0x00, 0x00, 0x00,					// Sender IP address
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00,		// Target MAC address
		//0xa9, 0xfe, 0xff, 0x7e					// Target IP address (here is 169.254.255.126, change this according to your needs)
		0x0a, 0x0a, 0x0a, 0x0a					// Target IP address (here is 10.10.10.10)
		//0xc0, 0xa8, 0x0a, 0x0a					// Target IP address (here is 192.168.10.10)
		// 42 bytes without padding
};

size_t eth_composeSampleFrameTypeII(uint8_t *ethFrame, uint8_t *dstMAC, uint8_t *srcMAC, uint16_t etherType, uint8_t *payload, size_t payloadLen);
int isArpRequest(uint8_t *ethFrame, size_t length);
int isArpReply(uint8_t *ethFrame, size_t length);
int getSourceMAC(uint8_t *ethFrame);

#endif // ETH_SMB_UTIL_H
