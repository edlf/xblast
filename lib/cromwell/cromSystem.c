/*
 * system.c
 *
 *  Created on: Jan 30, 2017
 *      Author: cromwelldev
 */

#include "FlashDriver.h"
#include "FlashUi.h"
#include "WebServerOps.h"
#include "lib/LPCMod/BootLCD.h"
#include "lib/LPCMod/LCDRingBuffer.h"
#include "lib/time/timeManagement.h"

unsigned char cromwellLoop(void) {
    if (currentNetworkState != NetworkState_Idle) {
        run_lwip();
    }

    if (xLCD.enable) {
        updateLCDRingBuffer();
    }

    // debugSPIPrint loop
    // LCD loop

    return 1;
}
