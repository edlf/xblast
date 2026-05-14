/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "BootIde.h"
#include "MenuInits.h"
#include "UncommittedChangesMenuActions.h"
#include "include/boot.h"
#include "lib/LPCMod/xblastDebug.h"
#include "string.h"
#include "xblast/settings/xblastSettingsChangeTracker.h"

void UncommittedChangesMenuDynamic(void *nothing) {
    TEXTMENU *menuPtr = generateMenuEntries();

    ResetDrawChildTextMenu(menuPtr);
}
