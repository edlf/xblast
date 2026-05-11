/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "ConfirmDialog.h"
#include "boot.h"
#include "video.h"
#include "cromwell.h"
#include "string.h"
#include "lib/LPCMod/xblastDebug.h"
#include "lib/cromwell/cromSystem.h"

#define ComparebufSize 100
char bypassConfirmDialog[ComparebufSize];        //Arbitrary length

bool ConfirmDialog(char * string, bool critical)
{
    unsigned int yPos = 120;
    unsigned int stringLength = strlen(string);
    bool result = true;         //True = cancel.
        
    stringLength = stringLength > ComparebufSize ? ComparebufSize : stringLength;
    if(strncmp(string, bypassConfirmDialog, stringLength) == false && critical == false)
    {
        return false;
    }

    BootVideoClearScreen(&jpegBackdrop, 0, 0xffff);
    VIDEO_ATTR=0xffff1515; //Red characters.
    yPos = centerScreenPrintk(yPos, "\2%s\n", string);
    VIDEO_ATTR=0x00ffffff; //Back to white
    yPos = centerScreenPrintk(yPos, "Hold Start to confirm\n");
    centerScreenPrintk(yPos, "Press Back to cancel");
    
    while(cromwellLoop())
    {
        if(risefall_xpad_STATE(XPAD_STATE_START)) //white button
        {
            debugSPIPrint(DEBUG_GENERAL_UI, "All correct buttons pressed. Accepting.\n");
            strncpy(bypassConfirmDialog, string, stringLength);
            result = false;
            break;
        }

        if(risefall_xpad_STATE(XPAD_STATE_BACK) == 1)
        {
            break;
        }
    }
    BootVideoClearScreen(&jpegBackdrop, 0, 0xffff);
    
    return result;
}
