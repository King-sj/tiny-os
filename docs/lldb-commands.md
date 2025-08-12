# LLDB 调试命令参考

## 连接和基础操作

### 连接远程调试
```bash
# 连接到QEMU gdbserver（端口1234）
(lldb) gdb-remote localhost:1234

# 或者直接在启动时连接
lldb -o "gdb-remote localhost:1234"
```

### 加载符号文件
```bash
# 创建目标并加载主执行文件
(lldb) target create build/bootpack.elf

# 方法1：添加额外的模块（推荐用于调试文件）
(lldb) target modules add build/asmhead.elf
(lldb) image add build/asmhead.elf

# 方法2：如果需要指定基地址，先添加模块再设置地址
(lldb) target modules add build/asmhead.elf
(lldb) target modules load --file build/asmhead.elf --slide 0x8200

# 查看已加载的模块
(lldb) target modules list
(lldb) image list

# 手动设置符号文件的基地址（如果自动检测不正确）
(lldb) target symbols add build/asmhead.elf
```

## 符号加载问题解决

### 常见错误和解决方案

1. **"no object file for module" 错误**：
   ```bash
   # 错误示例
   (lldb) target modules load --file build/asmhead.elf --slide 0x8200
   error: no object file for module 'build/asmhead.elf'

   # 解决方案：先添加模块
   (lldb) target modules add build/asmhead.elf
   # 然后可以设置基地址（可选）
   (lldb) target modules load --file build/asmhead.elf --slide 0x8200
   ```

2. **符号无法解析**：
   ```bash
   # 检查符号是否正确加载
   (lldb) image lookup --name function_name
   (lldb) image lookup --address 0x8200

   # 如果找不到符号，尝试重新添加
   (lldb) target modules add build/asmhead.elf
   ```

3. **地址映射问题**：
   ```bash
   # 查看当前模块的加载地址
   (lldb) target modules list

   # 手动设置正确的基地址
   (lldb) target modules load --file build/asmhead.elf --slide 0x8200
   ```

## 执行控制

### 单步执行
```bash
(lldb) si          # 单步执行一条指令（step instruction）
(lldb) s           # 单步执行，进入函数调用（step）
(lldb) n           # 单步执行，跳过函数调用（next）
(lldb) finish      # 执行到当前函数返回
(lldb) c           # 继续执行（continue）
```

### 断点管理
```bash
# 设置断点
(lldb) breakpoint set --address 0x7c00          # 在指定地址设置断点
(lldb) breakpoint set --name HariMain           # 在函数名设置断点
(lldb) breakpoint set --file bootpack.c --line 20  # 在文件的指定行设置断点
(lldb) b 0x7c00                                  # 简写形式

# 管理断点
(lldb) breakpoint list                           # 列出所有断点
(lldb) breakpoint delete 1                       # 删除断点1
(lldb) breakpoint disable 1                      # 禁用断点1
(lldb) breakpoint enable 1                       # 启用断点1
```

## 查看状态

### 寄存器
```bash
(lldb) register read                             # 显示所有寄存器
(lldb) register read eax ebx ecx edx            # 显示指定寄存器
(lldb) register read --all                      # 显示所有寄存器（包括特殊寄存器）
(lldb) register write eax 0x12345678            # 写入寄存器值
```

### 内存
```bash
(lldb) memory read 0x7c00                       # 读取指定地址的内存
(lldb) memory read --size 4 --count 10 0x7c00   # 读取10个4字节值
(lldb) memory read --format x --size 1 --count 16 0x7c00  # 十六进制显示16字节
(lldb) x/16xb 0x7c00                            # GDB风格的内存查看
(lldb) memory write 0x7c00 0x90 0x90            # 写入内存
```

### 反汇编
```bash
(lldb) disassemble --pc                         # 反汇编当前PC位置
(lldb) disassemble --pc --count 10              # 反汇编当前PC位置后10条指令
(lldb) disassemble --start-address 0x7c00 --count 20  # 反汇编指定地址
(lldb) disassemble --name HariMain              # 反汇编指定函数
```

