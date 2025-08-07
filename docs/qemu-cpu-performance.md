# QEMU CPU 频率和性能配置说明

## 1. QEMU CPU 频率机制

QEMU 使用虚拟指令计数器（icount）来控制 CPU 执行速度，而不是传统的"主频"概念。

### 默认行为

- 无 `-icount` 参数：以主机 CPU 速度运行，尽可能快
- 适合开发和测试，但时间不确定

### icount 模式参数

#### shift 参数

```bash
-icount shift=N
```

- **shift=0**: 每个虚拟时钟周期执行 2^0 = 1 条指令（最快）
- **shift=3**: 每个虚拟时钟周期执行 2^3 = 8 条指令
- **shift=10**: 每个虚拟时钟周期执行 2^10 = 1024 条指令（较慢）
- **shift=auto**: 自动调整，保持虚拟时间与实际时间同步

#### 其他重要参数

```bash
-icount shift=auto,align=on,sleep=on
```

- **align=on**: 对齐虚拟时钟和主机时钟
- **sleep=on**: 当虚拟机空闲时让主机 CPU 休眠
- **sleep=off**: 始终占用主机 CPU（更精确但耗电）

## 2. 实际使用建议

### 开发阶段（推荐默认）

```bash
qemu-system-i386 -fda build/tiny-os.img -boot a
```

- 最快的执行速度
- 适合调试和开发

### 性能测试

```bash
qemu-system-i386 -fda build/tiny-os.img -boot a -icount shift=auto,align=on
```

- 接近真实硬件的时序
- 适合测试定时器、延时等

### 模拟低端硬件

```bash
qemu-system-i386 -fda build/tiny-os.img -boot a -icount shift=10 -cpu 486
```

- 模拟较慢的 CPU
- 适合测试在低端硬件上的表现

### 精确计时测试

```bash
qemu-system-i386 -fda build/tiny-os.img -boot a -icount shift=0,align=on,sleep=off
```

- 最精确的时序控制
- 适合测试实时性要求高的代码
