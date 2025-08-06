; Tiny OS naskfunc
; 汇编函数库，为C语言提供底层接口
; TAB=4

BITS 32

SECTION .text

; 导出函数
GLOBAL io_hlt
GLOBAL io_cli
GLOBAL io_sti
GLOBAL io_in8
GLOBAL io_out8
GLOBAL io_in16
GLOBAL io_out16
GLOBAL io_in32
GLOBAL io_out32
GLOBAL io_load_eflags
GLOBAL io_store_eflags

; void io_hlt(void); - CPU休眠
io_hlt:
    HLT
    RET

; void io_cli(void); - 禁用中断
io_cli:
    CLI
    RET

; void io_sti(void); - 启用中断
io_sti:
    STI
    RET

; void io_stihlt(void); - 启用中断并休眠
io_stihlt:
    STI
    HLT
    RET

; int io_in8(int port); - 从端口读取8位数据
io_in8:
    MOV     EDX,[ESP+4]     ; 端口
    MOV     EAX,0
    IN      AL,DX
    RET

; int io_in16(int port); - 从端口读取16位数据
io_in16:
    MOV     EDX,[ESP+4]     ; 端口
    MOV     EAX,0
    IN      AX,DX
    RET

; int io_in32(int port); - 从端口读取32位数据
io_in32:
    MOV     EDX,[ESP+4]     ; 端口
    IN      EAX,DX
    RET

; void io_out8(int port, int data); - 向端口输出8位数据
io_out8:
    MOV     EDX,[ESP+4]     ; 端口
    MOV     AL,[ESP+8]      ; 数据
    OUT     DX,AL
    RET

; void io_out16(int port, int data); - 向端口输出16位数据
io_out16:
    MOV     EDX,[ESP+4]     ; 端口
    MOV     AX,[ESP+8]      ; 数据
    OUT     DX,AX
    RET

; void io_out32(int port, int data); - 向端口输出32位数据
io_out32:
    MOV     EDX,[ESP+4]     ; 端口
    MOV     EAX,[ESP+8]      ; 数据
    OUT     DX,EAX
    RET

; int io_load_eflags(void); - 加载EFLAGS寄存器
io_load_eflags:
    PUSHFD                  ; 压入EFLAGS
    POP     EAX             ; 弹出到EAX
    RET

; void io_store_eflags(int eflags); - 存储EFLAGS寄存器
io_store_eflags:
    MOV     EAX,[ESP+4]     ; 获取EFLAGS值
    PUSH    EAX             ; 压入EFLAGS
    POPFD                   ; 恢复EFLAGS
    RET
