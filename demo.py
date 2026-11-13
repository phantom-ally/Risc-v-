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
    "add":  (0b0000000, 0b000), "sub":  (0b0100000, 0b000),
    "sll":  (0b0000000, 0b001), "slt":  (0b0000000, 0b010),
    "sltu": (0b0000000, 0b011), "xor":  (0b0000000, 0b100),
    "srl":  (0b0000000, 0b101), "sra":  (0b0100000, 0b101),
    "or":   (0b0000000, 0b110), "and":  (0b0000000, 0b111),
}

I_TYPES = {
    "addi": 0b000, "slti": 0b010, "sltiu": 0b011,
    "xori": 0b100, "ori":  0b110, "andi":  0b111,
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

def assemble_line(line):
    line = line.split("#")[0].split("//")[0].strip()
    if not line or line.lower() == "nop":
        return 0x00000013, None
    parts = [p for p in re.split(r"[\s,]+", line) if p]
    op = parts[0].lower()

    # Support 8086/ARM-style "mov r1, 12h" or "mov r1, r2"
    if op in ("mov", "li", "mv"):
        rd = parse_reg(parts[1])
        if parts[2].strip().lower() in REG_MAP:
            rs1 = parse_reg(parts[2])
            return ((0 << 20) | (rs1 << 15) | (0b000 << 12) | (rd << 7) | 0b0010011), rd
        imm = parse_imm(parts[2]) & 0xFFF
        return ((imm << 20) | (0 << 15) | (0b000 << 12) | (rd << 7) | 0b0010011), rd

    # Support 2-operand "add r1, r2" -> "add r1, r1, r2" as well as 3-operand "add x1, x1, x2"
    if op in R_TYPES:
        f7, f3 = R_TYPES[op]
        if len(parts) == 3:
            rd = rs1 = parse_reg(parts[1])
            rs2 = parse_reg(parts[2])
        else:
            rd, rs1, rs2 = parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3])
        return ((f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0b0110011), rd

    if op in I_TYPES:
        rd, rs1, imm = parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3]) & 0xFFF
        return ((imm << 20) | (rs1 << 15) | (I_TYPES[op] << 12) | (rd << 7) | 0b0010011), rd

    if op in ("slli", "srli", "srai"):
        rd, rs1, shamt = parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3]) & 0x1F
        f3 = 0b001 if op == "slli" else 0b101
        f7 = 0b0100000 if op == "srai" else 0b0000000
        return ((f7 << 25) | (shamt << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0b0010011), rd

    if op == "lw":
        rd = parse_reg(parts[1])
        m = re.match(r"(-?(?:0x)?[0-9a-fA-FhH]+)\(([^)]+)\)", parts[2])
        imm, rs1 = parse_imm(m.group(1)) & 0xFFF, parse_reg(m.group(2))
        return ((imm << 20) | (rs1 << 15) | (0b010 << 12) | (rd << 7) | 0b0000011), rd

    if op == "sw":
        rs2 = parse_reg(parts[1])
        m = re.match(r"(-?(?:0x)?[0-9a-fA-FhH]+)\(([^)]+)\)", parts[2])
        imm, rs1 = parse_imm(m.group(1)) & 0xFFF, parse_reg(m.group(2))
        return (((imm >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (0b010 << 12) | ((imm & 0x1F) << 7) | 0b0100011, None

    raise ValueError(f"Unsupported instruction '{op}'")

print("==========================================================")
print("  RV32I VHDL Processor - Interactive Live Execution Demo  ")
print("==========================================================")
print("Enter assembly commands (supports both RISC-V & mov/2-op syntax).")
print("Type 'run' when ready:\n")

lines, touched = [], set()
while True:
    try:
        inp = input("RV32I> ").strip()
    except EOFError:
        break
    if inp.lower() == "run":
        break
    if inp:
        try:
            _, rd = assemble_line(inp)
            lines.append(inp)
            if rd:
                touched.add(rd)
        except Exception as e:
            print(f"  [Syntax Error] {e}")

if not lines:
    sys.exit(0)

mem_entries = []
print("\n[1/3] Assembling into 32-bit RV32I Machine Code (Little-Endian):")
for idx, asm in enumerate(lines):
    word, _ = assemble_line(asm)
    addr = idx * 4
    b0, b1, b2, b3 = word & 0xFF, (word >> 8) & 0xFF, (word >> 16) & 0xFF, (word >> 24) & 0xFF
    print(f"  PC=0x{addr:02X} | {asm:<22} -> 0x{word:08X}  (bytes: {b0:02X} {b1:02X} {b2:02X} {b3:02X})")
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
