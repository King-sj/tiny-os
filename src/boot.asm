; tiny os
org 07c00h ; 加载到内存的 0x7c00 处
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
BootMessage: db "tiny os"
times 510-($-$$) db 0 ; 填充剩下的字节，使得文件大小为 512 字节

dw 0xaa55 ; 结束标志
