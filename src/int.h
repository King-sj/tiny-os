/**
 * 中断相关函数声明
 */
#ifndef INT_H
#define INT_H
#include "graphic.h"
#include "naskfunc.h"
#include "asmhead.h"


#define PIC0_ICW1		0x0020
#define PIC0_OCW2		0x0020
// Interrupt mask register
#define PIC0_IMR		0x0021
// initial control world
#define PIC0_ICW2		0x0021
#define PIC0_ICW3		0x0021
#define PIC0_ICW4		0x0021
#define PIC1_ICW1		0x00a0
#define PIC1_OCW2		0x00a0
#define PIC1_IMR		0x00a1
#define PIC1_ICW2		0x00a1
#define PIC1_ICW3		0x00a1
#define PIC1_ICW4		0x00a1

// PIC初始化
void init_pic(void);

// TODO: RENAME
// 中断处理函数, 来自PS/2键盘的中断
void inthandler21(int *esp);
/* 来自PS/2鼠标的中断 */
void inthandler2c(int *esp);
/* PIC0中断的不完整策略 */
void inthandler27(int *esp);
#endif // INT_H