### 栈和调用
```bash
(lldb) bt                                       # 显示调用栈（backtrace）
(lldb) frame info                               # 显示当前帧信息
(lldb) up                                       # 移动到上一个栈帧
(lldb) down                                     # 移动到下一个栈帧
```

## 变量和表达式

### 查看变量
```bash
(lldb) frame variable                           # 显示当前作用域的所有变量
(lldb) frame variable var_name                  # 显示指定变量
(lldb) p variable_name                          # 打印变量值
(lldb) po object_name                           # 打印对象（适用于OC/Swift）
```

### 表达式计算
```bash
(lldb) expression $eax + $ebx                   # 计算表达式
(lldb) expr (int)$eax                          # 类型转换
(lldb) expr $pc = 0x7c00                       # 修改PC寄存器
```

## 模块和符号

### 模块信息
```bash
(lldb) target modules list                      # 列出所有加载的模块
(lldb) target modules show-unwind               # 显示展开信息
(lldb) image lookup --address 0x7c00           # 查找地址对应的符号
(lldb) image lookup --name HariMain            # 查找符号信息
```

## 设置和配置

### 显示设置
```bash
(lldb) settings set target.x86-disassembly-flavor intel  # 设置Intel汇编语法
(lldb) settings show target.x86-disassembly-flavor       # 显示当前设置
```

### 自动显示
```bash
(lldb) target stop-hook add --one-liner "register read eip"  # 每次停止时显示EIP
(lldb) target stop-hook add --one-liner "disassemble --pc --count 5"  # 每次停止时反汇编
(lldb) target stop-hook list                    # 列出所有stop hook
(lldb) target stop-hook delete 1                # 删除stop hook
```

## 实用技巧

### 操作系统内核调试
```bash
# 16位实模式调试
(lldb) settings set target.default-arch i386
(lldb) breakpoint set --address 0x7c00

# 32位保护模式调试
(lldb) settings set target.default-arch i386
(lldb) breakpoint set --name HariMain

# 查看段寄存器（在支持的情况下）
(lldb) register read cs ds es fs gs ss
```

### 快捷命令别名
```bash
# 在~/.lldbinit中定义别名
command alias r register read
command alias rd register read
command alias rw register write
command alias si stepi
command alias dis disassemble --pc --count 10
```

## 常见问题解决

### "Command requires a current process"
- 确保已经连接到远程目标：`gdb-remote localhost:1234`
- 确保QEMU已经启动并在等待调试连接

### 无法设置断点
- 检查符号文件是否正确加载
- 使用地址而不是符号名设置断点
- 确保目标代码已经加载到内存中

### 寄存器显示不正确
- 检查目标架构设置是否正确
- 在实模式和保护模式切换时可能需要重新连接

## 调试工作流示例

```bash
# 1. 启动QEMU调试服务器
make debug-server

# 2. 在另一个终端连接LLDB
make lldb-connect

# 3. 开始调试
(lldb) process status     # 查看进程状态
(lldb) register read      # 查看寄存器（连接后可用）
(lldb) c                  # 继续执行到第一个断点
(lldb) si                 # 单步执行
(lldb) disassemble --pc --count 10  # 查看当前指令
(lldb) memory read --format x --size 1 --count 16 $pc  # 查看内存
```

### 正确的连接顺序

LLDB连接远程调试器的正确顺序很重要：

```bash
# 正确顺序：
1. target create file.elf    # 先创建目标
2. gdb-remote host:port     # 再连接远程
3. 其他配置命令             # 最后配置

# 错误顺序：
1. gdb-remote host:port     # 先连接（会导致某些命令失效）
2. target create file.elf   # 后创建目标
```

### 常用调试命令组合

```bash
# 查看当前状态
(lldb) process status
(lldb) thread list
(lldb) register read eip esp
(lldb) disassemble --pc --count 5

# 执行控制
(lldb) c           # 继续执行
(lldb) si          # 单步执行指令
(lldb) s           # 单步执行（进入函数）
(lldb) n           # 单步执行（跳过函数）
(lldb) finish      # 执行到函数返回

# 内存和寄存器
(lldb) memory read --format x --size 4 --count 8 0x7c00
(lldb) register write eax 0x12345678
(lldb) expression $eip = 0x7c00
```
