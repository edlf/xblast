/*
 *
 *  BIOS ROM Startup Assembler
 *  (C)2002 Andy, Michael, Paul, Steve
 * Original top and bottom ROM code by Steve from an idea by Michael
 * -- NOTE: Comment removed, the top / bottom Code changed to turnaround code.
 */

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
/* 
	Rewritten from Original .bin linking to compiler system by Lehner Franz (franz@caos.at) 
	Rewritten to Dual Boot concept for 2BL loading
	New written CPU Inits by Lehner Franz (franz@caos.at) 
	Written New Working Xcodes + Xcode compiler by Lehner Franz (franz@caos.at) 
	Focus support by Lehner Franz (franz@caos.at) 
	Xcalibur support by Lehner Franz (franz@caos.at) 
*/
 
 
#define xcode_peek(val1) .byte 0x2; .long val1 ; .long 0x0 ;
#define xcode_poke(val1,val2) .byte 0x3; .long val1 ; .long val2 ;
#define xcode_pciout(val1,val2) .byte 0x4; .long val1 ; .long val2 ;
#define xcode_pciin_a(val1) .byte 0x5; .long val1 ; .long 0x0 ;

#define xcode_bittoggle(val1,val2) .byte 0x6; .long val1 ; .long val2 ;

#define xcode_ifngoto(val1,val2) .byte 0x8; .long val1 ; .long (9*(val2-1)) ;
#define xcode_ifngoto_label(val1,val2) .byte 0x8; .long val1 ; .long (val2-.-4) ;

#define xcode_outb(val1,val2) .byte 0x11; .long val1 ; .long val2 ;			    
#define xcode_inb(val1) .byte 0x12; .long val1 ; .long 0x0 ;			    

#define xcode_poke_a(val1) .byte 0x7; .long 0x3; .long val1 ;  
#define xcode_pciout_a(val1) .byte 0x7; .long 0x4; .long val1 ;  
#define xcode_outb_a(val1) .byte 0x7; .long 0x11; .long val1 ;  

#define xcode_goto(val1) .byte 0x9; .long 0x0; .long (9*(val1-1));
#define xcode_goto_label(val1) .byte 0x9; .long 0x0; .long (val1-.-4);

#define xcode_END(val1) .byte 0xEE; .long val1 ; .long 0x0;

#define SMBUS 		0x0000c000

#define SMBUS_READ_RETRY -4

#define SMB_xcode_Write(val1,val2); \
			xcode_outb(SMBUS+8, val1); \
			xcode_outb(SMBUS+6, val2); \
			xcode_outb(SMBUS+2, 0x0000000a); \
			xcode_inb(SMBUS); \
			xcode_ifngoto(0x00000010,-1); \
			xcode_outb(SMBUS, 0x00000010); 

.code32

.section .low_rom, "ax"

.org 0x0
	/* MCPX Magic Values - clock timings*/
	
	.long 0xff000009 //SmartXX sets this one to 0xff000008 but was originally 0xff000009. SpiderGX has this set to 0xff000003
	.long 0xff000008
	.long 0x2b16d065
	.long 0x3346322d
	.long 0x01010101
	.long 0x08080808
	.long 0x00000801

	.long 0xc8fc7c8a
	.long 0x44290213
	.long 0x90004998		
	.long 0x00000000

	.long 0xffffffff
	.long 0xffffffff
	
	.org 0x40
	.long _start_checksum	// This number will be overwritten  
									// With imagebld, but we need a temp value
	
	.org 0x6c
	.long 0x00000107
	
	.org 0x70		// MCPX Config Area
	.long 0x0000000f
	.long 0x40004400
	
	.long 0x12d10070
	.long 0x00000c90

	
	//The bytecode interpreter begins here
xcode_pciout(0x80000884, 0x00008001);
xcode_pciout(0x80000810, 0x00008001);
xcode_pciout(0x80000804, 0x00000003);
xcode_outb(0x00008049, 0x00000008);
xcode_outb(0x000080d9, 0x00000000);
xcode_outb(0x00008026, 0x00000001);
xcode_pciout(0x8000f04c, 0x00000001);
xcode_pciout(0x8000f018, 0x00010100);
xcode_pciout(0x80000084, 0x07ffffff);

xcode_pciout(0x8000f020, 0x0ff00f00);
xcode_pciout(0x8000f024, 0xf7f0f000);
xcode_pciout(0x80010010, 0x0f000000);
xcode_pciout(0x80010014, 0xf0000000);
xcode_pciout(0x80010004, 0x00000007);
xcode_pciout(0x8000f004, 0x00000007);
// Set up the SM - bus controller
xcode_pciout(0x80000904, 0x00000001);
xcode_pciout(0x80000914, 0x0000c001);
xcode_pciout(0x80000918, 0x0000c201);
xcode_goto_label(common_init);
//xcode_goto_label(xcalibur_init);	//Not very useful! Probably leftover from debugging...

common_init:
xcode_poke(0x0f0010b0, 0x07633461);
xcode_poke(0x0f0010cc, 0x66660000);
xcode_peek(0x0f101000);
xcode_bittoggle(0x000c0000, 0x00000000);
xcode_ifngoto_label(0x00000000, common_init_alt1);
xcode_peek(0x0f101000);
xcode_bittoggle(0xe1f3ffff, 0x80000000);
xcode_poke_a(0x0f101000);
xcode_poke(0x0f0010b8, 0xeeee0000);
xcode_goto_label(common_init_ending);

common_init_alt1:
xcode_ifngoto_label(0x000c0000, common_init_alt2);
xcode_peek(0x0f101000);
xcode_bittoggle(0xe1f3ffff, 0x860c0000);
xcode_poke_a(0x0f101000);
xcode_poke(0x0f0010b8, 0xffff0000);
xcode_goto_label(common_init_ending);

common_init_alt2:
xcode_peek(0x0f101000);
xcode_bittoggle(0xe1f3ffff, 0x820c0000);
xcode_poke_a(0x0f101000);
xcode_poke(0x0f0010b8, 0x11110000);

