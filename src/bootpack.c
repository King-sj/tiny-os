/* 告诉C编译器，有一个函数在别的文件里 */

void io_hlt(void);

/* 汇编入口点 - 必须在最前面 */
__asm__(
    ".global bootpack\n"
    "bootpack:\n"
    "    call HariMain\n"
    "    ret\n"
);

/* C代码主函数 */
void HariMain(void)
{
    char *vram = (char *) 0xa0000;  // 直接初始化
    int i, x, y;

    // 证明C代码运行：画独特的图案
    // 在第6-8行画黄色条纹（只有C代码会画这个图案）
    char *yellow_start = vram + 320 * 5;
    for (i = 0; i < 320 * 3; i++) {
        yellow_start[i] = 14;     // 黄色条纹，连续3行
    }

    // 在第12-14行画青色条纹（颜色值11）
    char *cyan_start = vram + 320 * 11;
    for (i = 0; i < 320 * 3; i++) {
        cyan_start[i] = 11;    // 青色条纹
    }

    // 在屏幕中间画一个大的品红色方块（颜色值13）
    for (y = 90; y < 110; y++) {
        char *line = vram + y * 320;
        for (x = 135; x < 185; x++) {
            line[x] = 13;  // 品红色方块
        }
    }

    // 在底部画C代码特有的标记：交替的红蓝条纹
    for (i = 0; i < 10; i++) {
        char color = (i % 2) ? 12 : 1;  // 交替红蓝
        char *line = vram + (180 + i) * 320;
        for (x = 0; x < 320; x++) {
            line[x] = color;
        }
    }

    // 成功！进入无限循环，防止返回到汇编代码
    while(1) {
        io_hlt();  // CPU休眠，节省电力
    }
}