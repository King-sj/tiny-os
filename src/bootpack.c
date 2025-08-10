/* 汇编入口点 - 必须在最前面 */
__asm__(
    ".global _start\n"
    ".global bootpack\n"
    "_start:\n"
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
// 毫秒级睡眠
void sleep_ms(int milliseconds);
// 加载全局描述符表寄存器
void load_gdtr(int limit, int addr);
// 加载中断描述符表寄存器
void load_idtr(int limit, int addr);
// sprintf 相关函数
void tiny_sprintf_d(char* buffer, const char* format, int value);
void tiny_sprintf_x(char* buffer, const char* format, int value);
void tiny_sprintf_s(char* buffer, const char* format, const char* str_value);

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

/* 段描述符 */
struct SEGMENT_DESCRIPTOR {
	short limit_low, base_low;
	char base_mid, access_right;
	char limit_high, base_high;
};

/* 中断门描述符 */
struct GATE_DESCRIPTOR {
	short offset_low, selector;
	char dw_count, access_right;
	short offset_high;
};
// 函数声明
void init_palette(void);
void init_gdtidt(void);
void set_segmdesc(struct SEGMENT_DESCRIPTOR *sd, unsigned int limit, int base, int ar);
void set_gatedesc(struct GATE_DESCRIPTOR *gd, int offset, int selector, int ar);
void set_palette(int start, int end, unsigned char *rgb);
void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1);
void init_screen(char *vram, int x, int y);
void putfont8(unsigned char *vram, int xsize, int x, int y, char c, const unsigned char *font);
void putfonts8_asc(unsigned char *vram, int xsize, int x, int y, char c, unsigned char *s);
void init_mouse_cursor8(char *mouse, char bc);
void putblock8_8(char *vram, int vxsize, int pxsize, int pysize, int px0, int py0, char *buf, int bxsize);
/* C代码主函数 */
extern const char __font[16 * 256]; // 声明全局字体数组
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

// 初始化全局描述符表和中断描述符表
void init_gdtidt(void) {
    // TODO: 去除magic number
    struct SEGMENT_DESCRIPTOR *gdt = (struct SEGMENT_DESCRIPTOR *) 0x00270000;
	struct GATE_DESCRIPTOR    *idt = (struct GATE_DESCRIPTOR    *) 0x0026f800;
    for (int i = 0; i < 8192; i++) {
        set_segmdesc(gdt + i, 0, 0, 0); // 清空GDT
    }
    set_segmdesc(gdt + 1, 0xffffffff, 0x00000000, 0x4092); // 设置代码段
    set_segmdesc(gdt + 2, 0x0007ffff, 0x00280000, 0x409a); // 设置数据段
    load_gdtr(0xffff, 0x00270000); // 加载GDT
    // 初始化IDT
    for (int i = 0; i < 256; i++) {
        set_gatedesc(idt + i, 0, 0, 0);
    }
    load_idtr(0x7ff, 0x0026f800); // 加载IDT
}

// 设置段描述符
void set_segmdesc(struct SEGMENT_DESCRIPTOR *sd, unsigned int limit, int base, int ar) {
	if (limit > 0xfffff) {
		ar |= 0x8000; /* G_bit = 1 */
		limit /= 0x1000;
	}
	sd->limit_low = limit & 0xffff;
	sd->base_low = base & 0xffff;
	sd->base_mid = (base >> 16) & 0xff;
	sd->access_right = ar & 0xff;
	sd->limit_high = (limit >> 16) & 0x0f;
	sd->base_high = (base >> 24) & 0xff;
}

// 设置中断门描述符
void set_gatedesc(struct GATE_DESCRIPTOR *gd, int offset, int selector, int ar) {
	gd->offset_low   = offset & 0xffff;
	gd->selector     = selector;
	gd->dw_count     = (ar >> 8) & 0xff;
	gd->access_right = ar & 0xff;
	gd->offset_high  = (offset >> 16) & 0xffff;
	return;
}
