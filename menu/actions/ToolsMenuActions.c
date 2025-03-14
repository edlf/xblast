/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
#include "MenuInits.h"
#include "MenuActions.h"
#include "ToolsMenuActions.h"
#include "EepromEditMenuActions.h"
#include "NetworkMenuActions.h"
#include "HDDMenuActions.h"
#include "ResetMenuActions.h"
#include "lpcmod_v1.h"
#include "BootHddKey.h"
#include "lib/LPCMod/BootLPCMod.h"
#include "lib/cromwell/cromString.h"
#include "lib/cromwell/cromSystem.h"
#include "xblast/settings/xblastSettingsImportExport.h"
#include "string.h"
#include "menu/misc/ConfirmDialog.h"
#include "menu/misc/ProgressBar.h"
TEXTMENUITEM* saveEEPROMPtr;
TEXTMENUITEM* restoreEEPROMPtr;
TEXTMENUITEM* editEEPROMPtr;

void saveEEPromToFlash(void* ignored)
{
    int version;

    version = decryptEEPROMData((unsigned char *)&(LPCmodSettings.bakeeprom), NULL);
    if(version >= EEPROM_EncryptV1_0 && version <= EEPROM_EncryptV1_6)   //Current content in eeprom is valid.
    {
        if(ConfirmDialog("Overwrite back up EEProm content?", 1))
        {
            return;
        }
    }

    saveEEPROMPtr->nextMenuItem = restoreEEPROMPtr;
#ifdef DEV_FEATURES
    editEEPROMPtr->previousMenuItem = eraseEEPROMPtr;
#else
    editEEPROMPtr->previousMenuItem = restoreEEPROMPtr;
#endif

    memcpy(&(LPCmodSettings.bakeeprom),&eeprom,sizeof(EEPROMDATA));
    UiHeader("Back up to flash successful");

    UIFooter();
}

void restoreEEPromFromFlash(void* ignored){

    editeeprom = (EEPROMDATA *)malloc(sizeof(EEPROMDATA));

    if(updateEEPROMEditBufferFromInputBuffer((unsigned char *)&(LPCmodSettings.bakeeprom), sizeof(EEPROMDATA), false) == false)
    {
        if(replaceEEPROMContentFromBuffer(editeeprom))
        {
            UiHeader("No valid EEPROM backup on modchip.");
            printk("\n           Nothing to restore. Xbox EEPROM is unchanged.");
            UIFooter();
        }
    }

    free(editeeprom);
    editeeprom = NULL;
}

#ifdef DEV_FEATURES
void eraseEEPromFromFlash(void* ignored)
{
    memset(&LPCmodSettings.bakeeprom, 0xFF, sizeof(EEPROMDATA));

    saveEEPROMPtr->nextMenuItem = editEEPROMPtr;
    editEEPROMPtr->previousMenuItem = saveEEPROMPtr;

    UiHeader("EEPROM backup on modchip erased.");
    UIFooter();
}
#endif

void warningDisplayEepromEditMenu(void* ignored)
{
    if(ConfirmDialog("Use these tools at your own risk!", 1))
    {
            return;
    }

    editeeprom = (EEPROMDATA *)malloc(sizeof(EEPROMDATA));
    memcpy(editeeprom, &eeprom, sizeof(EEPROMDATA));   //Initial copy into edition buffer.
    ResetDrawChildTextMenu(eepromEditMenuDynamic());
    free(editeeprom);
    editeeprom = NULL;
}

void wipeEEPromUserSettings(void* ignored)
{
    if(ConfirmDialog("Reset user EEProm settings(safe)?", 1))
    {
        return;
    }

    memset(eeprom.Checksum3,0xFF,4);    //Checksum3 need to be 0xFFFFFFFF
    memset(eeprom.TimeZoneBias,0x00,0x5b);    //Start from Checksum3 address in struct and write 0x00 up to UNKNOWN6.
    UiHeader("Reset user EEProm settings successful");
    UIFooter();
}

static int testBank(int bank)
{
    unsigned int counter, subCounter, lastValue;
    unsigned int *membasetop = (unsigned int*)((64*1024*1024));
    unsigned char result=0; //Start assuming everything is good.

    lastValue = 1;
    //Clear Upper 64MB
    for (counter= 0; counter < (64*1024*1024/4);counter+=16)
    {
        for(subCounter = 0; subCounter < 3; subCounter++)
            membasetop[counter+subCounter+bank*4] = lastValue; //Set it all to 0x1
    }

    while(lastValue < 0x80000000 && cromwellLoop()) //Test every data bit pins.
    {
        for (counter= 0; counter < (64*1024*1024/4);counter+=16) //Test every address bit pin. 4194304 * 8 = 32MB
        {
            for(subCounter = 0; subCounter < 3; subCounter++)
            {
                if(membasetop[counter+subCounter+bank*4]!=lastValue)
                {
                    result = 1; //1=no no
                    lastValue = 0x80000000;
                    return result; //No need to go further. Bank is broken.
                }
                membasetop[counter+subCounter+bank*4] = lastValue<<1; //Prepare for next read.
            }
        }
        lastValue = lastValue << 1; //Next data bit pin.
    }
    return result;
}