common_init_ending:								//Ultimately, all of the above code merge back to here.
xcode_poke(0x0f0010d4, 0x00000009);
xcode_poke(0x0f0010b4, 0x00000000);
xcode_poke(0x0f0010bc, 0x00005866);
xcode_poke(0x0f0010c4, 0x0351c858);
xcode_poke(0x0f0010c8, 0x30007d67);
xcode_poke(0x0f0010d8, 0x00000000);
xcode_poke(0x0f0010dc, 0xa0423635);
xcode_poke(0x0f0010e8, 0x0c6558c6);
xcode_poke(0x0f100200, 0x03070103);
xcode_poke(0x0f100410, 0x11000016);
xcode_poke(0x0f100330, 0x84848888);
xcode_poke(0x0f10032c, 0xffffcfff);
xcode_poke(0x0f100328, 0x00000001);
xcode_poke(0x0f100338, 0x000000df);
xcode_outb(0x0000c200, 0x00000070);

//VIDEO INIT CODE
/* It is necessary to write to the video encoder, as the PIC
 snoops the I2C traffic and will reset us if it doesn't see what
 it judges as 'appropriate' traffic.  Conexant is the most urgent,
 as on 1.0 Xboxes, the PIC was very strict and reset us earlier
 than later models
 */
 //This is focus...
xcode_outb(SMBUS+4, 0x000000d4);
xcode_outb(SMBUS+8, 0x0000000c);
xcode_outb(SMBUS+6, 0x00000000);
xcode_outb(SMBUS+2, 0x0000000a);

xcode_inb(SMBUS);
xcode_ifngoto(0x00000010, 0x00000002);
xcode_goto_label(focus_init_part2);						//Success!
xcode_bittoggle(0x00000008, 0x00000000); //Check fail status
xcode_ifngoto(0x00000000, SMBUS_READ_RETRY);//No result yet, read again.
xcode_outb(SMBUS, 0x000000ff);
xcode_goto_label(connexant_init);			//Abandon focus, go to connexant

focus_init_part2:						//focus phase 2
xcode_outb(SMBUS, 0x00000010);
SMB_xcode_Write(0x0000000d, 0x00000020);
xcode_goto_label(focus_init_part3);		//Oops, missed that one.

connexant_init:			//Connexant init attempt.
xcode_outb(SMBUS, 0x00000010);
xcode_outb(SMBUS+4, 0x0000008a);	//This is the address for connexant.
xcode_outb(SMBUS+8, 0x000000ba);
xcode_outb(SMBUS+6, 0x0000003f);
xcode_outb(SMBUS+2, 0x0000000a);
xcode_inb(SMBUS);
xcode_ifngoto(0x00000010, 0x00000002); //Write failed, forward 2
xcode_goto_label(connexant_init_part2);						//Success!
xcode_bittoggle(0x00000008, 0x00000000);//Check fail status
xcode_ifngoto(0x00000000, SMBUS_READ_RETRY);//No result yet, read again.
xcode_outb(SMBUS, 0x000000ff);			//Abandon connexant.
xcode_outb(SMBUS, 0x00000010);

//xcode_outb(SMBUS+4, 0x000000e0);
//SMB_xcode_Write(0x00000000, 0x00000000);
//SMB_xcode_Write(0x000000b8, 0x00000000);
xcode_goto_label(xcalibur_init);				//to 1.6 init?

connexant_init_part2:				//Connexant phase 2
xcode_outb(SMBUS, 0x00000010);
SMB_xcode_Write(0x0000006c, 0x00000046);
SMB_xcode_Write(0x000000b8, 0x00000000);
SMB_xcode_Write(0x000000ce, 0x00000019);
SMB_xcode_Write(0x000000c6, 0x0000009c);
SMB_xcode_Write(0x00000032, 0x00000008);
SMB_xcode_Write(0x000000c4, 0x00000001);

//VIDEND - Encoder 'init' complete.

// PIC SLAVE Address (Write)
focus_init_part3:	//Connexant, focus common phase 3.
xcode_outb(SMBUS+4, 0x00000020);
// I2Ctransmit(0x20,0x1,0x0);
SMB_xcode_Write(0x00000001, 0x00000000);

// PIC SLAVE Address (Read)
xcode_outb(SMBUS+4, 0x00000021);

// I2Cgetbyte(0x8a,0x1);
xcode_outb(SMBUS+8, 0x00000001);
xcode_outb(SMBUS+2, 0x0000000a);
xcode_inb(SMBUS);
xcode_ifngoto(0x00000010, -1);	//retry
xcode_outb(SMBUS, 0x00000010);

// If SMC version does not match ... ?????
xcode_inb(SMBUS+6);

//Not going to add markers in this section. Pointless since self-contained.
xcode_poke(0x0f680500, 0x00011c01);
xcode_poke(0x0f68050c, 0x000a0400);
xcode_poke(0x0f001220, 0x00000000);
xcode_poke(0x0f001228, 0x00000000);
xcode_poke(0x0f001264, 0x00000000);
xcode_poke(0x0f001210, 0x00000010);
xcode_peek(0x0f101000);
xcode_bittoggle(0x06000000, 0x00000000);
xcode_ifngoto(0x00000000, 0x00000004);
xcode_poke(0x0f001214, 0x48480848);
xcode_poke(0x0f00122c, 0x88888888);
xcode_goto(0x00000007);
xcode_ifngoto(0x06000000, 0x00000004);
xcode_poke(0x0f001214, 0x09090909);
xcode_poke(0x0f00122c, 0xaaaaaaaa);
xcode_goto(0x00000003);
xcode_poke(0x0f001214, 0x09090909);
xcode_poke(0x0f00122c, 0xaaaaaaaa);
xcode_poke(0x0f001230, 0xffffffff);
xcode_poke(0x0f001234, 0xaaaaaaaa);
xcode_poke(0x0f001238, 0xaaaaaaaa);
xcode_poke(0x0f00123c, 0x8b8b8b8b);
xcode_poke(0x0f001240, 0xffffffff);
xcode_poke(0x0f001244, 0x8b8b8b8b);
xcode_poke(0x0f001248, 0x8b8b8b8b);
xcode_poke(0x0f1002d4, 0x00000001);
xcode_poke(0x0f1002c4, 0x00100042);
xcode_poke(0x0f1002cc, 0x00100042);
xcode_poke(0x0f1002c0, 0x00000011);
xcode_poke(0x0f1002c8, 0x00000011);
xcode_poke(0x0f1002c0, 0x00000032);
xcode_poke(0x0f1002c8, 0x00000032);
xcode_poke(0x0f1002c0, 0x00000232);
xcode_poke(0x0f1002c8, 0x00000232);
xcode_poke(0x0f1002d0, 0x00000001);
xcode_poke(0x0f1002d0, 0x00000001);
xcode_poke(0x0f100210, 0x80000000);
xcode_poke(0x0f00124c, 0xaa8baa8b);
xcode_poke(0x0f001250, 0x0000aa8b);
xcode_poke(0x0f100228, 0x081205ff);
xcode_poke(0x0f001218, 0x00010000);
xcode_pciin_a(0x80000860);
xcode_bittoggle(0xffffffff, 0x00000400);
xcode_pciout_a(0x80000860);
xcode_pciout(0x8000084c, 0x0000fdde);
xcode_pciout(0x8000089c, 0x871cc707);
xcode_pciin_a(0x800008b4);
xcode_bittoggle(0xfffff0ff, 0x00000f00);
xcode_pciout_a(0x800008b4);
xcode_pciout(0x80000340, 0xf0f0c0c0);
xcode_pciout(0x80000344, 0x00c00000);
xcode_pciout(0x8000035c, 0x04070000);
xcode_goto_label(endExec);

