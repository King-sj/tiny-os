# Makefile for Tiny OS

# ==== 配置参数 ====
# 架构和工具配置
ARCH := i386                   # 目标架构：32位x86
CC := x86_64-elf-gcc          # C编译器：使用交叉编译工具链
LD := x86_64-elf-ld           # 链接器：ELF格式链接器
ASM := nasm                   # 汇编器：Netwide Assembler
PYTHON := python3             # Python解释器：用于字体生成等脚本

# 内存布局配置
IPL_ADDR := 0x7c00            # IPL（Initial Program Loader）装载地址：BIOS标准引导扇区地址
ASMHEAD_ADDR := 0x8200        # ASMHEAD装载地址：第二阶段引导代码地址
BOOTPACK_ADDR := 0x280000     # BOOTPACK装载地址：主内核代码地址（2.5MB处）
VRAM_ADDR := 0xa0000          # VGA显存基地址：标准VGA模式显存地址
DSKCAC0_ADDR := 0x8000        # 磁盘缓存0地址：临时磁盘数据缓存
DSKCAC_ADDR := 0x100000       # 磁盘缓存地址：主磁盘数据缓存（1MB处）
STACK_ADDR := 0x310000        # 栈顶地址：内核栈地址（约3MB处）

# 磁盘配置
## 几何参数（模拟1.44MB软盘）
CYLINDERS := 30               # 柱面数：软盘柱面数量
SECTORS_PER_TRACK := 18       # 每磁道扇区数：标准软盘每磁道扇区数
HEADS := 2                    # 磁头数：双面软盘磁头数
DISK_SIZE := 2880             # 磁盘大小：总扇区数（1.44MB = 2880 * 512字节）
SECTOR_SIZE := 512            # 扇区大小：标准扇区字节数
## 系统文件大小配置
BOOTPACK_SIZE := 32768        # BOOTPACK固定大小：32KB（预留足够空间）
SYSTEM_SECTORS := 65          # 系统占用扇区数：asmhead(1) + bootpack(64)

# VGA配置
VGA_MODE := 0x13              # VGA显示模式：320x200x8位颜色模式
SCREEN_WIDTH := 320           # 屏幕宽度：像素数
SCREEN_HEIGHT := 200          # 屏幕高度：像素数
SCREEN_COLORS := 8            # 屏幕颜色位数：8位（256色）

# 目录配置
BUILD_DIR := build
SRC_DIR := src
STATIC_DIR := static
SCRIPTS_DIR := scripts

# ==== 计算的参数 ====
# 基于上述配置自动计算的参数
SYSTEM_SIZE := $(shell echo $$(($(SYSTEM_SECTORS) * $(SECTOR_SIZE))))      # 系统文件总大小
BOOTPACK_SECTORS := $(shell echo $$(($(BOOTPACK_SIZE) / $(SECTOR_SIZE))))  # BOOTPACK占用扇区数

# ==== 编译和汇编标志 ====
# C编译器标志
CFLAGS := -m32 -nostdlib -fno-builtin -fno-stack-protector -g  # 32位模式，无标准库，保留调试信息
# 链接器标志
LDFLAGS := -m elf_i386        # 生成32位ELF格式

# 传递给汇编器的所有参数（统一定义，避免重复）
# 这些参数作为预定义宏传递给汇编器，可在.nas文件中直接使用
ASM_DEFINES := -DIPL_ADDR=$(IPL_ADDR) \
               -DASMHEAD_ADDR=$(ASMHEAD_ADDR) \
               -DBOOTPACK_ADDR=$(BOOTPACK_ADDR) \
               -DVRAM_ADDR=$(VRAM_ADDR) \
               -DDSKCAC0_ADDR=$(DSKCAC0_ADDR) \
               -DDSKCAC_ADDR=$(DSKCAC_ADDR) \
               -DSTACK_ADDR=$(STACK_ADDR) \
               -DCYLINDERS=$(CYLINDERS) \
               -DSECTORS_PER_TRACK=$(SECTORS_PER_TRACK) \
               -DHEADS=$(HEADS) \
               -DDISK_SIZE=$(DISK_SIZE) \
               -DSECTOR_SIZE=$(SECTOR_SIZE) \
               -DBOOTPACK_SIZE=$(BOOTPACK_SIZE) \
               -DSYSTEM_SECTORS=$(SYSTEM_SECTORS) \
               -DVGA_MODE=$(VGA_MODE) \
               -DSCREEN_WIDTH=$(SCREEN_WIDTH) \
               -DSCREEN_HEIGHT=$(SCREEN_HEIGHT) \
               -DSCREEN_COLORS=$(SCREEN_COLORS)

