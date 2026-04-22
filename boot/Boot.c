#include "stdint.h"

unsigned int cromwell_config;
unsigned int cromwell_retryload;
unsigned int cromwell_2blversion;
unsigned int cromwell_2blsize;

unsigned int xbox_ram;

unsigned int video_encoder;

volatile unsigned int VIDEO_CURSOR_POSX;
volatile unsigned int VIDEO_CURSOR_POSY;
volatile unsigned int VIDEO_ATTR;
volatile unsigned int BIOS_TICK_COUNT;
volatile unsigned int DVD_TRAY_STATE;

unsigned char VIDEO_AV_MODE;

unsigned char *videosavepage;
