# Makefile for Tiny OS

ipl.bin: src/ipl.nas Makefile
	mkdir -p build
	nasm -f bin src/ipl.nas -o build/ipl.bin

img : ipl.bin
	script/bin2img.sh build/ipl.bin build/tiny-os.img

run: img
	qemu-system-x86_64 -drive format=raw,file=build/tiny-os.img

clean:
	rm -f build/ipl.bin build/tiny-os.img