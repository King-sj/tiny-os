#ifndef __ASMHEAD_H__
#define __ASMHEAD_H__
/* 引导信息结构体 */
struct BOOTINFO {
    char cyls, leds, vmode, reserve;
    short scrnx, scrny;
    char *vram;
};
#define ADR_BOOTINFO	0x00000ff0

#endif