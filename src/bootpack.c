/* 汇编入口点 - 必须在最前面 */
__asm__(
    ".global _start\n"
    ".global bootpack\n"
    "_start:\n"
    "bootpack:\n"
    "    call HariMain\n"
    "    ret\n"
);
#include "bootpack.h"

void HariMain(void)
{
    struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
    char mcursor[256];
    char s[40];
    int mx,my;
    init_gdtidt();   // 初始化全局描述符表和中断描述符表
    init_pic();      // 初始化中断控制器
    io_sti();        /* IDT/PIC的初始化已经完成，于是开放CPU的中断 */

    init_palette();  /* 设定调色板 */
    init_screen(binfo->vram, binfo->scrnx, binfo->scrny);
    init_mouse_cursor8(mcursor, COL8_008484);

    // 显示系统信息
    init_screen(binfo->vram, binfo->scrnx, binfo->scrny);  // clear screen
    sprintf(s, "SCREEN WIDTH: %d", binfo->scrnx);
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, (unsigned char*)s);

    sprintf(s, "SCREEN HEIGHT: %d", binfo->scrny);
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 16, COL8_FFFFFF, (unsigned char*)s);

    sprintf(s, "CYLINDERS: %d", binfo->cyls);
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 32, COL8_FFFFFF, (unsigned char*)s);

    // 测试新的sprintf功能
    sprintf(s, "TEST: %d + %d = %d", 10, 20, 30);
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 48, COL8_FFFFFF, (unsigned char*)s);

    sprintf(s, "HEX: 0x%x, UPPER: 0x%X", 255, 255);
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 64, COL8_FFFFFF, (unsigned char*)s);

    sprintf(s, "CHAR: %c, STRING: %s", 'A', "Hello");
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 80, COL8_FFFFFF, (unsigned char*)s);

    // 测试新增功能
    sprintf(s, "OCT: %o, UNSIGNED: %u", 64, 4294967295U);
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 96, COL8_FFFFFF, (unsigned char*)s);

    sprintf(s, "PTR: %p, PERCENT: 100%%", (void*)0x280000);
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 112, COL8_FFFFFF, (unsigned char*)s);

    // sleep_ms(10000);
    init_screen(binfo->vram, binfo->scrnx, binfo->scrny);  // clear screen
    /* 显示鼠标 */
	mx = (binfo->scrnx - 16) / 2; /* 计算画面的中心坐标*/
	my = (binfo->scrny - 28 - 16) / 2;
    putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);
    sprintf(s, "(%d, %d)", mx, my);
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 128, COL8_FFFFFF, (unsigned char*)s);

    io_out8(PIC0_IMR, 0xf9); /* 开放PIC1和键盘中断(11111001) */
	io_out8(PIC1_IMR, 0xef); /* 开放鼠标中断(11101111) */

    // 成功！进入无限循环，防止返回到汇编代码
    while(1) {
        io_hlt();  // CPU休眠，节省电力
        init_screen(binfo->vram, binfo->scrnx, binfo->scrny);  // clear screen
        sprintf(s, "%s", "Hello");
        putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 80, COL8_FFFFFF, (unsigned char*)s);
    }
}
