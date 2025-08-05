; Tiny OS naskfunc
; 汇编函数库，为C语言提供底层接口
; TAB=4

BITS 32

SECTION .text

; 导出函数
GLOBAL io_hlt
GLOBAL io_cli
GLOBAL io_sti
GLOBAL io_out8
GLOBAL io_in8

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

; void io_out8(int port, int data); - 向端口输出8位数据
io_out8:
    MOV     EDX,[ESP+4]     ; 端口
    MOV     AL,[ESP+8]      ; 数据
    OUT     DX,AL
    RET

; int io_in8(int port); - 从端口读取8位数据
io_in8:
    MOV     EDX,[ESP+4]     ; 端口
    MOV     EAX,0
    IN      AL,DX
    RET
