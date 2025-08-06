```sh
# 查看寄存器状态
(gdb) info registers
(gdb) info reg

# 查看当前指令和下几条指令
(gdb) display/i $pc

# 单步执行并显示汇编
(gdb) stepi
(gdb) si

# 查看内存内容（十六进制）
(gdb) x/16xb 0x7c00

# 查看内存内容（指令格式）
(gdb) x/10i 0x7c00
```
- si - 单步执行
- x/10i $pc - 查看当前位置汇编
- info reg - 查看寄存器状态