# 汇编器标志
ASMFLAGS_BIN := -f bin $(ASM_DEFINES) -DBIN      # 生成纯二进制文件
ASMFLAGS_ELF := -f elf32 $(ASM_DEFINES)          # 生成ELF32目标文件
ASMFLAGS_ELF_DEBUG := -f elf32 -g -F dwarf $(ASM_DEFINES)  # 生成带调试信息的ELF32文件

# ==== 源文件列表 ====
# 汇编源文件
ASM_SOURCES := ipl asmhead naskfunc sprintf_asm
ASM_BIN_TARGETS := ipl asmhead
ASM_OBJ_TARGETS := naskfunc sprintf_asm

# C源文件
C_SOURCES := bootpack sprintf graphic dsctbl int
C_OBJECTS := $(addprefix $(BUILD_DIR)/, $(addsuffix .o, $(C_SOURCES)))

# 生成的文件
GENERATED_SOURCES := font
GENERATED_OBJECTS := $(addprefix $(BUILD_DIR)/, $(addsuffix .o, $(GENERATED_SOURCES)))

# bootpack依赖的所有目标文件
BOOTPACK_OBJS := $(C_OBJECTS) $(addprefix $(BUILD_DIR)/, $(addsuffix .o, $(ASM_OBJ_TARGETS))) $(GENERATED_OBJECTS)

# QEMU基础命令
QEMU_BASE := qemu-system-$(ARCH) -drive file=$(BUILD_DIR)/tiny-os.img,format=raw,if=floppy -boot a

# ==== 通用规则 ====
# 默认目标
.DEFAULT_GOAL := img

# 创建构建目录
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# ==== 模式规则 ====
# 汇编文件 -> 二进制文件
$(BUILD_DIR)/%.bin: $(SRC_DIR)/%.nas Makefile | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS_BIN) $< -o $@

# 汇编文件 -> ELF目标文件
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.nas Makefile | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS_ELF) $< -o $@

# C文件 -> 目标文件
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c Makefile | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# ==== 特殊目标 ====
# asmhead需要特殊的ELF版本用于调试
$(BUILD_DIR)/asmhead.elf: $(SRC_DIR)/asmhead.nas Makefile | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS_ELF_DEBUG) $< -o $@

# 字体处理
$(BUILD_DIR)/font.nas: $(STATIC_DIR)/font/font.txt Makefile | $(BUILD_DIR)
	$(PYTHON) $(SCRIPTS_DIR)/makefont.py $< $@

$(BUILD_DIR)/font.o: $(BUILD_DIR)/font.nas Makefile
	$(ASM) $(ASMFLAGS_ELF) $< -o $@

# ==== 链接目标 ====
$(BUILD_DIR)/bootpack.bin: $(BOOTPACK_OBJS) Makefile
	# 链接生成bootpack.bin，直接链接C代码
	$(LD) $(LDFLAGS) --oformat binary -Ttext $(BOOTPACK_ADDR) -o $(BUILD_DIR)/bootpack.tmp $(BOOTPACK_OBJS)
	# 同时生成带调试信息的ELF文件用于调试
	$(LD) $(LDFLAGS) -Ttext $(BOOTPACK_ADDR) -o $(BUILD_DIR)/bootpack.elf $(BOOTPACK_OBJS)
	# 固定bootpack.bin大小为$(BOOTPACK_SIZE)字节，为未来功能扩展预留充足空间
	dd if=/dev/zero of=$@ bs=$(BOOTPACK_SIZE) count=1 2>/dev/null
	dd if=$(BUILD_DIR)/bootpack.tmp of=$@ conv=notrunc 2>/dev/null

$(BUILD_DIR)/system.bin: $(BUILD_DIR)/asmhead.bin $(BUILD_DIR)/bootpack.bin Makefile
	# 创建固定大小的system.bin（$(SYSTEM_SECTORS)个扇区 = $(SYSTEM_SIZE)字节）
	# asmhead.bin: $(SECTOR_SIZE)字节（1个扇区）
	# bootpack.bin: $(BOOTPACK_SIZE)字节（$(BOOTPACK_SECTORS)个扇区）
	dd if=/dev/zero of=$@ bs=$(SECTOR_SIZE) count=$(SYSTEM_SECTORS) 2>/dev/null
	# 写入asmhead.bin到第1个扇区
	dd if=$(BUILD_DIR)/asmhead.bin of=$@ conv=notrunc 2>/dev/null
	# 写入bootpack.bin到第2-$(SYSTEM_SECTORS)个扇区
	dd if=$(BUILD_DIR)/bootpack.bin of=$@ bs=$(SECTOR_SIZE) seek=1 conv=notrunc 2>/dev/null