static void memtest(void)
{
    unsigned char bank = 0;

    PciWriteDword(BUS_0, DEV_0, FUNC_0, 0x84, 0x07FFFFFF);  //Force 128 MB

    DisplayProgressBar(0, 4, 0xffff00ff); //Draw ProgressBar frame.
    for(bank = 0; bank < 4; bank++)
    {
        printk("\n           Ram chip %u : %s",bank+1, testBank(bank) ? "Failed" : "Success");
        DisplayProgressBar(bank + 1, 4, 0xffff00ff);                   //Purple progress bar.
    }

    VIDEO_ATTR=0xffc8c8c8;
}

void showMemTest(void* ignored)
{
    UiHeader("128MB RAM test");
    memtest();
    UIFooter();
}

static uint32_t lfsr_value;
static void LFSR(void) {
    bool lsb = lfsr_value & 1;
    lfsr_value >>= 1;
    if (lsb) {
        lfsr_value ^= ((1 << 31) | (1 << 21) | (1 << 1) | (1 << 0)); //Taps
    }
}

static void printTestFailure(uint32_t addr, uint32_t expected, uint32_t actual) {
    printk("\n               Fail at 0x%X. Expected 0x%08X. Actual 0x%08X", addr, expected, actual);
}

static uint32_t testBank256(uint32_t bank) {
    uint32_t* base = (uint32_t*)(128 * 1024 * 1024);
    uint32_t fails = 0;
    
    //Fill the memory with an LFSR pattern
    lfsr_value = 0x5AFEb055;
    for (uint32_t group = 0; group < (128 * 1024 * 1024 / 4); group += 16) { //Group size is 16 words
        base[group + (bank * 4) + 0] = lfsr_value;
        LFSR();
        base[group + (bank * 4) + 1] = lfsr_value;
        LFSR();
        base[group + (bank * 4) + 2] = lfsr_value;
        LFSR();
        base[group + (bank * 4) + 3] = lfsr_value;
        LFSR();
    }
    
    DisplayProgressBar(bank * 2 + 1, 8, 0xFF00FF93);
    
    //Reset the LFSR and read the pattern back
    lfsr_value = 0x5AFEb055;
    for (uint32_t group = 0; group < (128 * 1024 * 1024 / 4); group += 16) { //Group size is 16 words
        if (base[group + (bank * 4) + 0] != lfsr_value) {
            printTestFailure((uint32_t)&base[group + (bank * 4) + 0], lfsr_value, base[group + (bank * 4) + 0]);
            fails++;
            if (fails > 7) {
                break;
            }
        }
        LFSR();
        if (base[group + (bank * 4) + 1] != lfsr_value) {
            printTestFailure((uint32_t)&base[group + (bank * 4) + 1], lfsr_value, base[group + (bank * 4) + 1]);
            fails++;
            if (fails > 7) {
                break;
            }
        }
        LFSR();
        if (base[group + (bank * 4) + 2] != lfsr_value) {
            printTestFailure((uint32_t)&base[group + (bank * 4) + 2], lfsr_value, base[group + (bank * 4) + 2]);
            fails++;
            if (fails > 7) {
                break;
            }
        }
        LFSR();
        if (base[group + (bank * 4) + 3] != lfsr_value) {
            printTestFailure((uint32_t)&base[group + (bank * 4) + 3], lfsr_value, base[group + (bank * 4) + 3]);
            fails++;
            if (fails > 7) {
                break;
            }
        }
        LFSR();
    }
    
    DisplayProgressBar(bank * 2 + 2, 8, 0xFF00FF93);
    return fails > 0;
}

static void memtest256(void) {
    PciWriteDword(BUS_0, DEV_0, FUNC_0, 0x84, 0x0FFFFFFF); //Allow 256 MB
    
    DisplayProgressBar(0, 8, 0); //Empty ProgressBar frame
    for(uint32_t bank = 0; bank < 4; bank++) {
        printk("\n           RAM chip %u : %s", bank + 1, testBank256(bank) ? "Failed" : "Success");
    }

    VIDEO_ATTR=0xffc8c8c8;
}

void showMemTest256(void* ignored) {
    UiHeader("256MB RAM test");
    memtest256();
    UIFooter();
}

/*
void TSOPRecoveryReboot(void *ignored){
    if(ConfirmDialog("       Confirm reboot in TSOP recovery mode?", 1))
        return;
    WriteToIO(XODUS_CONTROL, RELEASED0 | GROUNDA15);
    WriteToIO(XBLAST_CONTROL, BNKOS);   //Make sure A19 signal is not controlled.
    BootFlashSaveOSSettings();
    assertWriteEEPROM();
    I2CTransmitWord(0x10, 0x1b00 + ( I2CTransmitByteGetReturn(0x10, 0x1b) | 0x04 )); // set noani-bit
    I2CRebootQuick();        //Retry
    while(1);
}
*/
void saveXBlastcfg(void* ignored)
{
    LPCMod_SaveCFGToHDD();
}