xcalibur_init:
xcode_outb(0x0000c200, 0x00000070);
xcode_poke(0x0f0010b0, 0x01000010);
xcode_poke(0x0f0010cc, 0x66660000);
xcode_goto_label(xcalibur_init_part2);

label13:
xcode_poke(0x0f0010d4, 0x0000000f);
xcode_poke(0x0f0010b4, 0x00000000);
xcode_poke(0x0f0010bc, 0x00005860);
xcode_poke(0x0f0010c4, 0xaaaa0000);
xcode_poke(0x0f0010c8, 0x00007d67);
xcode_poke(0x0f0010d8, 0x00000000);
xcode_poke(0x0f0010dc, 0x00000000);
xcode_poke(0x0f0010e8, 0x04000000);
xcode_poke(0x0f100200, 0x03070103);
xcode_poke(0x0f100410, 0x11000016);
xcode_poke(0x0f100330, 0x84848888);
xcode_poke(0x0f10032c, 0xffffcfff);
xcode_poke(0x0f100328, 0x00000001);
xcode_poke(0x0f100338, 0x000000df);
xcode_outb(SMBUS+4, 0x00000020);
SMB_xcode_Write(0x00000001, 0x00000000);
xcode_outb(SMBUS+4, 0x00000021);
xcode_outb(SMBUS+8, 0x00000001);
xcode_outb(SMBUS+2, 0x0000000a);
xcode_inb(SMBUS);
xcode_ifngoto(0x00000010, -1);
xcode_outb(SMBUS, 0x00000010);
xcode_inb(SMBUS+6);
xcode_ifngoto(0x00000050, 0x00000002);
xcode_goto(0x00000002);
xcode_pciout(0x8000036c, 0x01000000);
xcode_poke(0x0f680500, 0x00011c01);
xcode_poke(0x0f68050c, 0x000a0400);
xcode_poke(0x0f001220, 0x00000000);
xcode_poke(0x0f001228, 0x00000000);
xcode_poke(0x0f001264, 0x00000000);
xcode_poke(0x0f001210, 0x00000000);
xcode_goto_label(xcalibur_init_part3);

xcalibur_init_part2:
xcode_pciout(0x8000183c, 0x000000c3);

xcalibur_init_part3:
xcode_outb(SMBUS+4, 0x000000a9);
xcode_pciin_a(0x8000183c);
xcode_outb_a(0x0000c008);
xcode_outb(SMBUS, 0x00000000);
xcode_outb(SMBUS+2, 0x0000000a);
xcode_inb(SMBUS);
xcode_pciout_a(0x8000103c);
xcode_bittoggle(0x00000008, 0x00000000);
xcode_ifngoto(0x00000008, 0x00000002);
xcode_goto(SMBUS_READ_RETRY);
xcode_pciin_a(0x8000103c);
xcode_bittoggle(0x000000ff, 0x00000000);
xcode_ifngoto_label(0x00000010, xcalibur_init_part3);
xcode_inb(SMBUS+6);
xcode_bittoggle(0x000000ff, 0x00000000);
xcode_poke_a(0x0f001248);
xcode_pciin_a(0x8000183c);
xcode_bittoggle(0x000000ff, 0x00000000);
xcode_ifngoto_label(0x000000c3, label11);
xcode_peek(0x0f001248);
xcode_ifngoto(0x00000042, 0x00000004);
xcode_peek(0x0f101000);
xcode_bittoggle(0xe1f3ffff, 0x800c0000);
xcode_goto_label(label12);
xcode_ifngoto(0x00000040, 0x00000004);
xcode_peek(0x0f101000);
xcode_bittoggle(0xe1f3ffff, 0x80080000);
xcode_goto_label(label12);
xcode_ifngoto(0x00000002, 0x00000004);
xcode_peek(0x0f101000);
xcode_bittoggle(0xe1f3ffff, 0x80040000);
xcode_goto_label(label12);
xcode_peek(0x0f101000);
xcode_bittoggle(0xe1f3ffff, 0x80000000);

label12:
xcode_poke_a(0x0f101000);
xcode_pciout(0x8000183c, 0x000000c2);
xcode_goto_label(xcalibur_init_part3);

label11:
xcode_peek(0x0f001248);
xcode_bittoggle(0x00000001, 0x00000000);
xcode_ifngoto_label(0x00000000, label14);
xcode_peek(0x0f001248);

label14_2:
	xcode_bittoggle(0x00000002,0x00000000);
	xcode_ifngoto_label(0x00000000,label15)
	xcode_peek(0x0f001248);

label15_2:
	xcode_bittoggle(0x00000004,0x00000000);
	xcode_ifngoto_label(0x00000000,label16)
	xcode_peek(0x0f001248);

label16_2:
	xcode_bittoggle(0x00000008,0x00000000);
	xcode_ifngoto_label(0x00000000,label17)
	xcode_peek(0x0f001248);

label17_2:
	xcode_bittoggle(0x00000010,0x00000000);
	xcode_ifngoto_label(0x00000000,label18)
	xcode_peek(0x0f001248);

label18_2:
	xcode_bittoggle(0x00000020,0x00000000);
	xcode_ifngoto_label(0x00000000,label19)
	xcode_peek(0x0f001248);

label19_2:
	xcode_bittoggle(0x00000040,0x00000000);
	xcode_ifngoto_label(0x00000000,label20)
	xcode_peek(0x0f001248);