# ==== 软盘镜像 ====
img: $(BUILD_DIR)/tiny-os.img

$(BUILD_DIR)/tiny-os.img: $(BUILD_DIR)/ipl.bin $(BUILD_DIR)/system.bin Makefile
	# 创建1.44MB空软盘镜像
	dd if=/dev/zero of=$@ bs=$(SECTOR_SIZE) count=$(DISK_SIZE) 2>/dev/null
	# 写入引导扇区
	dd if=$(BUILD_DIR)/ipl.bin of=$@ conv=notrunc 2>/dev/null
	# 从第2扇区开始写入系统文件
	dd if=$(BUILD_DIR)/system.bin of=$@ bs=$(SECTOR_SIZE) seek=1 conv=notrunc 2>/dev/null

# ==== QEMU运行目标 ====
# 基础运行
run: img
	$(QEMU_BASE)

# 运行变体（使用函数简化）
define run_variant
run-$(1): img
	$(QEMU_BASE) $(2)
endef

# 定义各种运行变体
$(eval $(call run_variant,info,-cpu qemu32 -d cpu))
$(eval $(call run_variant,slow,-icount shift=10))
$(eval $(call run_variant,fast,-icount shift=0))
$(eval $(call run_variant,sync,-icount shift=auto,align=on))
$(eval $(call run_variant,486,-cpu 486))
$(eval $(call run_variant,pentium,-cpu pentium))
$(eval $(call run_variant,modern,-cpu Haswell))

# 鼠标测试运行目标
run-mouse-usb: img
	$(QEMU_BASE) -usb -device usb-mouse

run-mouse-gtk: img
	$(QEMU_BASE) -display gtk,grab-on-hover=on

run-mouse-vnc: img
	@echo "启动VNC服务器，使用以下命令连接："
	@echo "open vnc://localhost:5901"
	$(QEMU_BASE) -vnc :1

# 测试异常和crash处理
test-crash: img
	@echo "测试crash处理机制..."
	@echo "启动后系统会显示完整的中断处理支持"
	@echo "按键测试键盘中断，按Ctrl+C退出"
	$(QEMU_BASE) -display gtk

# 鼠标测试相关运行目标
run-mouse-usb: img
	$(QEMU_BASE) -usb -device usb-mouse

run-mouse-gtk: img
	$(QEMU_BASE) -display gtk,grab-on-hover=on

run-mouse-vnc: img
	@echo "启动VNC服务器，请在浏览器访问 vnc://localhost:5901"
	$(QEMU_BASE) -vnc :1

# ==== 调试目标 ====
log: img
	$(QEMU_BASE) -d cpu,int,guest_errors -D debug-full.log -serial stdio

# 增强的调试日志 - 捕获更多信息
debug-log: img
	$(QEMU_BASE) -d cpu,int,exec,unimp,guest_errors -D debug-full.log -serial stdio

# 调试服务器 - 在crash时停止
debug-server: img $(BUILD_DIR)/asmhead.elf
	$(QEMU_BASE) -s -S -no-reboot -no-shutdown

# 调试服务器 - 运行但在异常时停止
debug-server-run: img $(BUILD_DIR)/asmhead.elf
	$(QEMU_BASE) -s -no-reboot -no-shutdown

debug-connect:
	echo "调试kernel"
	x86_64-elf-gdb -ex "file $(BUILD_DIR)/bootpack.elf" \
				   -ex "add-symbol-file $(BUILD_DIR)/bootpack.elf $(BOOTPACK_ADDR)" \
	               -ex "target remote :1234" \
	               -ex "set architecture $(ARCH)" \
	               -ex "set disassembly-flavor intel" \
	               -ex "break *$(BOOTPACK_ADDR)" \
	               -ex "break asm_inthandler21" \
	               -ex "break inthandler21" \
	               -ex "display/10i \$$pc+$(BOOTPACK_ADDR)"

