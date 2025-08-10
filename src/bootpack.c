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
    struct BOOTINFO *binfo = (struct BOOTINFO *) 0x0ff0;
    char mcursor[256];
    char s[40];
    init_gdtidt(); // 初始化全局描述符表和中断描述符表
    init_palette(); /* 设定调色板 */
    init_screen(binfo->vram, binfo->scrnx, binfo->scrny);
    init_mouse_cursor8(mcursor, COL8_008484);

    // 显示系统信息
    init_screen(binfo->vram, binfo->scrnx, binfo->scrny);  // clear screen
    tiny_sprintf_d(s, "SCREEN WIDTH: %d", binfo->scrnx);
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 80, COL8_FFFFFF, (unsigned char*)s);

    tiny_sprintf_d(s, "SCREEN HEIGHT: %d", binfo->scrny);
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 96, COL8_FFFFFF, (unsigned char*)s);

    tiny_sprintf_d(s, "CYLINDERS: %d", binfo->cyls);
    putfonts8_asc((unsigned char*)binfo->vram, binfo->scrnx, 0, 112, COL8_FFFFFF, (unsigned char*)s);
    sleep_ms(1000);
    init_screen(binfo->vram, binfo->scrnx, binfo->scrny);  // clear screen
    /* 显示鼠标 */
	int mx = (binfo->scrnx - 16) / 2; /* 计算画面的中心坐标*/
	int my = (binfo->scrny - 28 - 16) / 2;
    putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);
    // 成功！进入无限循环，防止返回到汇编代码
    while(1) {
        io_hlt();  // CPU休眠，节省电力
    }
}