label20_2:
	xcode_bittoggle(0x00000080,0x00000000);
	xcode_ifngoto_label(0x00000000,label21)

label21_2:

	xcode_pciin_a(0x8000183C);
	xcode_bittoggle(0x000000ff,0x00000000);

	xcode_ifngoto_label(0x000000c2,label22)

	xcode_peek(0x0f001248);
	xcode_bittoggle(0xffff0000,0x00000000);
	xcode_poke_a(0x0f0010b8);
	xcode_pciout(0x8000183C, 0x000000c1);

	xcode_goto_label(label13)

label22:

	xcode_pciin_a(0x8000183C);
	xcode_bittoggle(0x000000ff,0x00000000);
	xcode_ifngoto_label(0x000000c1,label23)
	xcode_peek(0x0f001248);
	xcode_poke_a(0x0f00122c);
	xcode_pciout(0x8000183C, 0x000000c0);
	xcode_goto_label(xcalibur_init_part3)

label23:

	xcode_peek(0x0f001248);
	xcode_poke_a(0x0f001214);

	xcode_pciout(0x8000183C, 0x000000c3);
	xcode_goto_label(extendedEndExec)

label14:
	xcode_peek(0x0f001248);
	xcode_bittoggle(0xffffffff,0x01010100);
	xcode_poke_a(0x0f001248);
	xcode_goto_label(label14_2);

label15:
	xcode_peek(0x0f001248);
	xcode_bittoggle(0xffffffff,0x02020200);
	xcode_poke_a(0x0f001248);
	xcode_goto_label(label15_2);

label16:
	xcode_peek(0x0f001248);
	xcode_bittoggle(0xffffffff,0x04040400);
	xcode_poke_a(0x0f001248);
	xcode_goto_label(label16_2);

label17:
	xcode_peek(0x0f001248);
	xcode_bittoggle(0xffffffff,0x08080800);
	xcode_poke_a(0x0f001248);
	xcode_goto_label(label17_2);

label18:
	xcode_peek(0x0f001248);
	xcode_bittoggle(0xffffffff,0x10101000);
	xcode_poke_a(0x0f001248);
	xcode_goto_label(label18_2);

label19:
	xcode_peek(0x0f001248);
	xcode_bittoggle(0xffffffff,0x20202000);
	xcode_poke_a(0x0f001248);
	xcode_goto_label(label19_2);

label20:
	xcode_peek(0x0f001248);
	xcode_bittoggle(0xffffffff,0x40404000);
	xcode_poke_a(0x0f001248);
	xcode_goto_label(label20_2);

label21:
	xcode_peek(0x0f001248);
	xcode_bittoggle(0xffffffff,0x80808000);
	xcode_poke_a(0x0f001248);
	xcode_goto_label(label21_2);


extendedEndExec:

	xcode_poke(0x0f001248, 0x00000000);
	xcode_poke(0x0f001230, 0xffffffff);
	xcode_poke(0x0f001234, 0xaaaaaaaa);
	xcode_poke(0x0f001238, 0xaaaaaaaa);
	xcode_poke(0x0f00123c, 0x8b8b8b8b);
	xcode_poke(0x0f001240, 0xffffffff);
	xcode_poke(0x0f001244, 0x8b8b8b8b);
	xcode_poke(0x0f001248, 0x8b8b8b8b);
	xcode_poke(0x0f1002d4, 0x00000001);
	xcode_poke(0x0f1002c4, 0x00100000);
	xcode_poke(0x0f1002cc, 0x00100000);
	xcode_poke(0x0f1002c0, 0x00000011);
	xcode_poke(0x0f1002c8, 0x00000011);
	xcode_poke(0x0f1002c0, 0x00000032);
	xcode_poke(0x0f1002c8, 0x00000032);
	xcode_poke(0x0f1002c0, 0x00000232);
	xcode_poke(0x0f1002c8, 0x00000232);
	xcode_poke(0x0f1002d0, 0x00000001);
	xcode_poke(0x0f1002d0, 0x00000001);
	xcode_poke(0x0f100210, 0x80000000);
	xcode_poke(0x0f00124c, 0xaa8baa8b);
	xcode_poke(0x0f001250, 0x00005474);
	xcode_poke(0x0f100228, 0x081205ff);
	xcode_poke(0x0f001218, 0x00000000);

	xcode_pciin_a(0x80000860);
	xcode_bittoggle(0xffffffff,0x00000400);
	xcode_pciout_a(0x80000860);


	xcode_pciout(0x8000084c, 0x0000fdde);
	xcode_pciout(0x8000089c, 0x871cc707);
	xcode_pciin_a(0x800008b4);
	xcode_bittoggle(0xfffff0ff,0x00000f00);
	xcode_pciout_a(0x800008b4);
	xcode_pciout(0x80000340, 0xf0f0c0c0);
	xcode_pciout(0x80000344, 0x00000000);
	xcode_pciout(0x8000035c, 0x00000000);

endExec:		//There is no going back now.
xcode_pciout(0x8000036c, 0x00230801); //MPLL coefficient (for FSB) (MEM_PDIV = 2, FSB_PMULT = 3, NMULT = 8, MDIV = 1). Default 0x00230801
xcode_pciout(0x8000036c, 0x01230801); //"override" version of above
xcode_goto(1); //NOP
xcode_goto(1); //NOP


//Set up RAM configuration
xcode_poke(0x0f100204, 0x11449010); //Assume 256MB (9 column bits + AP on 'A9')
xcode_poke(0x00001048, 0xCAFEBABE); //Write to a word that has the A8 column bit set. A standard Xbox won't care about A8 being set
xcode_peek(0x0f001210); //Add early DQS
xcode_bittoggle(0xFFFFFFFF, 0x100); //Add early DQS
xcode_poke_a(0x0f001210); //Add early DQS - required to ensure accurate reading on 256Mbit RAM
xcode_peek(0x00000048) //Read back to see if it was actually written to the same address with A8 = 0
xcode_ifngoto_label(0xCAFEBABE, ram_256mbit_detected);
xcode_poke(0x0f100204, 0x11448000); //Use normal xbox config
xcode_peek(0x0f001210); //Remove early DQS
xcode_bittoggle(0xFFFFFEFF, 0x0); //Remove early DQS
xcode_poke_a(0x0f001210); //Remove early DQS - required to stabilise stock RAM
xcode_goto_label(ram_setup_exit);
ram_256mbit_detected:
xcode_pciout(0x80000084, 0x0FFFFFFF); //Set 256MB of RAM
xcode_poke(0x0f100200, 0x03070103); //Enable the second rank to check for its presence
xcode_poke(0x08001234, 0xDEADBEEF); //128MB/256MB check
xcode_peek(0x08001234);
xcode_ifngoto_label(0xDEADBEEF, only_128MB_ram);
xcode_goto_label(ram_setup_exit);
only_128MB_ram:
xcode_pciout(0x80000084, 0x07FFFFFF); //Set 128MB of RAM
xcode_poke(0x0f100200, 0x03070003); //required for booting MS BIOSes
ram_setup_exit:

//Set USB interrupts to IRQ 0
xcode_pciout(0x8000103c, 0x00000000); //PCI bus 0, dev 2, func 0, offset 3C
xcode_pciout(0x8000183c, 0x00000000); //PCI bus 0, dev 3, func 0, offset 3C

/* ----  Report Memory Size to PIC scratch register ---- */
// We emulate Good memory result to PIC
xcode_outb(SMBUS, 0x00000010);
xcode_outb(SMBUS+4, 0x00000020);
SMB_xcode_Write(0x00000013, 0x0000000f);
SMB_xcode_Write(0x00000012, 0x000000f0);

/* ---- Reload Nvidia Registers  ------------------------*/

xcode_pciout(0x8000f020, 0xfdf0fd00);
xcode_pciout(0x80010010, 0xfd000000);

// Visor trick (EIP overflow)
#define ASM_START 0xFF0
xcode_poke(0x00000000, 0xB8 + (ASM_START << 8)); //Write a jump to flash into RAM address 0
xcode_poke(0x00000004, 0x00E0FFFF);
xcode_END(0x00000806);


	// This is the Main Entry point
	.org ASM_START
        
	// Good Morning CPU

	// NOTE:
	// We come here form the high rom section Jump

	// Clear Intel Interrupts in Processor Register
	// Everytime very good, specially when comming out of a running envoronment

	movl	$0x1b, %ecx
	xor	%eax, %eax
	xor	%edx, %edx
	wrmsr

	// Interrupts now Dead

	// kill the cache  = Disable bit 30 + 29 = CD + NW
	// CD = Cache Disable (disable = 1)
	// NW Not write through (disable = 1)
	mov 	%cr0, %eax
	orl	$0x60000000, %eax
	mov	%eax, %cr0
	wbinvd

	// We clear the cr3 register
	mov	%eax, %eax
	mov	%eax, %cr3

	// Clear Memory Type register
	movl	$0x2ff, %ecx
	xor	%eax, %eax
	xor	%edx, %edx
	wrmsr

	//We are setting the Ram Init's now to set up the Regions in the Ram

	// MTRR for RAM
	// from address 0, Writeback Caching, 256MB range
	movl	$0x200, %ecx //BASE0
	movl	$0x00000000, %edx
	movl	$0x00000006, %eax 	// == WB_CACHE == 6
	wrmsr
	// MASK0 set to 0xf0000[000] == 256M
	movl	$0x201, %ecx //MASK0
	movl	$0x0000000f, %edx
	movl	$0xf0000800, %eax
	wrmsr

	// MTRR for shadow RAM
	// from address 0xf0000000, Write-combining Caching, 128MB range
	// Even with 256MB RAM present, shadow RAM cannot be bigger than 128MB
	movl	$0x202, %ecx //BASE1
	movl	$0x00000000, %edx
	movl	$0xf0000001, %eax 	// Write-Combining == 1
	wrmsr
	// MASK1 set to 0xf8000[000] == 128M
	movl	$0x203, %ecx //MASK1
	movl	$0x0000000f, %edx
	movl	$0xf8000800, %eax
	wrmsr
	
	// MTRR for flash ROM
	// from address 0xFF000000, uncacheable, 16MB range
	// Caching flash stops xblast from booting properly, and would break flash chip identification and programming
	movl $0x204, %ecx
	movl $0x00000000, %edx
	movl $0xFF000000, %eax
	wrmsr
	// MASK2 set to 0xFF000[000] = 16MB
	movl $0x205, %ecx
	movl $0x0000000F, %edx
	movl $0xFF000800, %eax
	wrmsr

	//Clear the rest of the MTRRs
	xor %eax, %eax
	xor %edx, %edx
	mov $10, %bl
	mtrr_loop:
		inc %ecx // IA32_MTRR_PHYS Base and MASK 3 to 7
		wrmsr
		dec %bl
		jnz mtrr_loop

	// Default MTRR set to uncacheable
	movl	$0x2ff, %ecx
	xor	%edx, %edx
	movl	$0x800, %eax
	wrmsr

	/* turn on normal cache */
	//  bit 30 + 29 = CD + NW
	// CD = Cache Disable (disable = 1)
	// NW Not write through (disable = 1)
	movl	%cr0, %eax
	mov 	%eax, %ebx
	andl	$0x9FFFFFFF,%eax
	movl	%eax, %cr0

	cld
	
	#define SMCReadByte(addr) \
	movl %edx, %ebp; /* Save edx */ \
	2:; \
	movb addr, %al; \
	movw $(SMBUS+8), %dx; \
	outb %al, %dx; \
	movb $0xA, %al; /*control register */ \
	movw $(SMBUS+2), %dx; \
	outb %al, %dx; \
	movw $SMBUS, %dx; \
	1:; \
	inb %dx, %al; /*Read status register */ \
	and $0x36, %al; \
	jz 1b; /*Wait for transaction done */ \
	and $0x10, %al; \
	jz 2b; /* Retry */ \
	movb $0xFF, %al; /*Clear flags */ \
	movw $SMBUS, %dx; \
	outb %al, %dx; \
	movw $(SMBUS+6), %dx; \
	inb %dx, %al; /*Read status register */ \
	movl %ebp, %edx; /* Restore edx */

