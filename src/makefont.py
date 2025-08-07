# 将 $<font_path>.txt 中定义的字体信息转换为 nas 汇编文件
# 以\n\n分隔， 第一行是字体名称
# 其余行为字符ascii 码和 8x16 点阵图(.为0, *为1)
from enum import Enum
import os
class FontStateMachine:

    class State(Enum):
        START = 1 # 开始状态
        FONT_NAME = 2 # 字体名称声明, 总是第一行
        CHAR_NAME = 3 # 单个字符 ASIIC: 形如 char 0x41
        CHAR_DATA = 4 # 字符数据
        NOP = 5       # 无操作状态
    class LineType(Enum):
        CHAR_NAME_DEF = 1
        CHAR_DATA_DEF = 2
        ERR = 3
        @staticmethod
        def match(line: str) -> 'FontStateMachine.LineType':
            if line.startswith("char "):
                if len(line) < 8 or not line[5:7].startswith('0x'):
                    return FontStateMachine.LineType.ERR
                asc = line[7:9]
                if not asc.isalnum():
                    return FontStateMachine.LineType.ERR
                return FontStateMachine.LineType.CHAR_NAME_DEF
            elif all(c in '.*' for c in line) and len(line) == 8:
                return FontStateMachine.LineType.CHAR_DATA_DEF
            return FontStateMachine.LineType.ERR
    state: State = State.START
    CHAR_DATA_MAX_SIZE = 16 # 每个字符数据的最大长度
    char_data_size = 0
    char_num = 0
    font_nas_file = '''
; 定义字体数据, 由 makefont 自动生成
section .data ; x86_64-elf-gcc ld 貌似不支持 .rodata
global __font
__font:
    '''
    def __init__(self):
        pass
    def transition(self, line: str):
        if self.state == self.State.START:
            if not line.strip():
                return
            self.state = self.State.FONT_NAME
            self.set_font_name(line)
            return
        if self.state == self.State.FONT_NAME:
            if not line.strip():
                return
            line_type = self.LineType.match(line)
            if line_type == self.LineType.CHAR_NAME_DEF:
                self.state = self.State.CHAR_NAME
                self.push_char_name(line)
                return
            print(f"Error: Invalid font definition line: {line}")
            exit(1)
        if self.state == self.State.CHAR_NAME:
            if not line.strip():
                return
            line_type = self.LineType.match(line)
            if line_type == self.LineType.CHAR_DATA_DEF:
                self.state = self.State.CHAR_DATA
                self.char_data_size = 1
                self.push_char_data(line)
                return
            elif line_type == self.LineType.ERR:
                print(f"Error: Invalid character definition line: {line}")
                exit(1)
            else:
                print(f"Error: Unexpected line in CHAR_NAME state: {line}")
                exit(1)
        if self.state == self.State.CHAR_DATA:
            if not line.strip():
                return
            line_type = self.LineType.match(line)
            if line_type == self.LineType.CHAR_DATA_DEF:
                if self.char_data_size >= self.CHAR_DATA_MAX_SIZE:
                    print(f"Error: Character data exceeds maximum size of {self.CHAR_DATA_MAX_SIZE} bits.")
                    exit(1)
                self.push_char_data(line)
                self.char_data_size += 1
                if self.char_data_size == self.CHAR_DATA_MAX_SIZE:
                    self.state = self.State.NOP
                return
            elif line_type == self.LineType.ERR:
                print(f"Error: Invalid character data line: {line}")
                exit(1)
            else:
                print(f"Error: Unexpected line in CHAR_DATA state: {line}")
                exit(1)
        if self.state == self.State.NOP:
            if not line.strip():
                return
            line_type = self.LineType.match(line)
            if line_type == self.LineType.CHAR_NAME_DEF:
                self.state = self.State.CHAR_NAME
                self.push_char_name(line)
                return
            elif line_type == self.LineType.CHAR_DATA_DEF:
                print(f"Error: Unexpected character data line in NOP state: {line}")
                exit(1)
            elif line_type == self.LineType.ERR:
                print(f"Error: Invalid line in NOP state: {line}")
                exit(1)
            else:
                print(f"Error: Unexpected line in NOP state: {line}")
                exit(1)

    def set_font_name(self, font_name: str):
        self.font_nas_file = f"; 字体名称: {font_name}\n" + self.font_nas_file
    def push_char_name(self, char_name: str):
        self.char_num += 1
        self.font_nas_file += f"; {char_name}\n"
    def push_char_data(self, char_data: str):
        code = 0
        for c in char_data:
            if c not in '.*':
                print(f"Error: Invalid character in font data: {c}")
                exit(1)
            code = (code << 1) | (1 if c == '*' else 0)
        self.font_nas_file += f"    db 0x{code:02x}\n"
    def get_font_nas_file(self):
        if self.state != self.State.NOP:
            print("Error: Font definition is not complete.")
            exit(1)
        if self.char_num == 0:
            print("Error: No characters defined in font.")
            exit(1)
        print(f"Font definition complete: {self.char_num} characters defined.")
        self.font_nas_file += f"; 字体定义结束，共 {self.char_num} 个字符\n"
        return self.font_nas_file

def gen_font_nas_file(font_txt_file_path:str):

    # 检查文件是否存在
    if not os.path.exists(font_txt_file_path):
        print(f"Error: {font_txt_file_path} not found.")
        return
    sm = FontStateMachine()
    with open(font_txt_file_path, 'r') as f:
        lines = f.readlines()
    for line in lines:
        line = line.strip()
        if not line:
            continue
        sm.transition(line)
    with open('build/font.nas', 'w') as f:
        f.write(sm.get_font_nas_file())

if __name__ == '__main__':
    # 调用方式 python makefont.py $<font_path>
    import sys
    if len(sys.argv) != 2:
        print("Usage: python makefont.py <font_path>")
    else:
        gen_font_nas_file(sys.argv[1])
        print(f"Font NAS file generated at build/font.nas")
