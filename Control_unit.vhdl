library IEEE;
use IEEE.std_logic_1164.all;
use work.Alu_ip.all;
use work.Data_type.all;

entity Control_unit is
    port (
        opcode       : in  std_logic_vector(6 downto 0);
        func3        : in  std_logic_vector(2 downto 0);
        func7        : in  std_logic_vector(6 downto 0);
        reg_write    : out std_logic;
        mem_read     : out std_logic;
        mem_write    : out std_logic;
        mem_unsigned : out std_logic;
        alu_src_imm  : out std_logic;
        is_branch    : out std_logic;
        is_jump      : out std_logic;
        is_jalr      : out std_logic;
        use_pc       : out std_logic;
        use_zero     : out std_logic;
        data_size    : out D_type;
        operation    : out Alu_op
    );
end entity Control_unit;

architecture decoding of Control_unit is
begin
    process(opcode, func3, func7)
        variable op : Alu_op;
    begin
        reg_write <= '0';
        mem_read <= '0';
        mem_write <= '0';
        mem_unsigned <= '0';
        alu_src_imm <= '0';
        is_branch <= '0';
        is_jump <= '0';
        is_jalr <= '0';
        use_pc <= '0';
        use_zero <= '0';
        data_size <= WORD;
        op := ADD;

        case opcode is
            when "0110011" =>
                reg_write <= '1';
                case func3 is
                    when "000" =>
                        if func7 = "0100000" then op := OP_SUB;
                        elsif func7 = "0000001" then op := MUL;
                        elsif func7 = "0000000" then op := ADD;
                        else reg_write <= '0';
                        end if;
                    when "001" =>
                        if func7 = "0000000" then op := SLL_OP;
                        else reg_write <= '0';
                        end if;
                    when "010" =>
                        if func7 = "0000000" then op := SLT;
                        else reg_write <= '0';
                        end if;
                    when "011" =>
                        if func7 = "0000000" then op := SLTU;
                        else reg_write <= '0';
                        end if;
                    when "100" =>
                        if func7 = "0000000" then op := OP_XOR;
                        elsif func7 = "0000001" then op := DIV;
                        else reg_write <= '0';
                        end if;
                    when "101" =>
                        if func7 = "0100000" then op := SRA_OP;
                        elsif func7 = "0000000" then op := SRL_OP;
                        elsif func7 = "0000001" then op := DIVU;
                        else reg_write <= '0';
                        end if;
                    when "110" =>
                        if func7 = "0000000" then op := OP_OR;
                        elsif func7 = "0000001" then op := MOD_OP;
                        else reg_write <= '0';
                        end if;
                    when "111" =>
                        if func7 = "0000000" then op := OP_AND;
                        elsif func7 = "0000001" then op := REMU;
                        else reg_write <= '0';
                        end if;
                    when others => reg_write <= '0';
                end case;
            when "0010011" =>
                reg_write <= '1';
                alu_src_imm <= '1';
                case func3 is
                    when "000" => op := ADD;
                    when "010" => op := SLT;
                    when "011" => op := SLTU;
                    when "100" => op := OP_XOR;
                    when "110" => op := OP_OR;
                    when "111" => op := OP_AND;
                    when "001" =>
                        if func7 = "0000000" then op := SLLI;
                        else reg_write <= '0';
                        end if;
                    when "101" =>
                        if func7 = "0100000" then op := SRAI;
                        elsif func7 = "0000000" then op := SRLI;
                        else reg_write <= '0';
                        end if;
                    when others => reg_write <= '0';
                end case;
            when "0000011" =>
                reg_write <= '1';
                mem_read <= '1';
                alu_src_imm <= '1';
                case func3 is
                    when "000" => data_size <= BYTE;
                    when "001" => data_size <= HALF_WORD;
                    when "010" => data_size <= WORD;
                    when "100" =>
                        data_size <= BYTE;
                        mem_unsigned <= '1';
                    when "101" =>
                        data_size <= HALF_WORD;
                        mem_unsigned <= '1';
                    when others =>
                        mem_read <= '0';
                        reg_write <= '0';
                end case;
            when "0100011" =>
                mem_write <= '1';
                alu_src_imm <= '1';
                case func3 is
                    when "000" => data_size <= BYTE;
                    when "001" => data_size <= HALF_WORD;
                    when "010" => data_size <= WORD;
                    when others => mem_write <= '0';
                end case;
            when "1100011" =>
                is_branch <= '1';
                case func3 is
                    when "000" | "001" | "100" | "101" | "110" | "111" => null;
                    when others => is_branch <= '0';
                end case;
            when "0110111" =>
                reg_write <= '1';
                alu_src_imm <= '1';
                use_zero <= '1';
            when "0010111" =>
                reg_write <= '1';
                alu_src_imm <= '1';
                use_pc <= '1';
            when "1101111" =>
                reg_write <= '1';
                is_jump <= '1';
            when "1100111" =>
                if func3 = "000" then
                    reg_write <= '1';
                    is_jump <= '1';
                    is_jalr <= '1';
                    alu_src_imm <= '1';
                end if;
            when others =>
                null;
        end case;
        operation <= op;
    end process;
end architecture decoding;