#define SMCWriteByte(addr, val); \
	movl %edx, %ebp; /* Save edx */ \
	2:; \
	movb addr, %al; \
	movw $(SMBUS+8), %dx; \
	outb %al, %dx; \
	movb val, %al; \
	movw $(SMBUS+6), %dx; \
	outb %al, %dx; \
	movb $0xA, %al; /*control register */ \
	movw $(SMBUS+2), %dx; \
	outb %al, %dx; \
	movw $SMBUS, %dx; \
	1:; \
	inb %dx, %al; /*Read status register */ \
	and $0x36, %al; \
	jz 1b; /*Wait for transaction done */ \
	and $0x10, %al; \
	jz 2b; /* Retry */ \
	movb $0xFF, %al; /*Clear flags */ \
	movw $SMBUS, %dx; \
	outb %al, %dx; \
	movl %ebp, %edx; /* Restore edx */
	
	
	//SMC challenge (formerly BootPerformPicChallengeResponseAction)
	//The challenge is done here rather than after loading RAM because it is quicker to stop the
	//SMC from giving us any resets. Since the 1.0 SMC is particularly strict, it would time out
	//in some conditions (such as when software bank switching on an Xecuter X3)
	movb $0x21, %al //Select SMC in read mode
	movw $(SMBUS+4), %dx
	outb %al, %dx
	
	SMCReadByte($0x1D)
	mov %al, %bl
	SMCReadByte($0x1E)
	mov %al, %cl
	SMCReadByte($0x1F)
	mov %al, %dl
	SMCReadByte($0x1C)
	
	//b3 in ch
	mov %al, %ch
	shl $2, %ch
	mov %bl, %ah
	add $0x39, %ah
	xor %ah, %ch
	mov %cl, %ah
	shr $2, %ah
	xor %ah, %ch
	mov %dl, %ah
	add $0x63, %ah
	xor %ah, %ch
	//b4 in dh
	mov %al, %dh
	add $0x0B, %dh
	mov %bl, %ah
	shr $2, %ah
	xor %ah, %dh
	mov %cl, %ah
	add $0x1B, %ah
	xor %ah, %dh
	
	mov $0x33, %ah //b1
	mov $0xED, %bh //b2
	
	mov $4, %bl
	challenge_loop:
	mov %bh, %al
	xor %ch, %al
	add %al, %ah
	mov %ah, %al
	xor %dh, %al
	add %al, %bh
	
	dec %bl
	jne challenge_loop
	
	//Send challenge response
	movb $0x20, %al //Select SMC in write mode
	movw $(SMBUS+4), %dx
	outb %al, %dx
	SMCWriteByte($0x20, %ah)
	SMCWriteByte($0x21, %bh)
	SMCWriteByte($0x01, $0x00)

#if BUILD_RAMTEST
	//Boot to xblast or ram test? check DVD drive
	movb $0x21, %al //Select SMC in read mode
	movw $(SMBUS+4), %dx
	outb %al, %dx
	SMCReadByte($0x03)
	cmp $0x01, %al
	jne flash_code //Go to ram test
#endif

	// copy everything into RAM 

	mov 	$_ram_location, %edi
	mov 	$_start_ramcopy, %esi
	mov 	$(_size_ramcopy + 6), %ecx
	shr	$2,%ecx    // We dividy / 4, as we copy Dword oriented
	rep 	movsl //Move ecx dwords from [esi] to [edi]
	
	jmp   initaftermemcpy



//x86 asm equivalents of some useful xcodes
//edi is the accumulator
#define x86code_poke(val1,val2) movl $val1, %eax; \
                              movl $val2, (%eax)

#define x86code_pciout(val1,val2) movw $0xCF8, %dx; \
                                movl $val1, %eax; \
                                outl %eax, %dx; \
                                add $4, %dx; \
                                movl $val2, %eax; \
                                outl %eax, %dx

#define x86code_outb(val1,val2) movb $val2, %al; \
                              movw $val1, %dx; \
                              outb %al, %dx

//Using ebp as the return address for function 'calls'. For when we can't trust RAM to hold a stack
#define CALL_CUSTOM(addr) movl $3f, %ebp; \
						  jmp addr; \
						  3:

//Seeded pseudo-random number generator
#define LFSR_SEED 0x149E22C1
#define TEST_MIN_ADDR 0x00000000
#define TEST_MAX_ADDR 0x00400000 //Testing the whole of RAM would take an extremely long time. This still exercises all address pins
#define LFSR_STEP() shr $1, %ecx; \
                    jc 1f; \
					xor $0x80200003, %ecx; \
					1:;

flash_code:
	//This is the code that tests the lower half of RAM and reports back if it works or not
	
	x86code_pciout(0x80000084, 0x0FFFFFFF) //Allow the full 256MB
	x86code_outb(SMBUS+4, 0x20) //Select SMC in write mode
	
	//25% flash LED orange
	mov $0x0888, %ax
	CALL_CUSTOM(smbus_send)
	mov $0x0701, %ax
	CALL_CUSTOM(smbus_send)
	
	//Disable cache
	mov 	%cr0, %eax
	orl	$0x60000000, %eax
	mov	%eax, %cr0
	//Empty cache
	wbinvd
	// Set flash cache to be write-back cacheable
	movl $0x204, %ecx
	movl $0x00000000, %edx
	movl $0xFF000006, %eax
	wrmsr
	//Enable cache
	movl	%cr0, %eax
	mov 	%eax, %ebx
	andl	$0x9FFFFFFF,%eax
	movl	%eax, %cr0
	
	//Use 9 column bits, AP select bit, and timing switch
#if RAMTEST_256MB
	wbinvd
	x86code_poke(0xFD100204, 0x11449010)
	x86code_poke(0xFD001210, 0x00000110)
	wbinvd
