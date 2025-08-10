#ifndef NASKFUNC_H
#define NASKFUNC_H

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

#endif