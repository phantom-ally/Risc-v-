# RV32I Single-Cycle Processor in VHDL

A modular 32-bit RISC-V (**RV32I**) processor implemented from scratch in VHDL-2008, complete with an interactive Python assembly runner (`demo.py`) for live instruction testing and automated RTL schematic generation (`arch` / `show_arch.sh`).

---

## Architecture Overview

The top-level core (`top_level` in `Top_level.vhdl`) connects 9 modular entities across the standard 5-stage RV32I datapath:

| Stage | Entity | File | Description |
| :--- | :--- | :--- | :--- |
| **1. Fetch** | `PC_logic` | `PC_logic.vhdl` | Manages the 32-bit Program Counter (`pc`), `pc + 4`, branches, `jal`, and `jalr` targets. |
| **1. Fetch** | `Instruction_mm` | `instruction_memory.vhdl` | 1024-byte little-endian instruction ROM addressed by `pc`. |
| **1. Fetch** | `fetch` | `fetch.vhdl` | Buffers and forwards the fetched 32-bit instruction word to the decoder. |
| **2. Decode** | `Instruction_decoder` | `Decoder.vhdl` | Extracts `opcode`, `rd`, `rs1`, `rs2`, `funct3`, `funct7`, and sign-extended immediates. |
| **2. Decode** | `Control_unit` | `Control_unit.vhdl` | Generates ALU operation codes (`Alu_op`), memory read/write enables, and branch/jump mux selects. |
| **2. Decode** | `Register_b` | `Register_file.vhdl` | 32 × 32-bit general-purpose register file (`x0` hardwired to `0`). |
| **3. Execute** | `alu` | `alu.vhdl` | Executes arithmetic, logical, shift, and comparison operations (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU`). |
| **3. Execute** | `branch` | `Branch_ctrl.vhdl` | Evaluates conditional branch comparisons (`BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`). |
| **4. Memory** | `Data_mm` | `DATA_MEMORY.vhdl` | Byte-addressable data RAM supporting byte, half-word, and word loads/stores with signed/unsigned extension. |
| **5. Writeback** | `top_level` | `Top_level.vhdl` | Selects between `Data_mm` output, `pc + 4`, and `alu` result to write back to `rd`. |

---

## Supported RV32I Instructions

* **R-Type (Register-Register):** `add`, `sub`, `sll`, `slt`, `sltu`, `xor`, `srl`, `sra`, `or`, `and`
* **I-Type (Immediate & Loads):** `addi`, `slti`, `sltiu`, `xori`, `ori`, `andi`, `slli`, `srli`, `srai`, `lw`, `lh`, `lb`, `lhu`, `lbu`, `jalr`
* **S-Type (Stores):** `sw`, `sh`, `sb`
* **B-Type (Branches):** `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`
* **U/J-Type (Upper Immediate & Jumps):** `lui`, `auipc`, `jal`

---

## Prerequisites (Linux / Debian / Kali)

Install **GHDL** (VHDL simulator), **GTKWave** (waveform viewer), **Yosys** (synthesis), **Graphviz**, and **NetlistSVG**:
sudo apt update
sudo apt install -y ghdl gtkwave yosys graphviz python3 nodejs npm
sudo npm install -g netlistsvg
Quick Start
1. Fork & Clone the Repository
Bash
git clone [https://github.com/](https://github.com/)<your-username>/Risc-v-.git
cd Risc-v-

2. Run Interactive Live Assembly Demo (demo.py)
demo.py translates human-readable RISC-V assembly (including pseudo-instructions like li, mv, and 2-operand mov/add) into 32-bit little-endian machine code, loads instruction_memory.vhdl, simulates the processor with GHDL, and prints the final register file (x0–x31) directly in the terminal.
python3 demo.py


Example session:
RV32I> addi x1, x0, 15
RV32I> addi x2, x0, 25
RV32I> add x3, x1, x2
RV32I> run
You can also pass an assembly file directly:
python3 demo.py program.s
To inspect cycle-by-cycle waveforms after running demo.py:
gtkwave wave.ghw &
4. Generate Hardware Schematics (arch)
Generate both the high-level 4-stage block diagram (riscv_block_diagram.svg) and the synthesized hardware schematic (circuit_schematic.svg) directly from the VHDL source:

python3 draw_arch.py
./show_arch.sh
(Optional) Add a shell shortcut so you can run it anytime by typing arch:
echo 'alias arch="$(pwd)/show_arch.sh"' >> ~/.zshrc && source ~/.zshrc
├── Risc_5pkg.vhdl           # Custom ALU operation and data-size type packages
├── Top_level.vhdl           # Top-level processor structural wiring
├── PC_logic.vhdl            # Program Counter and branch/jump target logic
├── instruction_memory.vhdl  # Instruction ROM (auto-populated by demo.py)
├── fetch.vhdl               # Instruction fetch stage
├── Decoder.vhdl             # Instruction field decoder & immediate generator
├── Control_unit.vhdl        # Main control signal decoder
├── Register_file.vhdl       # 32x32-bit register file (reg_mm)
├── alu.vhdl                 # 32-bit Arithmetic Logic Unit
├── Branch_ctrl.vhdl         # Branch condition evaluator
├── DATA_MEMORY.vhdl         # Data RAM module
├── tb_riscv.vhdl            # Clock/reset simulation testbench
├── demo.py                  # Interactive RV32I assembler & GHDL simulation runner
├── draw_arch.py             # Graphviz textbook block diagram generator
└── show_arch.sh             # Live schematic generator (aliased as `arch`)