#endif
	
	//50% flash LED orange
	mov $0x08CC, %ax
	CALL_CUSTOM(smbus_send)
	mov $0x0701, %ax
	CALL_CUSTOM(smbus_send)
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//RAM test - bank 0
	mov $TEST_MIN_ADDR, %ebx //ebx is the pointer to the address under test
	mov $LFSR_SEED+0, %ecx //ecx is the LFSR value
	
	////////////////////// Populate RAM //////////////////////
	pop_loop:
		mov %ecx, (%ebx)
		LFSR_STEP()
		mov %ecx, 4(%ebx)
		LFSR_STEP()
		mov %ecx, 8(%ebx)
		LFSR_STEP()
		mov %ecx, 12(%ebx)
		LFSR_STEP()
		
		add $0x40, %ebx //Go to next group
		cmp $TEST_MAX_ADDR, %ebx
		jl pop_loop //jump if ebx < TEST_MAX_ADDR
	
	
	////////////////////// Read back and test //////////////////////
	wbinvd
	
	mov $TEST_MIN_ADDR, %ebx //ebx is the pointer to the address under test
	mov $LFSR_SEED+0, %ecx //ecx is the LFSR value
		
	//Test RAM
	test_loop:
		cmp %ecx, (%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 4(%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 8(%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 12(%ebx)
		jne bad_result
		LFSR_STEP()
			
		//next_addr:
			add $0x40, %ebx
			cmp $TEST_MAX_ADDR, %ebx
			jl test_loop //jump if ebx < TEST_MAX_ADDR
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//LED = rxgx
	mov $0x0882, %ax
	CALL_CUSTOM(smbus_send)
	mov $0x0701, %ax
	CALL_CUSTOM(smbus_send)
	//RAM test - bank 1
	mov $TEST_MIN_ADDR, %ebx //ebx is the pointer to the address under test
	add $0x10, %ebx
	mov $LFSR_SEED+5, %ecx //ecx is the LFSR value
	
	////////////////////// Populate RAM //////////////////////
	pop_loop2:
		mov %ecx, (%ebx)
		LFSR_STEP()
		mov %ecx, 4(%ebx)
		LFSR_STEP()
		mov %ecx, 8(%ebx)
		LFSR_STEP()
		mov %ecx, 12(%ebx)
		LFSR_STEP()
		
		add $0x40, %ebx //Go to next group
		cmp $TEST_MAX_ADDR, %ebx
		jl pop_loop2 //jump if ebx < TEST_MAX_ADDR
	
	
	////////////////////// Read back and test //////////////////////
	wbinvd
	
	mov $TEST_MIN_ADDR, %ebx //ebx is the pointer to the address under test
	add $0x10, %ebx
	mov $LFSR_SEED+5, %ecx //ecx is the LFSR value
		
	//Test RAM
	test_loop2:
		cmp %ecx, (%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 4(%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 8(%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 12(%ebx)
		jne bad_result
		LFSR_STEP()
			
		//next_addr:
			add $0x40, %ebx
			cmp $TEST_MAX_ADDR, %ebx
			jl test_loop2 //jump if ebx < TEST_MAX_ADDR
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//LED = rrgg
	mov $0x08C3, %ax
	CALL_CUSTOM(smbus_send)
	mov $0x0701, %ax
	CALL_CUSTOM(smbus_send)
	//RAM test - bank 2
	mov $TEST_MIN_ADDR, %ebx //ebx is the pointer to the address under test
	add $0x20, %ebx
	mov $LFSR_SEED+29, %ecx //ecx is the LFSR value
	
	////////////////////// Populate RAM //////////////////////
	pop_loop3:
		mov %ecx, (%ebx)
		LFSR_STEP()
		mov %ecx, 4(%ebx)
		LFSR_STEP()
		mov %ecx, 8(%ebx)
		LFSR_STEP()
		mov %ecx, 12(%ebx)
		LFSR_STEP()
		
		add $0x40, %ebx //Go to next group
		cmp $TEST_MAX_ADDR, %ebx
		jl pop_loop3 //jump if ebx < TEST_MAX_ADDR
	
	
	////////////////////// Read back and test //////////////////////
	wbinvd
	
	mov $TEST_MIN_ADDR, %ebx //ebx is the pointer to the address under test
	add $0x20, %ebx
	mov $LFSR_SEED+29, %ecx //ecx is the LFSR value
		
	//Test RAM
	test_loop3:
		cmp %ecx, (%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 4(%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 8(%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 12(%ebx)
		jne bad_result
		LFSR_STEP()
			
		//next_addr:
			add $0x40, %ebx
			cmp $TEST_MAX_ADDR, %ebx
			jl test_loop3 //jump if ebx < TEST_MAX_ADDR
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//LED = ogog
	mov $0x08AF, %ax
	CALL_CUSTOM(smbus_send)
	mov $0x0701, %ax
	CALL_CUSTOM(smbus_send)
	//RAM test - bank 3
	mov $TEST_MIN_ADDR, %ebx //ebx is the pointer to the address under test
	add $0x30, %ebx
	mov $LFSR_SEED+76, %ecx //ecx is the LFSR value
	
	////////////////////// Populate RAM //////////////////////
	pop_loop4:
		mov %ecx, (%ebx)
		LFSR_STEP()
		mov %ecx, 4(%ebx)
		LFSR_STEP()
		mov %ecx, 8(%ebx)
		LFSR_STEP()
		mov %ecx, 12(%ebx)
		LFSR_STEP()
		
		add $0x40, %ebx //Go to next group
		cmp $TEST_MAX_ADDR, %ebx
		jl pop_loop4 //jump if ebx < TEST_MAX_ADDR
	
	
	////////////////////// Read back and test //////////////////////
	wbinvd
	
	mov $TEST_MIN_ADDR, %ebx //ebx is the pointer to the address under test
	add $0x30, %ebx
	mov $LFSR_SEED+76, %ecx //ecx is the LFSR value
		
	//Test RAM
	test_loop4:
		cmp %ecx, (%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 4(%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 8(%ebx)
		jne bad_result
		LFSR_STEP()
		
		cmp %ecx, 12(%ebx)
		jne bad_result
		LFSR_STEP()
			
		//next_addr:
			add $0x40, %ebx
			cmp $TEST_MAX_ADDR, %ebx
			jl test_loop4 //jump if ebx < TEST_MAX_ADDR
	
	//Done
	//Fast flash LED green
	mov $0x0805, %ax
	CALL_CUSTOM(smbus_send)
	mov $0x0701, %ax
	CALL_CUSTOM(smbus_send)
	jmp infloop
	
bad_result:
	//Report error
	//Save ebx
	movl %ebx, %esp
	
	//Look at bits 5:4 of %ebx
	and $0x30, %bl
	shr $4, %bl
	movzx %bl, %eax
	
	//Index ledcodes
	mov $ledcodes, %ebx
	add %eax, %ebx
	mov (%ebx), %al
	
	//Set LED
	mov $0x08, %ah
	CALL_CUSTOM(smbus_send)
	mov $0x0701, %ax
	CALL_CUSTOM(smbus_send)
	
	
	movl %esp, %ebx
	
	//Address of fault
	mov $0x8F, %ah
	mov %bl, %al
	CALL_CUSTOM(smbus_send)
	mov $0x8E, %ah
	mov %bh, %al
	CALL_CUSTOM(smbus_send)
	shr $16, %ebx
	mov $0x8E, %ah
	mov %bl, %al
	CALL_CUSTOM(smbus_send)
	mov $0x8E, %ah
	mov %bh, %al
	CALL_CUSTOM(smbus_send)
	
	//Actual data
	mov (%ebx), %ebx
	mov $0x8F, %ah
	mov %bl, %al
	CALL_CUSTOM(smbus_send)
	mov $0x8E, %ah
	mov %bh, %al
	CALL_CUSTOM(smbus_send)
	shr $16, %ebx
	mov $0x8E, %ah
	mov %bl, %al
	CALL_CUSTOM(smbus_send)
	mov $0x8E, %ah
	mov %bh, %al
	CALL_CUSTOM(smbus_send)
	
	//Expected data
	mov %ecx, %ebx //reuse ebx based code (laziness)
	mov $0x8F, %ah
	mov %bl, %al
	CALL_CUSTOM(smbus_send)
	mov $0x8E, %ah
	mov %bh, %al
	CALL_CUSTOM(smbus_send)
	shr $16, %ebx
	mov $0x8E, %ah
	mov %bl, %al
	CALL_CUSTOM(smbus_send)
	mov $0x8E, %ah
	mov %bh, %al
	CALL_CUSTOM(smbus_send)
	
infloop:
	jmp infloop
	
ledcodes:
	.byte 0x00 //xxxx
	.byte 0x10 //rxxx
	.byte 0x31 //roxx
	.byte 0x53 //rgox
	
smbus_send: //Sends ah then al over SMBus
	mov %edx, %esi
	
	xchg %al, %ah //Send the upper byte first
	movw $(SMBUS+8), %dx
	outb %al, %dx //SMBus first byte (al)
	
	xchg %al, %ah //Send lower byte
	movw $(SMBUS+6), %dx
	outb %al, %dx //SMBus second byte (al)
	
	x86code_outb(SMBUS+2, 0x0000000a)
	1:
		// like xcode_inb(SMBUS)
		movw $SMBUS, %dx
		inb %dx, %al
		// like xcode_ifngoto_label(0x00000010, 1b)
		cmp $0x10, %al
		jne 1b
	x86code_outb(SMBUS, 0x00000010)
	
	mov %esi, %edx
	//return
	jmp *%ebp


	// We leave Flash at this point, we never come back to it anymore.
	// the following ASM instructions below, already are linked to memory 
	// (look to the ldscript in this case)

	.section .text, "ax"
                         
	// Note: We are in Memory here, not in Flash anylonger, 
	// we have been copy'd here and linked for memory, as we reside in section .text
	// Look to LDscript
       
	.global	MemoryChecksum
MemoryChecksum:      	
	// The SHA-1 Hashsum is dumped here after with ImageBLD
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.long _size_2bl
	
	.org 0x19  // We have linkbase for this programm = 0x100000 + 0x40 = divisable /4 .. so CPU likes it
tableGdt:

	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 // 0x00 dummy
	.byte 0xff, 0xff, 0x00, 0x00, 0x00, 0x9b, 0xcf, 0x00 // 0x08 code32
	.byte 0xff, 0xff, 0x00, 0x00, 0x00, 0x9b, 0xcf, 0x00 // 0x10 code32
	.byte 0xff, 0xff, 0x00, 0x00, 0x00, 0x93, 0xcf, 0x00 // 0x18 data32
	.byte 0xff, 0xff, 0x00, 0x00, 0x00, 0x9b, 0x8f, 0x00 // 0x20 code16 (8f indicates 4K granularity, ie, huge limit)
	.byte 0xff, 0xff, 0x00, 0x00, 0x00, 0x93, 0x8f, 0x00 // 0x28 data16
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 // Dummy
	
tableGdtDescriptor:

	.word 0x30
	.long tableGdt
	.word 0x0       // fill Word, so we get alliged again

tableIdtDescriptor:

	.word 2048
	.long 0x400000
	.word 0x0	// fill Word, so we get alliged again
		
initaftermemcpy:
	// These Init Codes Can be found in the 2'nd Bootloader

	// We set up a GDT now, this is not necessary needed, 
	// but it is preferred, as we have more ability with commands
        
	// We clear the IDT in RAM
	xor %eax,%eax
    // Below is equivalent to memset(0x400000, 0, 0x5000/4);
	mov $0x5000,%ecx
	mov $0x400000,%edi
	rep stosl
   	
   	//Clear decompressed kernel space.
   	// memset((void*)0x03800000,0x0,0x30000)
#if 0
   	#include "memory_layout.h"
	movl $0x30000, %ecx
	movl $CODE_LOC_START, %edi
	rep stosl
#endif
	// We'll do that one PIC challenge has been resolved.
	// Fix issue for 1.0 strict timing.

	lidt tableIdtDescriptor
	lgdt tableGdtDescriptor
	// set up selectors for everything

	xor	%eax, %eax
	lldt %ax

	// Reload CS as 0010 from the new GDT using a far jump
	.byte 0xEA          // jmp far 0010:reload_cs
	.long reload_cs
	.word 0x0010
	.align 16

reload_cs:

	// CS is now a valid entry in the GDT.  Set SS, DS, and ES to valid
	// descriptors, but clear FS and GS as they are not necessary.

	// Set SS, DS, and ES to a data32 segment with maximum limit.
	movw $0x0018, %ax
	mov %eax, %ss
	mov %eax, %ds
	mov %eax, %es

	// Clear FS and GS
	xor %eax, %eax
	mov %eax, %fs
	mov %eax, %gs
	
	movl	$ 0x1ffff0,%esp

	mov	$0x8, %al
	mov	$0x61, %dx
	out	%al, %dx

	// Enable IDE and NIC
	mov 	$0x8000088C, %eax 
	movw 	$0xcf8, %dx 
	outl	%eax, %dx 
	movw 	$0xcfc, %dx 
	movl 	$0x40000000, %eax 
	outl	%eax, %dx
      	
	// CPU Whoami   ? sesless ?
	mov 	$0x80000080, %eax 
	movw 	$0xcf8, %dx 
	outl	%eax, %dx 
	movw 	$0xcfc, %dx 
	movl 	$0x100, %eax 
	outl	%eax, %dx 
        
	// this can be found in 2bBootStartBios.c
	jmp 	BootStartBiosLoader
