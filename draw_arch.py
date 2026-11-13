import subprocess

dot_source = """
digraph RISCV_Architecture {
    rankdir=LR;
    splines=ortho;
    nodesep=0.55;
    ranksep=0.95;
    bgcolor="white";
    fontname="Helvetica";
    node [shape=record, style="rounded,filled", fontname="Helvetica", fontsize=11, penwidth=1.6];
    edge [fontname="Helvetica", fontsize=9, penwidth=1.3];

    // Stage 1: Fetch & PC
    subgraph cluster_fetch {
        label="1. Instruction Fetch & PC";
        style="dashed,rounded";
        color="#64748B";
        fontcolor="#334155";
        PC_logic [fillcolor="#DBEAFE", color="#2563EB", label="{PC_logic|<pc> pc [31:0]|<pc4> pc_plus_four [31:0]}"];
        Instruction_mm [fillcolor="#DBEAFE", color="#2563EB", label="{Instruction_mm|(ROM 1024B)|<dout> Instruction_data [31:0]}"];
        fetch [fillcolor="#DBEAFE", color="#2563EB", label="{fetch|<inst> Instruction [31:0]}"];
    }

    // Stage 2: Decode & Control
    subgraph cluster_decode {
        label="2. Decode, Control & Registers";
        style="dashed,rounded";
        color="#64748B";
        fontcolor="#334155";
        Decoder [fillcolor="#FEF3C7", color="#D97706", label="{Instruction_decoder|<op> opcode / func3 / func7|<regs> reg_1, reg_2, reg_d|<imm> immediate [31:0]}"];
        Control [fillcolor="#FCE7F3", color="#DB2777", label="{Control_unit|<alu_op> operation (Alu_op)|<ctrl> reg_write, mem_read, mem_write\\lis_branch, is_jump, is_jalr\\lalu_src_imm, use_pc, use_zero}"];
        Registers [fillcolor="#DCFCE7", color="#16A34A", label="{Register_b|(32 x 32-bit)|<d1> data1 [31:0]|<d2> data2 [31:0]}"];
    }

    // Stage 3: Execute & Branch
    subgraph cluster_exec {
        label="3. Execute & Branch";
        style="dashed,rounded";
        color="#64748B";
        fontcolor="#334155";
        ALU_Mux [shape=diamond, fillcolor="#F1F5F9", color="#475569", label="ALU Input\\nMuxes"];
        ALU [fillcolor="#E0E7FF", color="#4F46E5", label="{alu|<out> write_data (alu_out) [31:0]}"];
        Branch [fillcolor="#FCE7F3", color="#DB2777", label="{branch|<bout> branch_out}"];
    }

    // Stage 4: Memory & Writeback
    subgraph cluster_mem {
        label="4. Data Memory & Writeback";
        style="dashed,rounded";
        color="#64748B";
        fontcolor="#334155";
        Data_mm [fillcolor="#F3E8FF", color="#9333EA", label="{Data_mm|(RAM)|<mout> mm_data_out [31:0]}"];
        WB_Mux [shape=diamond, fillcolor="#F1F5F9", color="#475569", label="Writeback\\nMux"];
    }

    // Datapath & Control Connections
    PC_logic:pc -> Instruction_mm [xlabel=" instruction_address "];
    PC_logic:pc -> ALU_Mux [xlabel=" pc (use_pc) "];
    PC_logic:pc4 -> WB_Mux [xlabel=" pc_plus_four "];

    Instruction_mm:dout -> fetch [xlabel=" instruction_data "];
    fetch:inst -> Decoder [xlabel=" instruction [31:0] "];

    Decoder:op -> Control [xlabel=" opcode, func3, func7 "];
    Decoder:regs -> Registers [xlabel=" r1, r2, rd "];
    Decoder:imm -> ALU_Mux [xlabel=" immediate "];
    Decoder:imm -> PC_logic [xlabel=" immediate "];

    Control:alu_op -> ALU [color="#DB2777", xlabel=" operation "];
    Control:ctrl -> Registers [color="#DB2777", xlabel=" reg_write "];
    Control:ctrl -> Data_mm [color="#DB2777", xlabel=" mem_read/write "];
    Control:ctrl -> Branch [color="#DB2777", xlabel=" is_branch "];
    Control:ctrl -> PC_logic [color="#DB2777", xlabel=" is_jump, is_jalr "];

    Registers:d1 -> ALU_Mux [xlabel=" data1 "];
    Registers:d2 -> ALU_Mux [xlabel=" data2 "];
    Registers:d1 -> Branch [xlabel=" data1 "];
    Registers:d2 -> Branch [xlabel=" data2 "];
    Registers:d2 -> Data_mm [xlabel=" data2 (store) "];
    Registers:d1 -> PC_logic [xlabel=" register_data "];

    ALU_Mux -> ALU [xlabel=" alu_inp1, alu_inp2 "];
    ALU:out -> Data_mm [xlabel=" data_address "];
    ALU:out -> WB_Mux [xlabel=" alu_out "];

    Branch:bout -> PC_logic [color="#DB2777", xlabel=" branch_taken "];

    Data_mm:mout -> WB_Mux [xlabel=" mm_data_out "];
    WB_Mux -> Registers [color="#16A34A", xlabel=" write_data [31:0] "];
}
"""

with open("riscv_block_diagram.dot", "w") as f:
    f.write(dot_source)

subprocess.run(["dot", "-Tsvg", "riscv_block_diagram.dot", "-o", "riscv_block_diagram.svg"], check=True)
subprocess.run(["dot", "-Tpng", "-Gdpi=300", "riscv_block_diagram.dot", "-o", "riscv_block_diagram.png"], check=True)
print("Generated riscv_block_diagram.svg and riscv_block_diagram.png")
