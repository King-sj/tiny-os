; 启动汇编代码
; TAB=4

BOTPAK	EQU		0x00280000		; 加载bootpack
DSKCAC	EQU		0x00100000		; 磁盘缓存的位置
DSKCAC0	EQU		0x00008000		; 磁盘缓存的位置（实模式）

; BOOT_INFO相关
CYLS	EQU		0x0ff0			; 引导扇区设置
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; 关于颜色的信息
SCRNX	EQU		0x0ff4			; 分辨率X
SCRNY	EQU		0x0ff6			; 分辨率Y
VRAM	EQU		0x0ff8			; 图像缓冲区的起始地址

		ORG		0x8200			; 这个程序要被装载的内存地址

; 显示进入asmhead消息
		MOV		SI,msg_asmhead
		CALL	putstr_16

; 设置画面模式

		MOV		AL,0x13			; VGA显卡，320x200x8位
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8	; 屏幕的模式（参考C语言的引用）
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; 显示VGA设置完成消息
		MOV		SI,msg_vga
		CALL	putstr_16

; 在实模式下测试VGA显存访问 - 画一条明显的白线
		MOV		AX, 0xa000          ; VGA显存段地址
		MOV		ES, AX
		MOV		DI, 0               ; 偏移地址0
		MOV		AL, 15              ; 白色（最亮）
		MOV		CX, 320             ; 填充整个第一行（320像素）
		CLD
		REP		STOSB               ; 重复存储字节

; 再画几条彩色线测试
		MOV		DI, 320             ; 第二行
		MOV		AL, 4               ; 红色
		MOV		CX, 320
		REP		STOSB

		MOV		DI, 640             ; 第三行
		MOV		AL, 2               ; 绿色
		MOV		CX, 320
		REP		STOSB

; 显示实模式VGA测试完成
		MOV		SI,msg_vga_test
		CALL	putstr_16

; 通过BIOS获取指示灯状态

		MOV		AH,0x02
		INT		0x16 			; 键盘BIOS
		MOV		[LEDS],AL

; 防止PIC接受所有中断
; AT兼容机的规范、PIC初始化
; 然后之前在CLI不做任何事就挂起
; PIC在同意后初始化

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; 不断执行OUT指令
		OUT		0xa1,AL

		CLI						; 进一步中断CPU

; 让CPU支持1M以上内存、设置A20GATE

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; 启用A20
		OUT		0x60,AL
		CALL	waitkbdout

; 保护模式转换
		MOV		SI,msg_protect
		CALL	putstr_16

		LGDT	[GDTR0]			; 设置临时GDT
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; 使用bit31（禁用分页）
		OR		EAX,0x00000001	; bit0到1转换（保护模式过渡）
		MOV		CR0,EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX,1*8			; 写32位的段
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; 在32位保护模式下，暂时不直接访问显存
; 让C代码来处理显存访问会更安全

; 跳转到C代码 - 使用固定的文件大小
; asmhead.bin固定为512字节，bootpack.bin从0x8200 + 512开始
		MOV		ESP,0x00310000      ; 设置堆栈

		; 直接跳转到固定地址的bootpack
		; 0x8200 + 512 = 0x8400
		JMP		DWORD 2*8:0x8400    ; 远跳转到C代码

; 如果C代码返回，画紫色标记
return_mark:
		MOV		EBX, 0xa0000
		ADD		EBX, 6400           ; 第20行
		MOV		AL, 5               ; 紫色
		MOV		ECX, 320
return_loop:
		MOV		[EBX], AL
		INC		EBX
		DEC		ECX
		JNZ		return_loop

; 最终无限循环
final_loop:
		HLT
		JMP		final_loop

waitkbdout:
		IN		 AL,0x64
		AND		 AL,0x02
		JNZ		waitkbdout		; AND结果不为0跳转到waitkbdout
		RET

; 16位模式下的字符串输出函数
putstr_16:
		MOV		AL,[SI]
		ADD		SI,1
		CMP		AL,0
		JE		putstr_16_end
		MOV		AH,0x0e			; 显示字符
		MOV		BX,15			; 字符颜色
		INT		0x10			; 调用BIOS显示服务
		JMP		putstr_16
putstr_16_end:
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; 运算结果不为0跳转到memcpy
		RET
; memcpy地址前缀大小

		TIMES	(16 - ($ - $$) % 16) % 16 DB 0
GDT0:
		TIMES	8 DB 0				; 初始值（空描述符）
		DW		0xffff,0x0000,0x9200,0x00cf	; 数据段描述符
		DW		0xffff,0x0000,0x9a00,0x00cf	; 代码段描述符

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

; 调试消息
msg_asmhead:
		DB		"ASMHEAD Start", 0x0d, 0x0a, 0

msg_vga:
		DB		"VGA Set", 0x0d, 0x0a, 0

msg_vga_test:
		DB		"VGA Test Real Mode", 0x0d, 0x0a, 0

msg_protect:
		DB		"Enter Protected Mode", 0x0d, 0x0a, 0

		TIMES	(16 - ($ - $$) % 16) % 16 DB 0

; 固定asmhead.bin的大小为512字节（1个扇区）
; bootpack标签必须在512字节边界上
		TIMES	512 - ($ - $$) DB 0
bootpack: