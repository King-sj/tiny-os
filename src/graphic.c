// #include "bootpack.h"
#include "naskfunc.h"
#include "graphic.h"
// 初始化调色板
void init_palette(void){
    static unsigned char table_rgb[16 * 3] = {
        0x00, 0x00, 0x00,	/*  0:黑 */
        0xff, 0x00, 0x00,	/*  1:梁红 */
        0x00, 0xff, 0x00,	/*  2:亮绿 */
        0xff, 0xff, 0x00,	/*  3:亮黄 */
        0x00, 0x00, 0xff,	/*  4:亮蓝 */
        0xff, 0x00, 0xff,	/*  5:亮紫 */
        0x00, 0xff, 0xff,	/*  6:浅亮蓝 */
        0xff, 0xff, 0xff,	/*  7:白 */
        0xc6, 0xc6, 0xc6,	/*  8:亮灰 */
        0x84, 0x00, 0x00,	/*  9:暗红 */
        0x00, 0x84, 0x00,	/* 10:暗绿 */
        0x84, 0x84, 0x00,	/* 11:暗黄 */
        0x00, 0x00, 0x84,	/* 12:暗青 */
        0x84, 0x00, 0x84,	/* 13:暗紫 */
        0x00, 0x84, 0x84,	/* 14:浅暗蓝 */
        0x84, 0x84, 0x84	/* 15:暗灰 */
    };
    set_palette(0, 15, table_rgb);
    return;
}

void set_palette(int start, int end, unsigned char *rgb){
    int i, eflags;
    eflags = io_load_eflags();	/* 记录中断许可标志的值 */
    io_cli(); 					/* 将中断许可标志置为0,禁止中断 */
    io_out8(0x03c8, start);
    for (i = start; i <= end; i++) {
        io_out8(0x03c9, rgb[0] / 4);
        io_out8(0x03c9, rgb[1] / 4);
        io_out8(0x03c9, rgb[2] / 4);
        rgb += 3;
    }
    io_store_eflags(eflags);	/* 复原中断许可标志 */
    return;
}

void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1)
{
    int x, y;
    for (y = y0; y <= y1; y++) {
        for (x = x0; x <= x1; x++)
            vram[y * xsize + x] = c;
    }
    return;
}

// 初始化屏幕
void init_screen(char *vram, int x, int y)
{
	boxfill8((unsigned char*)vram, x, COL8_008484,  0,     0,      x -  1, y - 29);
	boxfill8((unsigned char*)vram, x, COL8_C6C6C6,  0,     y - 28, x -  1, y - 28);
	boxfill8((unsigned char*)vram, x, COL8_FFFFFF,  0,     y - 27, x -  1, y - 27);
	boxfill8((unsigned char*)vram, x, COL8_C6C6C6,  0,     y - 26, x -  1, y -  1);

	boxfill8((unsigned char*)vram, x, COL8_FFFFFF,  3,     y - 24, 59,     y - 24);
	boxfill8((unsigned char*)vram, x, COL8_FFFFFF,  2,     y - 24,  2,     y -  4);
	boxfill8((unsigned char*)vram, x, COL8_848484,  3,     y -  4, 59,     y -  4);
	boxfill8((unsigned char*)vram, x, COL8_848484, 59,     y - 23, 59,     y -  5);
	boxfill8((unsigned char*)vram, x, COL8_000000,  2,     y -  3, 59,     y -  3);
	boxfill8((unsigned char*)vram, x, COL8_000000, 60,     y - 24, 60,     y -  3);

	boxfill8((unsigned char*)vram, x, COL8_848484, x - 47, y - 24, x -  4, y - 24);
	boxfill8((unsigned char*)vram, x, COL8_848484, x - 47, y - 23, x - 47, y -  4);
	boxfill8((unsigned char*)vram, x, COL8_FFFFFF, x - 47, y -  3, x -  4, y -  3);
	boxfill8((unsigned char*)vram, x, COL8_FFFFFF, x -  3, y - 24, x -  3, y -  3);
	return;
}
// 在屏幕上绘制一个字符 - 添加边界检查
void putfont8(unsigned char *vram, int xsize, int x, int y, char c, const unsigned char *font) {
    // 边界检查：确保字体完全在屏幕范围内
    if (x < 0 || y < 0 || x + 8 > xsize || y + 16 > 200) {
        return; // 超出边界则不绘制
    }
    for (int i = 0; i < 16; i++) {  // 遍历字体的16行
        unsigned char *p = vram + (y + i) * xsize + x;
        unsigned char d = font[i];
        // 最高位对应最左边的像素
        for (int j = 0; j < 8; j++) {  // 遍历字体的8列
            //例如 d = 0x18 = 0b00011000
            //bit 7 (最高位) 对应 j=0 (最左边像素)
            //bit 0 (最低位) 对应 j=7 (最右边像素)
            if ((d >> (7-j)) & 1) {
                p[j] = c;
            }
        }
    }
    return;
}

// 字符串显示函数
void putfonts8_asc(unsigned char *vram, int xsize, int x, int y, char c, unsigned char *s) {
    for (; *s != 0x00; s++) {
        putfont8(vram, xsize, x, y, c, __font + *s * 16);
        x += 8;
    }
    return;
}

// 鼠标指针初始化
void init_mouse_cursor8(char *mouse, char bc) {
static char cursor[16][16] = {
		"**************..",
		"*OOOOOOOOOOO*...",
		"*OOOOOOOOOO*....",
		"*OOOOOOOOO*.....",
		"*OOOOOOOO*......",
		"*OOOOOOO*.......",
		"*OOOOOOO*.......",
		"*OOOOOOOO*......",
		"*OOOO**OOO*.....",
		"*OOO*..*OOO*....",
		"*OO*....*OOO*...",
		"*O*......*OOO*..",
		"**........*OOO*.",
		"*..........*OOO*",
		"............*OO*",
		".............***"
	};
	int x, y;

	for (y = 0; y < 16; y++) {
		for (x = 0; x < 16; x++) {
			if (cursor[y][x] == '*') {
				mouse[y * 16 + x] = COL8_000000;
			}
			if (cursor[y][x] == 'O') {
				mouse[y * 16 + x] = COL8_FFFFFF;
			}
			if (cursor[y][x] == '.') {
				mouse[y * 16 + x] = bc;
			}
		}
	}
	return;
}

// 绘制块图像
void putblock8_8(char *vram, int vxsize, int pxsize, int pysize, int px0, int py0, char *buf, int bxsize) {
    int x, y;
    for (y = 0; y < pysize; y++) {
        for (x = 0; x < pxsize; x++) {
            vram[(py0 + y) * vxsize + (px0 + x)] = buf[y * bxsize + x];
        }
    }
}
