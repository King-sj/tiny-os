// 简化的 sprintf 实现
// 支持基本的格式化：%d, %x, %s, %c

// 汇编函数声明
int int_to_str(int num, char* buffer, int base);
int str_len(const char* str);
void str_copy(char* dest, const char* src);

// 更简单和安全的 sprintf 实现，避免可变参数的复杂性
void tiny_sprintf_d(char* buffer, const char* format, int value) {
    char* buf_ptr = buffer;
    const char* fmt_ptr = format;

    while (*fmt_ptr) {
        if (*fmt_ptr == '%' && *(fmt_ptr + 1) == 'd') {
            char temp_buf[32];
            int len = int_to_str(value, temp_buf, 10);
            str_copy(buf_ptr, temp_buf);
            buf_ptr += len;
            fmt_ptr += 2;  // 跳过 %d
        } else {
            *buf_ptr = *fmt_ptr;
            buf_ptr++;
            fmt_ptr++;
        }
    }
    *buf_ptr = '\0';
}

void tiny_sprintf_x(char* buffer, const char* format, int value) {
    char* buf_ptr = buffer;
    const char* fmt_ptr = format;

    while (*fmt_ptr) {
        if (*fmt_ptr == '%' && *(fmt_ptr + 1) == 'x') {
            char temp_buf[32];
            int len = int_to_str(value, temp_buf, 16);
            str_copy(buf_ptr, temp_buf);
            buf_ptr += len;
            fmt_ptr += 2;  // 跳过 %x
        } else {
            *buf_ptr = *fmt_ptr;
            buf_ptr++;
            fmt_ptr++;
        }
    }
    *buf_ptr = '\0';
}

void tiny_sprintf_s(char* buffer, const char* format, const char* str_value) {
    char* buf_ptr = buffer;
    const char* fmt_ptr = format;

    while (*fmt_ptr) {
        if (*fmt_ptr == '%' && *(fmt_ptr + 1) == 's') {
            if (str_value) {
                int len = str_len(str_value);
                str_copy(buf_ptr, str_value);
                buf_ptr += len;
            }
            fmt_ptr += 2;  // 跳过 %s
        } else {
            *buf_ptr = *fmt_ptr;
            buf_ptr++;
            fmt_ptr++;
        }
    }
    *buf_ptr = '\0';
}

// 更简单的版本，只支持字符串拼接
void simple_sprintf(char* buffer, const char* format, int num) {
    const char* fmt = format;
    char* buf = buffer;

    // 简单实现：查找 %d 并替换为数字
    while (*fmt) {
        if (*fmt == '%' && *(fmt + 1) == 'd') {
            // 转换数字
            char temp[16];
            int len = int_to_str(num, temp, 10);
            str_copy(buf, temp);
            buf += len;
            fmt += 2;  // 跳过 %d
        } else {
            *buf = *fmt;
            buf++;
            fmt++;
        }
    }
    *buf = '\0';
}
