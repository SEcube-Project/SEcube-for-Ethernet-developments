/**
 *  \file eth_smb.h
 *  \author Alberto Carboni, Alessio Ciarcià, Jacopo Grecuccio, Lorenzo Zaia
 *  \brief Low-Level driver for communication between CPU and LAN9211 in an IP-Manager-based environment
 */

#ifndef ETH_SMB_H
#define ETH_SMB_H


#include "Fpgaipm.h"


#define ETH_SMB_CORE_ID				(1)
/** \defgroup ETH_SMB OPCODES
 * @{
 */
/** \name ETH_SMB OPCODES */
///@{
#define OPC_CSR_READ				((uint8_t)(0x01))
#define OPC_CSR_WRITE				((uint8_t)(0x02))
#define OPC_TX_LAN					((uint8_t)(0x09))
#define OPC_START_TIMER				((uint8_t)(0x03))
#define OPC_RESET_TIMER				((uint8_t)(0x06))
#define OPC_STOP_TIMER				((uint8_t)(0x05))
#define OPC_CHANGE_TIMER_PERIOD		((uint8_t)(0x04))
///@}
/** @} */

/** \defgroup ETH_SMB DATA BUFFER ADDRESSES
 * @{
 */
/** \name ETH_SMB DATA BUFFER ADDRESSES */
///@{
#define ETH_SMB_ADDREG				(1)
#define ETH_SMB_LOCKREG				(63)

#define ETH_SMB_DATAH				(2)
#define ETH_SMB_DATAL				(3)

#define ETH_SMB_TX_FRAME_LENGTH_REG (1)

#define CPU_UNLOCK_WORD				(0xFFFF)
#define CPU_LOCK_WORD				(0x0000)
///@}
/** @} */
/**
 * @brief This Function is used to read 32 bits from a LAN9211 register
 * 
 * @param lan9211_reg The address of the target register
 * @param data The pointer to the buffer where the data will be stored
 */
void ETH_SMB_PIORead(uint16_t lan9211_reg, uint32_t *data);
/**
 * @brief This Function is used to write 32 bits from a LAN9211 register
 * 
 * @param lan9211_reg The address of the target register
 * @param data The value to be written
 */
void ETH_SMB_PIOWrite(uint16_t lan9211_reg, uint32_t data);

#endif // ETH_SMB_H
