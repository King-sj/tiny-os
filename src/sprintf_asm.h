#ifndef SPRINTF_ASM_H
#define SPRINTF_ASM_H


// 汇编函数声明
int int_to_str(int num, char* buffer, int base);
int str_len(const char* str);
void str_copy(char* dest, const char* src);

#endif
