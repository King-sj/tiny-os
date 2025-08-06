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

build/bootpack.o: src/bootpack.c Makefile
	mkdir -p build
	x86_64-elf-gcc -m32 -nostdlib -fno-builtin -fno-stack-protector -c src/bootpack.c -o build/bootpack.o

build/bootpack.bin: build/bootpack.o build/naskfunc.o Makefile
	# 链接生成bootpack.bin，直接链接C代码
	x86_64-elf-ld -m elf_i386 --oformat binary -Ttext 0x0000 -o build/bootpack.tmp build/bootpack.o build/naskfunc.o
	# 固定bootpack.bin为32768字节（64个扇区），为未来功能扩展预留充足空间
	dd if=/dev/zero of=build/bootpack.bin bs=32768 count=1 2>/dev/null
	dd if=build/bootpack.tmp of=build/bootpack.bin conv=notrunc 2>/dev/null
	rm -f build/bootpack.tmp

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
	qemu-system-i386 -fda build/tiny-os.img -boot a

clean:
	rm -rf build/