
/* 汇编入口点 - 必须在最前面 */
__asm__(
    ".global bootpack\n"
    "bootpack:\n"
    "    call HariMain\n"
    "    ret\n"
);

// ---- 汇编函数声明 ----
// 执行 HLT 指令, 使CPU进入休眠状态
void io_hlt(void);
// 禁用中断
void io_cli(void);
// 启用中断
void io_sti(void);
// 启用中断并休眠
void io_stihlt(void);
// 从端口读取8位数据
int io_in8(int port);
// 从端口读取16位数据
int io_in16(int port);
// 从端口读取32位数据
int io_in32(int port);
// 向端口输出8位数据
void io_out8(int port, int data);
// 向端口输出16位数据
void io_out16(int port, int data);
// 向端口输出32位数据
void io_out32(int port, int data);
// 读取中断标志寄存器的值
int io_load_eflags(void);
// 设置中断标志寄存器的值
void io_store_eflags(int eflags);

// 设置调色板
#define COL8_000000		0
#define COL8_FF0000		1
#define COL8_00FF00		2
#define COL8_FFFF00		3
#define COL8_0000FF		4
#define COL8_FF00FF		5
#define COL8_00FFFF		6
#define COL8_FFFFFF		7
#define COL8_C6C6C6		8
#define COL8_840000		9
#define COL8_008400		10
#define COL8_848400		11
#define COL8_000084		12
#define COL8_840084		13
#define COL8_008484		14
#define COL8_848484		15

/* 引导信息结构体 */
struct BOOTINFO {
    char cyls, leds, vmode, reserve;
    short scrnx, scrny;
    char *vram;
};
// 函数声明
void init_palette(void);
void set_palette(int start, int end, unsigned char *rgb);
void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1);
void init_screen(char *vram, int x, int y);
void putfont8(unsigned char *vram, int xsize, int x, int y, char c, unsigned char *font);

/* C代码主函数 */
void HariMain(void)
{
    struct BOOTINFO *binfo = (struct BOOTINFO *) 0x0ff0;

    // 先使用默认调色板
    // init_palette(); /* 设定调色板 */

    // 正确的字体A的位图数据（8x16像素）
    static unsigned char font_A[16] = {
        0x00, 0x18, 0x18, 0x18, 0x24, 0x24, 0x42, 0x7e,
        0x42, 0x42, 0x42, 0x42, 0x42, 0xe7, 0x00, 0x00
    };

    // 暂时不直接访问显存，先确保基础功能正常
    init_screen(binfo->vram, binfo->scrnx, binfo->scrny);
    putfont8((unsigned char*)binfo->vram, binfo->scrnx, 8, 8, COL8_848484, font_A);

    // 成功！进入无限循环，防止返回到汇编代码
    while(1) {
        io_hlt();  // CPU休眠，节省电力
    }
}
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
void putfont8(unsigned char *vram, int xsize, int x, int y, char c, unsigned char *font) {
    int i, j;
    unsigned char *p;
    unsigned char d; /* data */

    // 边界检查：确保字体完全在屏幕范围内
    if (x < 0 || y < 0 || x + 8 > xsize || y + 16 > 200) {
        return; // 超出边界则不绘制
    }

    for (i = 0; i < 16; i++) {
        p = vram + (y + i) * xsize + x;
        d = font[i];

        // 逐位检查并绘制，更加安全
        for (j = 0; j < 8; j++) {
            if ((d & (0x80 >> j)) != 0) {
                p[j] = c;
            }
        }
    }
    return;
}