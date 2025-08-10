// 简化的 sprintf 实现
// 支持基本的格式化：%d, %x, %s, %c
#include "sprintf.h"

// 主要的sprintf函数 - 支持可变参数
int sprintf(char* buffer, const char* format, ...) {
    va_list args;
    va_start(args, format);

    char* buf_ptr = buffer;
    const char* fmt_ptr = format;
    int chars_written = 0;

    while (*fmt_ptr) {
        if (*fmt_ptr == '%') {
            fmt_ptr++; // 跳过 %

            if (*fmt_ptr == '\0') {
                break; // 格式字符串结束
            }

            switch (*fmt_ptr) {
                case 'd': {
                    int value = va_arg(args, int);
                    char temp_buf[32];
                    int len = int_to_str(value, temp_buf, 10);
                    str_copy(buf_ptr, temp_buf);
                    buf_ptr += len;
                    chars_written += len;
                    break;
                }

                case 'x': {
                    int value = va_arg(args, int);
                    char temp_buf[32];
                    int len = int_to_str(value, temp_buf, 16);
                    str_copy(buf_ptr, temp_buf);
                    buf_ptr += len;
                    chars_written += len;
                    break;
                }

                case 'X': {
                    int value = va_arg(args, int);
                    char temp_buf[32];
                    int len = int_to_str(value, temp_buf, 16);
                    // 转换为大写
                    for (int i = 0; i < len; i++) {
                        if (temp_buf[i] >= 'a' && temp_buf[i] <= 'f') {
                            temp_buf[i] = temp_buf[i] - 'a' + 'A';
                        }
                    }
                    str_copy(buf_ptr, temp_buf);
                    buf_ptr += len;
                    chars_written += len;
                    break;
                }

                case 's': {
                    const char* str_value = va_arg(args, const char*);
                    if (str_value) {
                        int len = str_len(str_value);
                        str_copy(buf_ptr, str_value);
                        buf_ptr += len;
                        chars_written += len;
                    }
                    break;
                }

                case 'c': {
                    int char_value = va_arg(args, int); // char 被提升为 int
                    *buf_ptr = (char)char_value;
                    buf_ptr++;
                    chars_written++;
                    break;
                }

                case 'o': {
                    int value = va_arg(args, int);
                    char temp_buf[32];
                    int len = int_to_str(value, temp_buf, 8);
                    str_copy(buf_ptr, temp_buf);
                    buf_ptr += len;
                    chars_written += len;
                    break;
                }

                case 'u': {
                    unsigned int value = va_arg(args, unsigned int);
                    char temp_buf[32];
                    int len = int_to_str((int)value, temp_buf, 10);
                    str_copy(buf_ptr, temp_buf);
                    buf_ptr += len;
                    chars_written += len;
                    break;
                }

                case 'p': {
                    void* ptr = va_arg(args, void*);
                    char temp_buf[32];
                    temp_buf[0] = '0';
                    temp_buf[1] = 'x';
                    // 将指针转换为unsigned long再转int，在32位系统中是安全的
                    unsigned long ptr_val = (unsigned long)ptr;
                    int len = int_to_str((int)ptr_val, temp_buf + 2, 16) + 2;
                    str_copy(buf_ptr, temp_buf);
                    buf_ptr += len;
                    chars_written += len;
                    break;
                }

                case '%': {
                    *buf_ptr = '%';
                    buf_ptr++;
                    chars_written++;
                    break;
                }

                default: {
                    // 不支持的格式，输出原字符
                    *buf_ptr = '%';
                    buf_ptr++;
                    chars_written++;
                    *buf_ptr = *fmt_ptr;
                    buf_ptr++;
                    chars_written++;
                    break;
                }
            }
            fmt_ptr++;
        } else {
            *buf_ptr = *fmt_ptr;
            buf_ptr++;
            chars_written++;
            fmt_ptr++;
        }
    }

    *buf_ptr = '\0'; // 字符串结束符
    va_end(args);

    return chars_written;
}

