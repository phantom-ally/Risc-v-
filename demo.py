import re, subprocess, sys

REG_MAP = {f"x{i}": i for i in range(32)}
REG_MAP.update({f"r{i}": i for i in range(32)})
REG_MAP.update({
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7, "s0": 8, "fp": 8, "s1": 9,
    "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15,
    "a6": 16, "a7": 17, "s2": 18, "s3": 19, "s4": 20, "s5": 21,
    "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27,
    "t3": 28, "t4": 29, "t5": 30, "t6": 31
})

R_TYPES = {
    "add":    (0b0000000, 0b000), "sub":    (0b0100000, 0b000),
    "sll":    (0b0000000, 0b001), "slt":    (0b0000000, 0b010),
    "sltu":   (0b0000000, 0b011), "xor":    (0b0000000, 0b100),
    "srl":    (0b0000000, 0b101), "sra":    (0b0100000, 0b101),
    "or":     (0b0000000, 0b110), "and":    (0b0000000, 0b111),
    "mul":    (0b0000001, 0b000), "mulh":   (0b0000001, 0b001),
    "mulhsu": (0b0000001, 0b010), "mulhu":  (0b0000001, 0b011),
    "div":    (0b0000001, 0b100), "divu":   (0b0000001, 0b101),
    "rem":    (0b0000001, 0b110), "remu":   (0b0000001, 0b111),
}

I_TYPES = {
    "addi": 0b000, "slti": 0b010, "sltiu": 0b011,
    "xori": 0b100, "ori":  0b110, "andi":  0b111,
}

LOAD_TYPES = {
    "lb":  0b000, "lh":  0b001, "lw":  0b010,
    "lbu": 0b100, "lhu": 0b101,
}

STORE_TYPES = {
    "sb": 0b000, "sh": 0b001, "sw": 0b010,
}

BRANCH_TYPES = {
    "beq":  0b000, "bne":  0b001,
    "blt":  0b100, "bge":  0b101,
    "bltu": 0b110, "bgeu": 0b111,
}

def parse_reg(tok):
    tok = tok.strip().lower()
    if tok not in REG_MAP:
        raise ValueError(f"Unknown register '{tok}'")
    return REG_MAP[tok]

def parse_imm(tok):
    tok = tok.strip().lower()
    if tok.endswith("h"):
        return int(tok[:-1], 16)
    return int(tok, 0)

def parse_mem_operand(tok):
    m = re.match(r"(-?(?:0x)?[0-9a-fA-FhH]+)\(([^)]+)\)", tok.strip())
    if not m:
        raise ValueError(f"Invalid memory operand '{tok}', expected offset(reg)")
    return parse_imm(m.group(1)) & 0xFFF, parse_reg(m.group(2))

def encode_u(imm20, rd, opcode):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | opcode

def encode_i(imm12, rs1, f3, rd, opcode):
    return ((imm12 & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | opcode

def assemble_line(line):
    line = line.split("#")[0].split("//")[0].strip()
    if not line or line.lower() == "nop":
        return [(0x00000013, None, "nop")]

    parts = [p for p in re.split(r"[\s,]+", line) if p]
    op = parts[0].lower()

    if op in ("mov", "li", "mv"):
        rd = parse_reg(parts[1])
        if parts[2].strip().lower() in REG_MAP:
            rs1 = parse_reg(parts[2])
            return [(encode_i(0, rs1, 0b000, rd, 0b0010011), rd, line)]
        val = parse_imm(parts[2])
        if -2048 <= val <= 2047:
            return [(encode_i(val, 0, 0b000, rd, 0b0010011), rd, line)]
        val32 = val & 0xFFFFFFFF
        lo = val32 & 0xFFF
        hi = ((val32 + 0x800) >> 12) & 0xFFFFF
        return [
            (encode_u(hi, rd, 0b0110111), rd, f"lui {parts[1]}, 0x{hi:X}"),
            (encode_i(lo, rd, 0b000, rd, 0b0010011), rd, f"addi {parts[1]}, {parts[1]}, {lo - 4096 if lo >= 2048 else lo}"),
        ]

    if op in R_TYPES:
        f7, f3 = R_TYPES[op]
        if len(parts) == 3:
            rd = rs1 = parse_reg(parts[1])
            rs2 = parse_reg(parts[2])
        else:
            rd, rs1, rs2 = parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3])
        word = (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0b0110011
        return [(word, rd, line)]

    if op in I_TYPES:
        rd, rs1, imm = parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3])
        return [(encode_i(imm, rs1, I_TYPES[op], rd, 0b0010011), rd, line)]

    if op in ("slli", "srli", "srai"):
        rd, rs1, shamt = parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3]) & 0x1F
        f3 = 0b001 if op == "slli" else 0b101
        f7 = 0b0100000 if op == "srai" else 0b0000000
        word = (f7 << 25) | (shamt << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0b0010011
        return [(word, rd, line)]

    if op in ("lui", "auipc"):
        rd, imm20 = parse_reg(parts[1]), parse_imm(parts[2])
        opcode = 0b0110111 if op == "lui" else 0b0010111
        return [(encode_u(imm20, rd, opcode), rd, line)]

    if op in LOAD_TYPES:
        rd = parse_reg(parts[1])
        imm, rs1 = parse_mem_operand(parts[2])
        return [(encode_i(imm, rs1, LOAD_TYPES[op], rd, 0b0000011), rd, line)]

    if op in STORE_TYPES:
        rs2 = parse_reg(parts[1])
        imm, rs1 = parse_mem_operand(parts[2])
        word = (((imm >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (STORE_TYPES[op] << 12) | ((imm & 0x1F) << 7) | 0b0100011
        return [(word, None, line)]

    if op in BRANCH_TYPES:
        rs1, rs2, imm = parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3])
        f3 = BRANCH_TYPES[op]
        word = (
            (((imm >> 12) & 1) << 31)
            | (((imm >> 5) & 0x3F) << 25)
            | (rs2 << 20)
            | (rs1 << 15)
            | (f3 << 12)
            | (((imm >> 1) & 0xF) << 8)
            | (((imm >> 11) & 1) << 7)
            | 0b1100011
        )
        return [(word, None, line)]

    if op == "jal":
        if len(parts) == 2:
            rd, imm = 1, parse_imm(parts[1])
        else:
            rd, imm = parse_reg(parts[1]), parse_imm(parts[2])
        word = (
            (((imm >> 20) & 1) << 31)
            | (((imm >> 1) & 0x3FF) << 21)
            | (((imm >> 11) & 1) << 20)
            | (((imm >> 12) & 0xFF) << 12)
            | (rd << 7)
            | 0b1101111
        )
        return [(word, rd, line)]

    if op == "jalr":
        if len(parts) == 2:
            rd, rs1, imm = 1, parse_reg(parts[1]), 0
        elif len(parts) == 3 and "(" in parts[2]:
            rd = parse_reg(parts[1])
            imm, rs1 = parse_mem_operand(parts[2])
        else:
            rd, rs1, imm = parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3])
        return [(encode_i(imm, rs1, 0b000, rd, 0b1100111), rd, line)]

    raise ValueError(f"Unsupported instruction '{op}'")

