; sprintf 相关的汇编辅助函数
; TAB=4

BITS 32

SECTION .text

; 导出函数
GLOBAL int_to_str
GLOBAL str_len
GLOBAL str_copy

; int int_to_str(int num, char* buffer, int base); - 整数转字符串
; 返回字符串长度
int_to_str:
    PUSH    EBP
    MOV     EBP,ESP
    PUSH    EBX
    PUSH    ECX
    PUSH    EDX
    PUSH    ESI
    PUSH    EDI

    MOV     EAX,[EBP+8]     ; 数字
    MOV     EDI,[EBP+12]    ; 缓冲区
    MOV     EBX,[EBP+16]    ; 进制

    MOV     ECX,0           ; 字符计数
    MOV     ESI,EDI         ; 保存缓冲区起始位置

    ; 处理负数
    CMP     EAX,0
    JGE     positive
    NEG     EAX
    MOV     BYTE [EDI],'-'
    INC     EDI
    INC     ECX

positive:
    ; 如果数字为0
    CMP     EAX,0
    JNE     convert_loop
    MOV     BYTE [EDI],'0'
    INC     EDI
    INC     ECX
    JMP     end_convert

convert_loop:
    CMP     EAX,0
    JE      reverse_string

    XOR     EDX,EDX
    DIV     EBX             ; EAX = EAX/EBX, EDX = EAX%EBX

    ; 转换余数为字符
    CMP     EDX,9
    JLE     digit
    ADD     EDX,'A'-10      ; A-F for hex
    JMP     store_char
digit:
    ADD     EDX,'0'         ; 0-9

store_char:
    MOV     [EDI],DL
    INC     EDI
    INC     ECX
    JMP     convert_loop

reverse_string:
    ; 反转数字部分（不包括负号）
    MOV     EBX,ESI
    CMP     BYTE [EBX],'-'
    JNE     reverse_start
    INC     EBX             ; 跳过负号

reverse_start:
    DEC     EDI             ; EDI指向最后一个字符

reverse_loop:
    CMP     EBX,EDI
    JGE     end_convert

    ; 交换字符
    MOV     AL,[EBX]
    MOV     DL,[EDI]
    MOV     [EBX],DL
    MOV     [EDI],AL

    INC     EBX
    DEC     EDI
    JMP     reverse_loop

end_convert:
    MOV     BYTE [ESI+ECX],0  ; 添加字符串结束符
    MOV     EAX,ECX           ; 返回长度

    POP     EDI
    POP     ESI
    POP     EDX
    POP     ECX
    POP     EBX
    POP     EBP
    RET

; int str_len(const char* str); - 计算字符串长度
str_len:
    MOV     EDX,[ESP+4]     ; 字符串指针
    MOV     EAX,0           ; 长度计数

len_loop:
    CMP     BYTE [EDX+EAX],0
    JE      len_done
    INC     EAX
    JMP     len_loop

len_done:
    RET

; void str_copy(char* dest, const char* src); - 复制字符串
str_copy:
    MOV     EDI,[ESP+4]     ; 目标
    MOV     ESI,[ESP+8]     ; 源

copy_loop:
    MOV     AL,[ESI]
    MOV     [EDI],AL
    CMP     AL,0
    JE      copy_done
    INC     ESI
    INC     EDI
    JMP     copy_loop

copy_done:
    RET
