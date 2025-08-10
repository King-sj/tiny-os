#ifndef SPRINTF_H
#define SPRINTF_H

#include "sprintf_asm.h"

// 可变参数支持的基本类型定义
typedef char *va_list;

// va_arg 宏定义 - 用于获取下一个参数
#define va_start(ap, last) (ap = (va_list)(&last + 1))
#define va_arg(ap, type) (*(type*)((ap += sizeof(type)) - sizeof(type)))
#define va_end(ap) (ap = (va_list)0)

// sprintf 相关函数
// 支持的格式说明符：
// %d - 十进制整数
// %u - 无符号十进制整数
// %x - 小写十六进制
// %X - 大写十六进制
// %o - 八进制
// %c - 字符
// %s - 字符串
// %p - 指针地址 (0x前缀)
// %% - 字面量%
int sprintf(char* buffer, const char* format, ...);
// 安全版本：限制缓冲区大小
int snprintf(char* buffer, int size, const char* format, ...);

#endif
