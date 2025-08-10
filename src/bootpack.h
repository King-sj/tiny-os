#ifndef __BOOTPACK_H__
#define __BOOTPACK_H__

#include "naskfunc.h"
#include "graphic.h"
#include "dsctbl.h"

/* 引导信息结构体 */
struct BOOTINFO {
    char cyls, leds, vmode, reserve;
    short scrnx, scrny;
    char *vram;
};

#endif