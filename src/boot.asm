; tiny os
;%define __BOOT_DEBUG__ ; 做Boot sector 时一定要注释掉
                        ; 将此行打开后用 nasm boot.asm -o boot.com 做成一个.com 文件 易于调试
%ifdef __BOOT_DEBUG__
  org 0100h ; 调试状态，做成 .com 文件
%else
  org 07c00h ; Boot 状态，Bios 加载到内存的 0:0x7c00 处
%endif
mov ax, cs ; 将当前段寄存器的值存入 ax
mov ds, ax ; 将 ds 寄存器指向当前段
mov es, ax ; 将 es 寄存器指向当前段
call DispStr ; 显示字符串
jmp $ ; 无限循环

DispStr:
    mov ax, BootMessage ; 将字符串地址存入 ax
    mov bp, ax ; es:bp
    mov cx, 16 ; 字符串长度
    mov ax, 01301h ; ah=0x13, al=0x01
    mov bx, 000ch ; 颜色
    mov dl,0 ; 颜色
    int 10h ; 调用 BIOS 中断
    ret
BootMessage: db "welcome !"
times 510-($-$$) db 0 ; 填充剩下的字节，使得文件大小为 512 字节
                      ; 另外的 2 字节是引导扇区的结束标志
dw 0xaa55 ; 结束标志
