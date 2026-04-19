#ifndef _TOOLSMENUACTIONS_H_
#define _TOOLSMENUACTIONS_H_
/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
#include "BootEEPROM.h"
#include "TextMenu.h"
#include <stdbool.h>

void saveEEPromToFlash(void* ignored);
void restoreEEPromFromFlash(void* ignored);
#ifdef DEV_FEATURES
void eraseEEPromFromFlash(void* ignored);
#endif
void warningDisplayEepromEditMenu(void* ignored);
void wipeEEPromUserSettings(void* ignored);

void showMemTest(void* ignored);
void showMemTest256(void* ignored);

//void TSOPRecoveryReboot(void *ignored);

void saveXBlastcfg(void* ignored);
void loadXBlastcfg(void* ignored);

void prevA19controlModBootValue(void* itemPtr);
void nextA19controlModBootValue(void* itemPtr);

bool replaceEEPROMContentFromBuffer(EEPROMDATA* eepromPtr);

extern TEXTMENUITEM* saveEEPROMPtr;
extern TEXTMENUITEM* restoreEEPROMPtr;
extern TEXTMENUITEM* editEEPROMPtr;

#ifdef DEV_FEATURES
extern TEXTMENUITEM* eraseEEPROMPtr;
#endif

#endif