print("==========================================================")
print("  RV32IM VHDL Processor - Interactive Live Execution Demo ")
print("==========================================================")
print("Enter assembly commands (supports RV32IM, semicolons ';', & mov/2-op syntax).")
print("Type 'run' when ready:\n")

compiled_words, touched = [], set()
while True:
    try:
        inp = input("RV32IM> ").strip()
    except EOFError:
        break
    if inp.lower() == "run":
        break
    if not inp:
        continue
    for stmt in inp.split(";"):
        stmt = stmt.strip()
        if not stmt:
            continue
        try:
            items = assemble_line(stmt)
            for word, rd, label in items:
                compiled_words.append((word, label))
                if rd:
                    touched.add(rd)
        except Exception as e:
            print(f"  [Syntax Error in '{stmt}'] {e}")

if not compiled_words:
    sys.exit(0)

mem_entries = []
print("\n[1/3] Assembling into 32-bit RV32IM Machine Code (Little-Endian):")
for idx, (word, asm) in enumerate(compiled_words):
    addr = idx * 4
    b0, b1, b2, b3 = word & 0xFF, (word >> 8) & 0xFF, (word >> 16) & 0xFF, (word >> 24) & 0xFF
    print(f"  PC=0x{addr:02X} | {asm:<26} -> 0x{word:08X}  (bytes: {b0:02X} {b1:02X} {b2:02X} {b3:02X})")
    mem_entries.append(
        f'        -- 0x{addr:02X}: {asm} (0x{word:08X})\n'
        f'        {addr} => x"{b0:02X}", {addr+1} => x"{b1:02X}", {addr+2} => x"{b2:02X}", {addr+3} => x"{b3:02X}",'
    )

vhdl = f"""library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Instruction_mm is
    port (
        Instruction_add : in  std_logic_vector(31 downto 0);
        Instruction_data: out std_logic_vector(31 downto 0)
    );
end entity Instruction_mm;

architecture model of Instruction_mm is
    type memory_type is array (0 to 1023) of std_logic_vector(7 downto 0);
    signal memory : memory_type := (
{chr(10).join(mem_entries)}
        others => (others => '0')
    );
begin
    process(Instruction_add, memory)
        variable addr : integer;
    begin
        Instruction_data <= (others => '0');
        if Instruction_add(1 downto 0) = "00" and
           unsigned(Instruction_add(31 downto 10)) = 0 then
            addr := to_integer(unsigned(Instruction_add(9 downto 0)));
            if addr <= 1020 then
                Instruction_data <= memory(addr + 3) & memory(addr + 2) &
                                    memory(addr + 1) & memory(addr);
            end if;
        end if;
    end process;
end architecture model;
"""

with open("instruction_memory.vhdl", "w") as f:
    f.write(vhdl)

print("\n[2/3] Compiling & Simulating VHDL with GHDL (100 ns)...")
subprocess.run("rm -f *.o *.cf top_level tb_riscv wave.ghw", shell=True, check=True)
subprocess.run("ghdl -i --std=08 *.vhdl", shell=True, check=True)
subprocess.run("ghdl -m --std=08 tb_riscv", shell=True, check=True)
res = subprocess.run("ghdl -r --std=08 tb_riscv --wave=wave.ghw --stop-time=100ns", shell=True, check=True, capture_output=True, text=True)

regs = {}
for line in (res.stdout + "\n" + res.stderr).splitlines():
    if "REG_VAL:" in line:
        idx_s, dec_s, hex_s = line.split("REG_VAL:")[1].strip().split(":")
        regs[int(idx_s)] = (int(dec_s), hex_s)

print("\n[3/3] Final Register File State (reg_mm):")
for r in sorted(regs.keys()):
    val, hex_s = regs[r]
    if r == 0 or val != 0 or r in touched:
        tag = " <-- modified" if r in touched else ""
        print(f"  x{r:<2} (r{r:<2}) = {val:<12} (0x{hex_s}){tag}")

subprocess.run("rm -f *.o *.cf top_level tb_riscv", shell=True, check=True)
