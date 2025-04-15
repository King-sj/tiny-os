#!/bin/bash

# 功能：将 .bin 文件转换为可启动的 .img 镜像
# 用法：./bin2img.sh input.bin [output.img]

# 检查输入参数
if [ $# -lt 1 ]; then
    echo "错误：请指定输入的 .bin 文件"
    echo "用法: $0 <input.bin> [output.img]"
    exit 1
fi

INPUT_BIN="$1"
OUTPUT_IMG="${2:-${INPUT_BIN%.*}.img}"  # 默认输出同名 .img 文件

# 检查输入文件是否存在
if [ ! -f "$INPUT_BIN" ]; then
    echo "错误: 输入文件 $INPUT_BIN 不存在"
    exit 1
fi

# 检查输入是否为 .bin 文件
if [[ "$INPUT_BIN" != *.bin ]]; then
    echo "错误: 输入文件必须是 .bin 格式"
    exit 1
fi

# 检查依赖工具 (dd)
if ! command -v dd &> /dev/null; then
    echo "错误: 请确保已安装 'dd' 工具"
    exit 1
fi

# 创建空白镜像（1.44MB 软盘镜像，兼容大多数模拟器）
echo "创建空白镜像: $OUTPUT_IMG (1.44MB)..."
dd if=/dev/zero of="$OUTPUT_IMG" bs=512 count=2880 status=none

# 将 .bin 文件写入镜像开头
echo "写入引导程序: $INPUT_BIN -> $OUTPUT_IMG..."
dd if="$INPUT_BIN" of="$OUTPUT_IMG" conv=notrunc status=none

# 检查/添加引导签名 (0x55AA)
echo "检查引导签名..."
SIGNATURE=$(tail -c 2 "$INPUT_BIN" | hexdump -v -e '/1 "%02X"')
if [ "$SIGNATURE" != "55AA" ]; then
    echo "添加引导签名 0x55AA..."
    printf '\x55\xAA' | dd of="$OUTPUT_IMG" bs=1 seek=510 conv=notrunc status=none
else
    echo "引导签名已存在"
fi

# 完成提示
echo "镜像生成成功: $OUTPUT_IMG"
echo "可用以下命令启动测试: qemu-system-x86_64 -drive format=raw,file=$OUTPUT_IMG"