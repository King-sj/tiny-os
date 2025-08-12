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
GLOBAL sleep_ms
GLOBAL load_gdtr
GLOBAL load_idtr
GLOBAL asm_inthandler21, asm_inthandler27, asm_inthandler2c
EXTERN inthandler21, inthandler27, inthandler2c

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

; void sleep_ms(int milliseconds); - 毫秒级睡眠（简单忙等待实现）
sleep_ms:
    MOV     ECX,[ESP+4]     ; 获取毫秒数
    CMP     ECX,0
    JLE     sleep_done      ; 如果<=0则直接返回

    ; 简单的循环计数实现（需要根据CPU频率调整）
    ; 这里假设1ms大约需要循环1000000次（需要校准）
    IMUL    ECX,1000000     ; 每毫秒循环次数

; 忙等待循环
sleep_loop:
    DEC     ECX
    JNZ     sleep_loop

; 完成睡眠
sleep_done:
    RET

; void load_gdtr(int limit, int addr); - 加载全局描述符表寄存器
load_gdtr:
    MOV     AX,[ESP+4]      ; 获取limit
    MOV     EDX,[ESP+8]     ; 获取addr
    LGDT    [EDX]           ; 加载GDT
    RET

; void load_idtr(int limit, int addr); - 加载中断描述符表寄存器
load_idtr:
		MOV		AX,[ESP+4]		; limit
		MOV		[ESP+6],AX
		LIDT	[ESP+6]
		RET


; 中断处理函数
; 这些函数由C语言调用，处理特定的中断
asm_inthandler21:
		PUSH	ES
		PUSH	DS
		PUSHAD
		MOV		EAX,ESP
		PUSH	EAX
		MOV		AX,SS
		MOV		DS,AX
		MOV		ES,AX
		CALL	inthandler21
		POP		EAX
		POPAD
		POP		DS
		POP		ES
		IRET

; 中断处理函数21
asm_inthandler27:
		PUSH	ES
		PUSH	DS
		PUSHAD
		MOV		EAX,ESP
		PUSH	EAX
		MOV		AX,SS
		MOV		DS,AX
		MOV		ES,AX
		CALL	inthandler27
		POP		EAX
		POPAD
		POP		DS
		POP		ES
		IRETD
; 中断处理函数2c
asm_inthandler2c:
		PUSH	ES
		PUSH	DS
		PUSHAD
		MOV		EAX,ESP
		PUSH	EAX
		MOV		AX,SS
		MOV		DS,AX
		MOV		ES,AX
		CALL	inthandler2c
		POP		EAX
		POPAD
		POP		DS
		POP		ES
		IRETD