void loadXBlastcfg(void* ignored)
{
    int result;
    _LPCmodSettings tempSettings;
    if(ConfirmDialog("Restore settings from \"xblast.cfg\"?", 1))
    {
        UiHeader("Loading from C:\\xblast.cfg aborted.");
        result = 1;
    }
    else
    {
        result = LPCMod_ReadCFGFromHDD(&tempSettings, &settingsPtrStruct);
    }
    
    if(result == 0)
    {
        importNewSettingsFromCFGLoad(&tempSettings);
        UiHeader("Success.");
        printk("\n           Settings loaded from \"C:\\XBlast\\xblast.cfg\".");
    }
    else
    {
        UiHeader("Error!!!");
        switch(result)
        {
        default:
            break;
        case 2:
            printk("\n           Unable to open partition. Is drive formatted?");
            break;
        case 3:
            printk("\n           File \"C:\\XBlast\\xblast.cfg\" not found.");
            break;
        case 4:
            printk("\n           Unable to open \"C:\\XBlast\\xblast.cfg\".");
            break;
        }
    }
    UIFooter();
}

void nextA19controlModBootValue(void* itemPtr)
{
    switch(A19controlModBoot)
    {
        case BNKFULLTSOP:
            A19controlModBoot = BNKTSOPSPLIT0;
            sprintf(itemPtr, "%s", "Bank0");
            break;
        case BNKTSOPSPLIT0:
            A19controlModBoot = BNKTSOPSPLIT1;
            sprintf(itemPtr, "%s", "Bank1");
            break;
        case BNKTSOPSPLIT1:
        default:
            A19controlModBoot = BNKFULLTSOP;
            sprintf(itemPtr, "%s", "No");
            break;
    }
}

void prevA19controlModBootValue(void* itemPtr)
{
    switch(A19controlModBoot)
    {
        case BNKTSOPSPLIT1:
            A19controlModBoot = BNKTSOPSPLIT0;
            sprintf(itemPtr, "%s", "Bank0");
            break;
        case BNKFULLTSOP:
            A19controlModBoot = BNKTSOPSPLIT1;
            sprintf(itemPtr, "%s", "Bank1");
            break;
        case BNKTSOPSPLIT0:
        default:
            A19controlModBoot = BNKFULLTSOP;
            sprintf(itemPtr, "%s", "No");
            break;
    }
}

bool replaceEEPROMContentFromBuffer(EEPROMDATA* eepromPtr)
{
    unsigned char i, unlockConfirm[2];
    bool cancelChanges = false;

    for(i = 0; i < 2; i++)               //Probe 2 possible drives
    {
        if(tsaHarddiskInfo[i].m_fDriveExists && !tsaHarddiskInfo[i].m_fAtapi)  //If there's a HDD plugged on specified port
        {
            if((tsaHarddiskInfo[i].m_securitySettings &0x0002)==0x0002)        //If drive is locked
            {
                if(UnlockHDD(i, 0, (unsigned char *)&eeprom, true))            //0 is for silent
                {
                    unlockConfirm[i] = 255;  //error
                }
                else
                {
                    unlockConfirm[i] = 1; //Everything went well, we'll relock after eeprom write.
                }
            }
            else
            {
                unlockConfirm[i] = 0;   //Drive not locked, won't relock after eeprom write.
            }
        }
        else
        {
            unlockConfirm[i] = 0;       //Won't relock as no HDD was detected on that port.
        }

        debugSPIPrint(DEBUG_GENERAL_UI, "Drive %u  lock assert result %u\n", i, unlockConfirm[i]);
    }

    if(unlockConfirm[0] == 255 || unlockConfirm[1] == 255)      //error in unlocking one of 2 drives.
    {
        cancelChanges = ConfirmDialog("Drive(s) still locked\n\2Continue anyway?", 1);
    }

    if(cancelChanges == false)
    {
        memcpy(&eeprom, eepromPtr, sizeof(EEPROMDATA));

        for(i = 0; i < 2; i++)               //Probe 2 possible drives
        {
            if(unlockConfirm[i] == 1)
            {
                debugSPIPrint(DEBUG_GENERAL_UI, "Relocking drive %u with new HDDKey\n", i);
                LockHDD(i, 0, (unsigned char *)&eeprom);    //0 is for silent mode.
            }
        }
        UiHeader("Saved EEPROM image");
        printk("\n\n           Modified buffer has been saved to main EEPROM buffer.\n           Pressing \'B\' will program EEPROM chip and restart the console.\n           Pressing Power button will cancel EEPROM chip write.\n\n\n");
        UIFooter();
        SlowReboot(NULL);   //This function will take care of saving eeprom image to chip.
        while(1);
        return false;
    }
    else
    {
        UiHeader("Operation aborted");
        printk("\n\n           Error unlocking drives with previous key.");
        printk("\n           Actual EEPROM has NOT been changed.");
        printk("\n           Please Manually unlock all connected HDDs before modifying EEPROM content.");
        UIFooter();
        return false;
    }

    return true;        //Error
}
