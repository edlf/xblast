/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
#include "FlashMenuActions.h"
#include "MenuActions.h"
#include "lpcmod_v1.h"
#include "FlashUi.h"
#include "BootIde.h"
#include "TextMenu.h"
#include "boot.h"
#include "i2c.h"
#include "video.h"
#include "memory_layout.h"
#include "BootFATX.h"
#include "FlashDriver.h"
#include "Gentoox.h"
#include "string.h"
#include "lib/LPCMod/BootLPCMod.h"
#include "lib/cromwell/cromString.h"
#include "lib/cromwell/cromSystem.h"
#include "lib/time/timeManagement.h"
#include "LEDMenuActions.h"
#include "WebServerOps.h"

extern int etherboot(void);

int BootLoadFlashCD(const int cdromId) {
    busyLED();
    long imageSize=0;
    int n;
    int imageFound=0;
    unsigned char *fileBuf;
    fileBuf = (unsigned char *)malloc(1024 * 1024);
    memset(fileBuf,0x0,1024 * 1024);

    //See if we already have a CDROM in the drive
    //Try for 4 seconds - takes a while to 'spin up'.
    I2CTransmitWord(0x10, 0x0c01); // close DVD tray

    VIDEO_CURSOR_POSY=vmode.ymargin+96;
    printk("\n\n\n\n\n           Checking disc");
    dots();

    for (n=0;n<16;++n) {
        imageSize = BootIso9660GetFile(cdromId,"/image.bin", fileBuf, 0x10);
        if (imageSize>0) {
            imageFound=1;
            break;
        }
        wait_ms(250);
    }

    if (!imageFound) {
        //Needs to be changed for non-xbox drives, which don't have an eject line
        //Need to send ATA eject command.
        I2CTransmitWord(0x10, 0x0c00); // eject DVD tray
        cromwellWarning();
        VIDEO_ATTR=0xffeeeeff;
        printk("           Please insert a disc which contains \"image.bin\"");
        dots();
        inputLED();

        wait_ms(1000); // Wait for DVD to become responsive to inject command

        while(cromwellLoop()) {
            // Make button 'A' close the DVD tray
            if (risefall_xpad_BUTTON(TRIGGER_XPAD_KEY_A) == 1) {
                I2CTransmitWord(0x10, 0x0c01);
                // May as well break here too incase the drive is
                // a non-standard Xbox drive and can't report whether the
                // tray is closing or not.
                wait_ms(500);
                busyLED();
                break;
            }

            // If the drive is closing, exit the loop.  This accounts
            // for people pushing the drive shut or even pressing the eject
            // button.
            if (DVD_TRAY_STATE == DVD_CLOSING) {
                wait_ms(500);
                break;
            }
            wait_ms(10);
        }

        busyLED();

        VIDEO_ATTR=0xffffffff;

        //Try to load image.bin - if we can't after a while, give up.
        for (n=0;n<48;++n) {
            imageSize = BootIso9660GetFile(cdromId,"/image.bin", fileBuf, 0x10);
            if (imageSize>0) {
                imageFound=1;
                break;
            }
            wait_ms(250);
        }
    }

    //Failed to find the image.bin file
    if (!imageFound) {
        cromwellError();
        printk("\n\n           Could not find the image.bin file.\n");
        FlashFooter();
        return 0;
    }

    cromwellSuccess();

    printk("           Reading image.bin");
    dots();

    // Read in a full 1MB bios (read will be truncated if the file is not this big).
    imageSize=BootIso9660GetFile(cdromId, "/image.bin", fileBuf, 1024*1024);

    if(imageSize < 0) { //It's not there
        cromwellWarning();
        printk("           image.bin not found on CD.\n");
        wait_ms(2000);
        inputLED();
        return 0;
    }

    FlashFileFromBuffer(fileBuf, imageSize, 1);
    return 0;
}

void FlashBiosFromHDD (void *fname) {
#ifdef FLASH
    int res;
    unsigned char * fileBuf;
    FATXFILEINFO fileinfo;
    FATXPartition *partition;

    partition = OpenFATXPartition (0, SECTOR_SYSTEM, SYSTEM_SIZE);
    fileBuf = (unsigned char *) malloc (1024 * 1024);  //1MB buffer(max BIOS size)
    memset (fileBuf, 0x00, 1024 * 1024);   //Fill with 0.

    //res = LoadFATXFilefixed(partition, fname, &fileinfo, (char*)0x100000);
    res = LoadFATXFile(partition, fname, &fileinfo);
    if (!res) {
        printk ("\n\n\n\n\n           Loading BIOS failed");
        dots ();
        cromwellError ();
        goto jumpToEnd;
    }
    memcpy(fileBuf, fileinfo.buffer, fileinfo.fileSize);
    free(fileinfo.buffer);
    fileinfo.buffer = fileBuf;
    FlashFileFromBuffer(fileinfo.buffer, fileinfo.fileSize, 1); //1 to display confirmDialog
    free(fileinfo.buffer);
jumpToEnd:
    CloseFATXPartition (partition);

    return;
#endif
}

void FlashBiosFromCD (void *cdromId) {
#ifdef FLASH
    BootVideoClearScreen(&jpegBackdrop, 0, 0xffff);
    BootLoadFlashCD (*(int *) cdromId);
#endif
}

void enableNetflash (void *flashType) {
#ifdef FLASH
    static bool nicInit = false;
    BootVideoClearScreen(&jpegBackdrop, 0, 0xffff);
    printk ("\n\n            Starting network interface.");
    VIDEO_ATTR = 0xffc8c8c8;

    if(nicInit == true || etherboot() == 0)
    {
        nicInit = true;
        cromwellSuccess();
        debugSPIPrint(DEBUG_GENERAL_UI, "Starting network service\n");
        startNetFlash(*(WebServerOps *)flashType);
        while(cromwellLoop()) {
            if(netflashPostProcess()) {
                debugSPIPrint(DEBUG_GENERAL_UI, "Killing network service\n");
                break;
            }
        }

    } else {
        printk("\n\n            Starting network interface failed. Press B or Back");
        while (risefall_xpad_BUTTON(TRIGGER_XPAD_KEY_B) != 1 && risefall_xpad_STATE(XPAD_STATE_BACK) != 1) {
            cromwellLoop();
        }
    }
#endif
}

void enableWebupdate (void *whatever) {
#ifdef FLASH
    BootVideoClearScreen(&jpegBackdrop, 0, 0xffff);
    printk ("\n\n");
    VIDEO_ATTR = 0xffc8c8c8;

    //initialiseNetwork ();
    //webUpdate ();
#endif
}

void FlashFooter(void)
{
    UIFooter();
    initialSetLED (LPCmodSettings.OSsettings.LEDColor);
}