// 安全版本的sprintf，限制输出缓冲区大小
int snprintf(char* buffer, int size, const char* format, ...) {
    if (size <= 0 || !buffer) {
        return -1; // 无效参数
    }

    va_list args;
    va_start(args, format);

    char* buf_ptr = buffer;
    const char* fmt_ptr = format;
    int chars_written = 0;
    int remaining = size - 1; // 为结束符预留空间

    while (*fmt_ptr && remaining > 0) {
        if (*fmt_ptr == '%') {
            fmt_ptr++; // 跳过 %

            if (*fmt_ptr == '\0') {
                break; // 格式字符串结束
            }

            switch (*fmt_ptr) {
                case 'd': {
                    int value = va_arg(args, int);
                    char temp_buf[32];
                    int len = int_to_str(value, temp_buf, 10);
                    if (len > remaining) len = remaining;
                    for (int i = 0; i < len; i++) {
                        *buf_ptr++ = temp_buf[i];
                    }
                    chars_written += len;
                    remaining -= len;
                    break;
                }

                case 'x': {
                    int value = va_arg(args, int);
                    char temp_buf[32];
                    int len = int_to_str(value, temp_buf, 16);
                    if (len > remaining) len = remaining;
                    for (int i = 0; i < len; i++) {
                        *buf_ptr++ = temp_buf[i];
                    }
                    chars_written += len;
                    remaining -= len;
                    break;
                }

                case 'X': {
                    int value = va_arg(args, int);
                    char temp_buf[32];
                    int len = int_to_str(value, temp_buf, 16);
                    if (len > remaining) len = remaining;
                    // 转换为大写并复制
                    for (int i = 0; i < len; i++) {
                        char c = temp_buf[i];
                        if (c >= 'a' && c <= 'f') {
                            c = c - 'a' + 'A';
                        }
                        *buf_ptr++ = c;
                    }
                    chars_written += len;
                    remaining -= len;
                    break;
                }

                case 'o': {
                    int value = va_arg(args, int);
                    char temp_buf[32];
                    int len = int_to_str(value, temp_buf, 8);
                    if (len > remaining) len = remaining;
                    for (int i = 0; i < len; i++) {
                        *buf_ptr++ = temp_buf[i];
                    }
                    chars_written += len;
                    remaining -= len;
                    break;
                }

                case 'u': {
                    unsigned int value = va_arg(args, unsigned int);
                    char temp_buf[32];
                    int len = int_to_str((int)value, temp_buf, 10);
                    if (len > remaining) len = remaining;
                    for (int i = 0; i < len; i++) {
                        *buf_ptr++ = temp_buf[i];
                    }
                    chars_written += len;
                    remaining -= len;
                    break;
                }

                case 's': {
                    const char* str_value = va_arg(args, const char*);
                    if (str_value) {
                        while (*str_value && remaining > 0) {
                            *buf_ptr++ = *str_value++;
                            chars_written++;
                            remaining--;
                        }
                    }
                    break;
                }

                case 'c': {
                    if (remaining > 0) {
                        int char_value = va_arg(args, int);
                        *buf_ptr++ = (char)char_value;
                        chars_written++;
                        remaining--;
                    } else {
                        va_arg(args, int); // 消费参数但不使用
                    }
                    break;
                }

                case 'p': {
                    void* ptr = va_arg(args, void*);
                    if (remaining >= 2) {
                        *buf_ptr++ = '0';
                        *buf_ptr++ = 'x';
                        chars_written += 2;
                        remaining -= 2;

                        char temp_buf[32];
                        unsigned long ptr_val = (unsigned long)ptr;
                        int len = int_to_str((int)ptr_val, temp_buf, 16);
                        if (len > remaining) len = remaining;
                        for (int i = 0; i < len; i++) {
                            *buf_ptr++ = temp_buf[i];
                        }
                        chars_written += len;
                        remaining -= len;
                    }
                    break;
                }

                case '%': {
                    if (remaining > 0) {
                        *buf_ptr++ = '%';
                        chars_written++;
                        remaining--;
                    }
                    break;
                }

                default: {
                    // 不支持的格式，输出原字符
                    if (remaining >= 2) {
                        *buf_ptr++ = '%';
                        *buf_ptr++ = *fmt_ptr;
                        chars_written += 2;
                        remaining -= 2;
                    }
                    break;
                }
            }
            fmt_ptr++;
        } else {
            *buf_ptr++ = *fmt_ptr++;
            chars_written++;
            remaining--;
        }
    }

    *buf_ptr = '\0'; // 字符串结束符
    va_end(args);

    return chars_written;
}

