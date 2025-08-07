# Makefile for Tiny OS

# 构建目标文件
build/ipl.bin: src/ipl.nas Makefile
	mkdir -p build
	nasm -f bin src/ipl.nas -o build/ipl.bin

build/asmhead.bin: src/asmhead.nas Makefile
	mkdir -p build
	nasm -f bin src/asmhead.nas -o build/asmhead.bin

build/naskfunc.o: src/naskfunc.nas Makefile
	mkdir -p build
	nasm -f elf32 src/naskfunc.nas -o build/naskfunc.o

build/sprintf_asm.o: src/sprintf_asm.nas Makefile
	mkdir -p build
	nasm -f elf32 src/sprintf_asm.nas -o build/sprintf_asm.o

build/sprintf.o: src/sprintf.c Makefile
	mkdir -p build
	x86_64-elf-gcc -m32 -nostdlib -fno-builtin -fno-stack-protector -g -c src/sprintf.c -o build/sprintf.o
build/font.nas: src/font.txt Makefile
	mkdir -p build
	python3 src/makefont.py src/font.txt
build/font.o: build/font.nas Makefile
	mkdir -p build
	nasm -f elf32 build/font.nas -o build/font.o

build/bootpack.o: src/bootpack.c Makefile
	mkdir -p build
# 	编译C代码为32位目标文件，禁用标准库和栈保护，启用调试信息
	x86_64-elf-gcc -m32 -nostdlib -fno-builtin -fno-stack-protector -g -c src/bootpack.c -o build/bootpack.o

build/bootpack.bin: build/bootpack.o build/naskfunc.o build/sprintf_asm.o build/sprintf.o build/font.o Makefile
	# 链接生成bootpack.bin，直接链接C代码, 0x8400是bootpack的起始地址
	x86_64-elf-ld -m elf_i386 --oformat binary -Ttext 0x8400 -o build/bootpack.tmp build/bootpack.o build/naskfunc.o build/sprintf_asm.o build/sprintf.o build/font.o
	# 同时生成带调试信息的ELF文件用于调试
	x86_64-elf-ld -m elf_i386 -Ttext 0x8400 -o build/bootpack.elf build/bootpack.o build/naskfunc.o build/sprintf_asm.o build/sprintf.o build/font.o
	# 固定bootpack.bin为32768字节（64个扇区），为未来功能扩展预留充足空间
	dd if=/dev/zero of=build/bootpack.bin bs=32768 count=1 2>/dev/null
	dd if=build/bootpack.tmp of=build/bootpack.bin conv=notrunc 2>/dev/null

build/system.bin: build/asmhead.bin build/bootpack.bin Makefile
	# 创建固定大小的system.bin（65个扇区 = 33280字节）
	# asmhead.bin: 512字节（1个扇区）
	# bootpack.bin: 32768字节（64个扇区）
	dd if=/dev/zero of=build/system.bin bs=512 count=65 2>/dev/null
	# 写入asmhead.bin到第1个扇区
	dd if=build/asmhead.bin of=build/system.bin conv=notrunc 2>/dev/null
	# 写入bootpack.bin到第2-65个扇区
	dd if=build/bootpack.bin of=build/system.bin bs=512 seek=1 conv=notrunc 2>/dev/null

# 创建软盘镜像
img: build/ipl.bin build/system.bin Makefile
	mkdir -p build
	# 创建1.44MB空软盘镜像
	dd if=/dev/zero of=build/tiny-os.img bs=512 count=2880 2>/dev/null
	# 写入引导扇区
	dd if=build/ipl.bin of=build/tiny-os.img conv=notrunc 2>/dev/null
	# 从第2扇区开始写入系统文件
	dd if=build/system.bin of=build/tiny-os.img bs=512 seek=1 conv=notrunc 2>/dev/null

run: img
	qemu-system-i386 -drive file=build/tiny-os.img,format=raw,if=floppy -boot a

# 运行时显示CPU信息
run-info: img
	qemu-system-i386 -drive file=build/tiny-os.img,format=raw,if=floppy -boot a -cpu qemu32 -d cpu

# 慢速运行（模拟低频CPU）
run-slow: img
	qemu-system-i386 -drive file=build/tiny-os.img,format=raw,if=floppy -boot a -icount shift=10

# 快速运行（模拟高频CPU）
run-fast: img
	qemu-system-i386 -drive file=build/tiny-os.img,format=raw,if=floppy -boot a -icount shift=0

# 精确时钟同步运行
run-sync: img
	qemu-system-i386 -drive file=build/tiny-os.img,format=raw,if=floppy -boot a -icount shift=auto,align=on

# 使用不同的CPU类型运行
run-486: img
	qemu-system-i386 -drive file=build/tiny-os.img,format=raw,if=floppy -boot a -cpu 486

run-pentium: img
	qemu-system-i386 -drive file=build/tiny-os.img,format=raw,if=floppy -boot a -cpu pentium

run-modern: img
	qemu-system-i386 -drive file=build/tiny-os.img,format=raw,if=floppy -boot a -cpu Haswell

log: img
	timeout 10 qemu-system-i386 -drive file=build/tiny-os.img,format=raw,if=floppy -boot a -d cpu,int,exec -D debug.log -no-reboot -no-shutdown 2>&1 || true

debug-server: img
# 	使用 qemu 的调试功能，开启 gdb 服务器
	qemu-system-i386 -drive file=build/tiny-os.img,format=raw,if=floppy -s -S
# 	使用 qemu 的监控台连接调试
# 	qemu-system-i386 -fda build/tiny-os.img -s -S -monitor stdio

debug-connect:
# 	使用 gdb 连接到 qemu 的 gdb 服务器
	x86_64-elf-gdb -ex "file build/bootpack.elf" \
	               -ex "target remote :1234" \
	               -ex "set architecture i386" \
	               -ex "break *0x7c00" \
	               -ex "break HariMain" \
	               -ex "display/10i \$$pc"

# 	使用 lldb 连接到 qemu 的 gdb 服务器
# 	lldb  -arch i386 -o "gdb-remote 1234" -o "register read" -o "memory read 0x7c00" -o "breakpoint set --address 0x7c00"

clean:
	rm -rf build/