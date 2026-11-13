library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Alu_ip.all;

entity alu is
    port (
        input1    : in  std_logic_vector(31 downto 0);
        input2    : in  std_logic_vector(31 downto 0);
        write_data: out std_logic_vector(31 downto 0);
        operation: in  alu_op
    );
end entity alu;

architecture functioning of alu is
begin
    process(input1, input2, operation)
        variable result_value : std_logic_vector(31 downto 0);
        variable shift_amount : natural range 0 to 31;
    begin
        result_value := (others => '0');
        shift_amount := to_integer(unsigned(input2(4 downto 0)));
        case operation is
            when ADD =>
                result_value := std_logic_vector(unsigned(input1) + unsigned(input2));
            when SUB =>
                result_value := std_logic_vector(unsigned(input1) - unsigned(input2));
            when MUL =>
                result_value := std_logic_vector(resize(unsigned(input1) * unsigned(input2), 32));
            when DIV =>
                if unsigned(input2) = 0 then
                    result_value := (others => '1');
                elsif input1 = x"80000000" and input2 = x"FFFFFFFF" then
                    result_value := input1;
                else
                    result_value := std_logic_vector(signed(input1) / signed(input2));
                end if;
            when MOD_OP =>
                if unsigned(input2) = 0 then
                    result_value := input1;
                else
                    result_value := std_logic_vector(signed(input1) rem signed(input2));
                end if;
            when DIVU =>
                if unsigned(input2) = 0 then
                    result_value := (others => '1');
                else
                    result_value := std_logic_vector(unsigned(input1) / unsigned(input2));
                end if;
            when REMU =>
                if unsigned(input2) = 0 then
                    result_value := input1;
                else
                    result_value := std_logic_vector(unsigned(input1) mod unsigned(input2));
                end if;
            when AND_ =>
                result_value := input1 and input2;
            when OR_ =>
                result_value := input1 or input2;
            when NAND_ =>
                result_value := input1 nand input2;
            when XOR_ =>
                result_value := input1 xor input2;
            when SLLI | SLL_OP =>
                result_value := std_logic_vector(shift_left(unsigned(input1), shift_amount));
            when SRLI | SRL_OP =>
                result_value := std_logic_vector(shift_right(unsigned(input1), shift_amount));
            when SRAI | SRA_OP =>
                result_value := std_logic_vector(shift_right(signed(input1), shift_amount));
            when SLT =>
                if signed(input1) < signed(input2) then
                    result_value(0) := '1';
                end if;
            when SLTU =>
                if unsigned(input1) < unsigned(input2) then
                    result_value(0) := '1';
                end if;
            when others =>
                null;
        end case;
        write_data <= result_value;
    end process;
end architecture functioning;
