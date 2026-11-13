library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Data_type.all;

entity Instruction_decoder is
    port (
        Instruction     : in  std_logic_vector(31 downto 0);
        instruction_type: out std_logic_vector(2 downto 0);
        reg_2           : out std_logic_vector(4 downto 0);
        reg_1           : out std_logic_vector(4 downto 0);
        reg_d           : out std_logic_vector(4 downto 0);
        func7           : out std_logic_vector(6 downto 0);
        func3           : out std_logic_vector(2 downto 0);
        opcode          : out std_logic_vector(6 downto 0);
        immediate       : out std_logic_vector(31 downto 0)
    );
end entity Instruction_decoder;

architecture decoding of Instruction_decoder is
begin
    process(Instruction)
        variable imm12 : std_logic_vector(11 downto 0);
        variable imm13 : std_logic_vector(12 downto 0);
        variable imm21 : std_logic_vector(20 downto 0);
    begin
        instruction_type <= "000";
        reg_1 <= (others => '0');
        reg_2 <= (others => '0');
        reg_d <= (others => '0');
        func7 <= (others => '0');
        func3 <= (others => '0');
        opcode <= Instruction(6 downto 0);
        immediate <= (others => '0');

        case Instruction(6 downto 0) is
            when "0110011" =>
                instruction_type <= "001";
                func7 <= Instruction(31 downto 25);
                reg_2 <= Instruction(24 downto 20);
                reg_1 <= Instruction(19 downto 15);
                func3 <= Instruction(14 downto 12);
                reg_d <= Instruction(11 downto 7);
            when "0010011" | "0000011" | "1100111" =>
                instruction_type <= "010";
                imm12 := Instruction(31 downto 20);
                immediate <= sign_extend(imm12, 32);
                reg_1 <= Instruction(19 downto 15);
                func3 <= Instruction(14 downto 12);
                reg_d <= Instruction(11 downto 7);
                func7 <= Instruction(31 downto 25);
            when "0100011" =>
                instruction_type <= "011";
                imm12 := Instruction(31 downto 25) & Instruction(11 downto 7);
                immediate <= sign_extend(imm12, 32);
                reg_2 <= Instruction(24 downto 20);
                reg_1 <= Instruction(19 downto 15);
                func3 <= Instruction(14 downto 12);
            when "1100011" =>
                instruction_type <= "100";
                imm13 := Instruction(31) & Instruction(7) &
                         Instruction(30 downto 25) & Instruction(11 downto 8) & '0';
                immediate <= sign_extend(imm13, 32);
                reg_2 <= Instruction(24 downto 20);
                reg_1 <= Instruction(19 downto 15);
                func3 <= Instruction(14 downto 12);
            when "0110111" | "0010111" =>
                instruction_type <= "101";
                immediate <= Instruction(31 downto 12) & x"000";
                reg_d <= Instruction(11 downto 7);
            when "1101111" =>
                instruction_type <= "110";
                imm21 := Instruction(31) & Instruction(19 downto 12) &
                         Instruction(20) & Instruction(30 downto 21) & '0';
                immediate <= sign_extend(imm21, 32);
                reg_d <= Instruction(11 downto 7);
            when others =>
                null;
        end case;
    end process;
end architecture decoding;
