; Tiny OS IPL (Initial Program Loader)
; Based on 30dayMakeOS 03_day
; TAB=4

; 从Makefile传入的配置参数（无默认值，必须由Makefile提供）
; 直接使用Makefile传入的常量，无需重新定义

		ORG		IPL_ADDR	; 声明程序装载地址，用于汇编器生成正确的标签地址

; 标准FAT12格式软盘引导扇区
		JMP		entry
		DB		0x90
		DB		"TINYOS  "		; 启动扇区名称（8字节）
		DW		SECTOR_SIZE		; 扇区大小
		DB		1				; 簇大小（1个扇区）
		DW		1				; FAT起始位置
		DB		2				; FAT个数
		DW		224				; 根目录大小
		DW		DISK_SIZE	; 磁盘大小
		DB		0xf0			; 磁盘类型
		DW		9				; FAT长度
		DW		SECTORS_PER_TRACK	; 每磁道扇区数
		DW		HEADS		; 磁头数
		DD		0				; 分区偏移
		DD		DISK_SIZE	; 磁盘大小
		DB		0,0,0x29		; 固定值
		DD		0xffffffff		; 卷序列号
		DB		"TINY-OS    "	; 卷标（11字节）
		DB		"FAT12   "		; 文件系统类型（8字节）
		RESB	18				; 保留18字节

entry:
		MOV		AX,0			; 初始化寄存器
		MOV		SS,AX
		MOV		SP,IPL_ADDR
		MOV		DS,AX

; 显示启动消息
		MOV		SI,msg_start
		CALL	putstr

; 读取磁盘数据到内存
        ; TODO:这个 0x0820的Magic Number暂时没想好该怎么弄
		MOV		AX,0x0820		; 读取到0x8200地址
		MOV		ES,AX
		MOV		CH,0			; 柱面0
		MOV		DH,0			; 磁头0
		MOV		CL,2			; 从扇区2开始读取

readloop:
		MOV		SI,0			; 失败计数器

retry:
		MOV		AH,0x02			; 读磁盘功能
		MOV		AL,1			; 读1个扇区
		MOV		BX,0
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 调用BIOS磁盘服务
		JNC		next			; 成功则继续
		ADD		SI,1			; 失败次数+1
		CMP		SI,5			; 重试5次
		JAE		error			; 失败则报错
		MOV		AH,0x00			; 重置磁盘
		MOV		DL,0x00
		INT		0x13
		JMP		retry

next:
		MOV		AX,ES
		ADD		AX,0x0020		; 指向下一个扇区位置
		MOV		ES,AX
		ADD		CL,1			; 扇区号+1
		CMP		CL,18			; 读取18个扇区
		JBE		readloop
        MOV     CL,1            ; 重置扇区号
        ADD		DH,1			; 磁头+1
        CMP		DH,2			; 2个磁头
        JB		readloop		; 如果磁头小于2，继续读取
        MOV		DH,0			; 重置磁头
        ADD		CH,1			; 柱面+1
        CMP		CH,CYLINDERS		    ; 比较柱面数
        JBE		readloop		; 如果柱面小于CYLS，继续读取

; 读取完成，跳转到第二阶段
		MOV		SI,msg_jump
		CALL	putstr
        MOV		[0x0ff0],CH     ; 保存柱面数
		JMP		ASMHEAD_ADDR			; 跳转到asmhead.nas

error:
		MOV		SI,msg_error
        CALL	putstr
        HLT
        JMP $

putstr:
		MOV		AL,[SI]
		ADD		SI,1
		CMP		AL,0
		JE		putstr_end
		MOV		AH,0x0e			; 显示字符
		MOV		BX,15			; 字符颜色
		INT		0x10			; 调用BIOS显示服务
		JMP		putstr
putstr_end:
		RET

putloop:
		MOV		AL,[SI]
		ADD		SI,1
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; 显示字符
		MOV		BX,15			; 字符颜色
		INT		0x10			; 调用BIOS显示服务
		JMP		putloop

fin:
		HLT
		JMP		fin

msg_start:
		DB		"IPL Start", 0x0d, 0x0a, 0

msg_jump:
		DB		"Jump to ASM", 0x0d, 0x0a, 0

msg_error:
		DB		0x0a, 0x0a
		DB		"Load Error"
		DB		0x0a
		DB		0

		TIMES	510-($-$$) DB 0		; 填充到510字节

		DB		0x55, 0xaa		; 引导签名
