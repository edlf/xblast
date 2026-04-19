/*
 * I2C-related code
 * AG 2002-07-27
 */

 /***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "2bload.h"
#include <stdbool.h>

unsigned char *BufferIN;
int BufferINlen;
unsigned char *BufferOUT;
int BufferOUTPos;

// ----------------------------  I2C -----------------------------------------------------------

// transmit a word, no returned data from I2C device

int I2CTransmitWord(unsigned char bPicAddressI2cFormat, unsigned short wDataToWrite)
{
    int nRetriesToLive = 400;

    while(IoInputWord(I2C_IO_BASE + 0) & 0x0800) ;  // Franz's spin while bus busy with any master traffic

    while(nRetriesToLive--)
    {
        IoOutputByte(I2C_IO_BASE + 4, (bPicAddressI2cFormat << 1) | 0);

        IoOutputByte(I2C_IO_BASE + 8, (unsigned char)(wDataToWrite >> 8));
        IoOutputByte(I2C_IO_BASE + 6, (unsigned char)wDataToWrite);
        IoOutputWord(I2C_IO_BASE + 0, 0xffff);  // clear down all preexisting errors
        IoOutputByte(I2C_IO_BASE + 2, 0x1a);

        {
            unsigned char b = 0x0;
            while((b & 0x36) == 0)
            {
                b = IoInputByte(I2C_IO_BASE + 0);
            }

            if(b & 0x24)
            {
                //bprintf("I2CTransmitWord error %x\n", b);
            }
            if((b & 0x10) == false)
            {
                //bprintf("I2CTransmitWord no complete, retry\n");
            }
            else
            {
                return ERR_SUCCESS;
            }
        }
    }
    return ERR_I2C_ERROR_BUS;
}
