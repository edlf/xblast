/*
 * i2c.h
 *
 *  Created on: Sep 14, 2016
 *      Author: bennyboy
 */

#ifndef INCLUDE_I2C_H_
#define INCLUDE_I2C_H_

#include <stdbool.h>

int WriteToSMBus(const unsigned char Address, const unsigned char bRegister, const unsigned char Size, const unsigned int Data_to_smbus);
int ReadfromSMBus(const unsigned char Address, const unsigned char bRegister, const unsigned char Size, unsigned int *Data_to_smbus);
int I2CTransmitByteGetReturn(const unsigned char bPicAddressI2cFormat, const unsigned char bDataToWrite);
int I2CTransmitWord(const unsigned char bPicAddressI2cFormat, const unsigned short wDataToWrite);
int I2CWriteBytetoRegister(const unsigned char bPicAddressI2cFormat, const unsigned char bRegister, const unsigned char wDataToWrite);

int I2cSetFrontpanelLed(unsigned char b);
bool I2CGetTemperature(int * pnLocalTemp, int * pExternalTemp);
void I2CRebootQuick(void);
void I2CRebootSlow(void);
void I2CPowerOff(void);
unsigned char I2CGetFanSpeed(void);
void I2CSetFanSpeed(unsigned char speed);
unsigned char I2CGetXboxMBRev(void);


#endif /* INCLUDE_I2C_H_ */
