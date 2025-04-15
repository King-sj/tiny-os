#!/bin/bash
mkdir build
# compile boot.asm to /build/boot.bin
nasm src/boot.asm -o build/boot.bin
# make boot.bin to os.img
script/bin2img.sh build/boot.bin build/os.img
# run os.img
qemu-system-x86_64 -drive format=raw,file=build/os.img
