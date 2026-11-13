library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Alu_ip.all;
use work.Data_type.all;

entity top_level is
    port (
        Reset : in std_logic;
        Clock : in std_logic
    );
end entity top_level;

architecture beh of top_level is
    signal pc, pc_plus_four : std_logic_vector(31 downto 0);
    signal instruction_address, instruction_data, instruction : std_logic_vector(31 downto 0);
    signal immediate, write_data : std_logic_vector(31 downto 0);
    signal data1, data2, alu_inp1, alu_inp2, alu_out : std_logic_vector(31 downto 0);
    signal data_address, mm_data_out : std_logic_vector(31 downto 0);
    signal instruction_type : std_logic_vector(2 downto 0);
    signal func3 : std_logic_vector(2 downto 0);
    signal func7, opcode : std_logic_vector(6 downto 0);
    signal reg_1, reg_2, reg_d : std_logic_vector(4 downto 0);
    signal data_size : D_type;
    signal operation : Alu_op;
    signal reg_write, mem_read, mem_write, mem_unsigned : std_logic;
    signal alu_src_imm, is_branch, is_jump, is_jalr : std_logic;
    signal use_pc, use_zero, branch_out, mem_req : std_logic;
begin
    Instruction_fetch : entity work.Instruction_mm
        port map (
            Instruction_add  => instruction_address,
            Instruction_data => instruction_data
        );

    Fetch : entity work.fetch
        port map (
            Instruction_data => instruction_data,
            Instruction      => instruction
        );

    instruction_address <= pc;

    Decode : entity work.Instruction_decoder
        port map (
            Instruction      => instruction,
            instruction_type => instruction_type,
            reg_1            => reg_1,
            reg_2            => reg_2,
            reg_d            => reg_d,
            func7            => func7,
            func3            => func3,
            opcode           => opcode,
            immediate        => immediate
        );

    Control : entity work.Control_unit
        port map (
            opcode       => opcode,
            func3        => func3,
            func7        => func7,
            reg_write    => reg_write,
            mem_read     => mem_read,
            mem_write    => mem_write,
            mem_unsigned => mem_unsigned,
            alu_src_imm  => alu_src_imm,
            is_branch    => is_branch,
            is_jump      => is_jump,
            is_jalr      => is_jalr,
            use_pc       => use_pc,
            use_zero     => use_zero,
            data_size    => data_size,
            operation    => operation
        );

    Registers : entity work.Register_b
        port map (
            r1           => reg_1,
            r2           => reg_2,
            rd           => reg_d,
            write_data   => write_data,
            write_enable => reg_write,
            data1        => data1,
            data2        => data2,
            reset        => Reset,
            clock        => Clock
        );

    alu_inp1 <= pc when use_pc = '1' else
                (others => '0') when use_zero = '1' else data1;
    alu_inp2 <= immediate when alu_src_imm = '1' else data2;
    mem_req <= (mem_read or mem_write) and not Reset;

    ALU_block : entity work.alu
        port map (
            input1     => alu_inp1,
            input2     => alu_inp2,
            write_data => alu_out,
            operation  => operation
        );

    data_address <= alu_out;
    Data_memory : entity work.Data_mm
        port map (
            Clock          => Clock,
            data_address   => data_address,
            data1          => data2,
            mm_data_out    => mm_data_out,
            data_wr_enable => mem_write,
            data_size      => data_size,
            data_req       => mem_req,
            data_zero_exd  => mem_unsigned
        );

    Branch_control : entity work.branch
        port map (
            data1      => data1,
            data2      => data2,
            is_branch  => is_branch,
            func3      => func3,
            branch_out => branch_out
        );

    PC_control : entity work.PC_logic
        port map (
            Clock         => Clock,
            Reset         => Reset,
            branch_taken  => branch_out,
            is_jump       => is_jump,
            is_jalr       => is_jalr,
            immediate     => immediate,
            register_data => data1,
            pc            => pc,
            pc_plus_four  => pc_plus_four
        );

    process(pc_plus_four, mm_data_out, mem_read, is_jump, alu_out)
    begin
        if mem_read = '1' then
            write_data <= mm_data_out;
        elsif is_jump = '1' then
            write_data <= pc_plus_four;
        else
            write_data <= alu_out;
        end if;
    end process;

end architecture beh;