# 增强的GDB连接 - 添加异常处理
debug-connect-enhanced:
	echo "增强调试kernel - 捕获异常"
	x86_64-elf-gdb -ex "file $(BUILD_DIR)/bootpack.elf" \
				   -ex "add-symbol-file $(BUILD_DIR)/bootpack.elf $(BOOTPACK_ADDR)" \
	               -ex "target remote :1234" \
	               -ex "set architecture $(ARCH)" \
	               -ex "set disassembly-flavor intel" \
	               -ex "break *$(BOOTPACK_ADDR)" \
	               -ex "break asm_inthandler21" \
	               -ex "break inthandler21" \
	               -ex "catch signal SIGSEGV" \
	               -ex "catch signal SIGILL" \
	               -ex "set confirm off" \
	               -ex "display/10i \$$pc" \
	               -ex "display/x \$$esp" \
	               -ex "display/x \$$ebp"

lldb-connect:
	lldb -o "target create $(BUILD_DIR)/bootpack.elf" \
	     -o "gdb-remote localhost:1234" \
	     -o "settings set target.x86-disassembly-flavor intel" \
	     -o "breakpoint set --address $(IPL_ADDR)" \
	     -o "breakpoint set --name HariMain" \
	     -o "process status" \
	     -o "disassemble --pc --count 5"

# LLDB完整连接（启动后手动加载符号）
lldb-connect-full:
	@echo "启动LLDB，连接后请手动执行以下命令加载asmhead符号："
	@echo "target modules add $(BUILD_DIR)/asmhead.elf"
	@echo "或者使用: image add $(BUILD_DIR)/asmhead.elf"
	lldb -o "target create $(BUILD_DIR)/bootpack.elf" \
	     -o "gdb-remote localhost:1234" \
	     -o "settings set target.x86-disassembly-flavor intel" \
	     -o "breakpoint set --address $(IPL_ADDR)" \
	     -o "breakpoint set --name HariMain"

# 16位模式调试连接（用于调试实模式部分）
debug-connect-16:
	x86_64-elf-gdb -ex "target remote :1234" \
	               -ex "set architecture i8086" \
	               -ex "set disassembly-flavor intel" \
	               -ex "break *$(IPL_ADDR)" \
	               -ex "break *$(ASMHEAD_ADDR)" \
	               -ex "display/10i \$$pc"

# ==== 清理目标 ====
clean:
	rm -rf $(BUILD_DIR)/

# ==== 帮助信息 ====
help:
	@echo "Tiny OS Makefile"
	@echo ""
	@echo "主要目标:"
	@echo "  img           - 构建软盘镜像"
	@echo "  run           - 运行操作系统"
	@echo "  clean         - 清理构建文件"
	@echo ""
	@echo "调试目标:"
	@echo "  debug-server           - 启动调试服务器（暂停启动）"
	@echo "  debug-server-run       - 启动调试服务器（直接运行）"
	@echo "  debug-connect          - 连接GDB调试器"
	@echo "  debug-connect-enhanced - 连接GDB调试器（增强版，捕获异常）"
	@echo "  lldb-connect           - 连接LLDB调试器（快速）"
	@echo "  lldb-connect-full      - 连接LLDB调试器（完整，需手动加载符号）"
	@echo "  debug-connect-16       - 16位模式GDB调试"
	@echo "  log                    - 生成执行日志"
	@echo "  debug-log              - 生成增强调试日志"
	@echo ""
	@echo "运行变体:"
	@echo "  run-info      - 显示CPU信息运行"
	@echo "  run-slow      - 慢速运行"
	@echo "  run-fast      - 快速运行"
	@echo "  run-486       - 486 CPU运行"
	@echo "  run-pentium   - Pentium CPU运行"
	@echo "  run-modern    - 现代CPU运行"
	@echo ""
	@echo "鼠标测试运行目标:"
	@echo "  run-mouse-usb - 使用USB鼠标模拟运行"
	@echo "  run-mouse-gtk - 使用GTK显示和鼠标捕获运行"
	@echo "  run-mouse-vnc - 使用VNC显示运行（端口5901）"
	@echo ""
	@echo "调试技巧:"
	@echo "1. 键盘crash调试："
	@echo "   make debug-server-run &"
	@echo "   make debug-connect-enhanced"
	@echo "   (gdb) c   # 继续运行，按键盘测试"
	@echo ""
	@echo "2. 捕获crash地址："
	@echo "   make debug-log"
	@echo "   查看debug-full.log文件"

.PHONY: img run clean help debug-server debug-server-run debug-connect debug-connect-enhanced debug-connect-16 log debug-log \
        lldb-connect lldb-connect-full \
        run-info run-slow run-fast run-sync run-486 run-pentium run-modern \
        run-mouse-usb run-mouse-gtk run-mouse-vnc