library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package Alu_ip is
    subtype Alu_op is std_logic_vector(4 downto 0);
    constant ADD   : Alu_op := "00000";
    constant SUB   : Alu_op := "00001";
    constant MUL   : Alu_op := "00010";
    constant DIV   : Alu_op := "00011";
    constant MOD_OP: Alu_op := "00100";
    constant AND_  : Alu_op := "00101";
    constant OR_   : Alu_op := "00110";
    constant NAND_ : Alu_op := "00111";
    constant XOR_  : Alu_op := "01000";
    constant SLLI  : Alu_op := "01001";
    constant SRLI  : Alu_op := "01010";
    constant SRAI  : Alu_op := "01011";
    constant SLL_OP: Alu_op := "01100";
    constant SRL_OP: Alu_op := "01101";
    constant SRA_OP: Alu_op := "01110";
    constant SLT   : Alu_op := "01111";
    constant SLTU  : Alu_op := "10000";
    constant DIVU  : Alu_op := "10001";
    constant REMU  : Alu_op := "10010";
end package Alu_ip;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package Data_type is
    subtype D_type is std_logic_vector(1 downto 0);
    constant BYTE      : D_type := "00";
    constant HALF_WORD : D_type := "01";
    constant WORD      : D_type := "10";

    function zero_extend(data : std_logic_vector; out_width : integer)
        return std_logic_vector;
    function sign_extend(data : std_logic_vector; out_width : integer)
        return std_logic_vector;
end package Data_type;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package body Data_type is
    function zero_extend(data : std_logic_vector; out_width : integer)
        return std_logic_vector is
        variable result : std_logic_vector(out_width - 1 downto 0);
    begin
        result := (others => '0');
        result(data'length - 1 downto 0) := data;
        return result;
    end function zero_extend;

    function sign_extend(data : std_logic_vector; out_width : integer)
        return std_logic_vector is
        variable result : std_logic_vector(out_width - 1 downto 0);
    begin
        result := (others => data(data'left));
        result(data'length - 1 downto 0) := data;
        return result;
    end function sign_extend;
end package body Data_type;

library IEEE;
use IEEE.std_logic_1164.all;

package branch_type is
    subtype b_type_ins is std_logic_vector(2 downto 0);
    constant BEQ  : b_type_ins := "000";
    constant BNE  : b_type_ins := "001";
    constant BLT  : b_type_ins := "100";
    constant BGE  : b_type_ins := "101";
    constant BLTU : b_type_ins := "110";
    constant BGEU : b_type_ins := "111";
end package branch_type;

library IEEE;
use IEEE.std_logic_1164.all;

package R_type is
    subtype R_type_ins is std_logic_vector(4 downto 0);
    constant R_ADD  : R_type_ins := "00000";
    constant R_SUB  : R_type_ins := "00001";
    constant R_MUL  : R_type_ins := "00010";
    constant R_DIV  : R_type_ins := "00011";
    constant R_MOD  : R_type_ins := "00100";
    constant R_AND  : R_type_ins := "00101";
    constant R_OR   : R_type_ins := "00110";
    constant R_NAND : R_type_ins := "00111";
    constant R_XOR  : R_type_ins := "01000";
    constant R_SLL  : R_type_ins := "01100";
    constant R_SRL  : R_type_ins := "01101";
    constant R_SRA  : R_type_ins := "01110";
    constant R_SLT  : R_type_ins := "01111";
    constant R_SLTU : R_type_ins := "10000";
end package R_type;

library IEEE;
use IEEE.std_logic_1164.all;

package I_type is
    subtype I_type_ins is std_logic_vector(3 downto 0);
    constant I_LB       : I_type_ins := "0000";
    constant I_LH       : I_type_ins := "0001";
    constant I_LW       : I_type_ins := "0010";
    constant I_LBU      : I_type_ins := "0011";
    constant I_LHU      : I_type_ins := "0100";
    constant I_SLLI     : I_type_ins := "0101";
    constant I_SRLI_SRAI: I_type_ins := "0110";
    constant I_ADDI     : I_type_ins := "0111";
    constant I_SLTI     : I_type_ins := "1000";
    constant I_SLTIU    : I_type_ins := "1001";
    constant I_ANDI     : I_type_ins := "1010";
    constant I_ORI      : I_type_ins := "1011";
    constant I_NANDI    : I_type_ins := "1100";
    constant I_XORI     : I_type_ins := "1101";
end package I_type;

library IEEE;
use IEEE.std_logic_1164.all;

package S_type is
    subtype S_type_ins is std_logic_vector(1 downto 0);
    constant S_SB : S_type_ins := "00";
    constant S_SH : S_type_ins := "01";
    constant S_SW : S_type_ins := "10";
end package S_type;

library IEEE;
use IEEE.std_logic_1164.all;

package SRC_type is
    subtype SRC_type_ins is std_logic_vector(1 downto 0);
    constant SRC_ALU : SRC_type_ins := "00";
    constant SRC_MEM : SRC_type_ins := "01";
    constant SRC_IMM : SRC_type_ins := "10";
    constant SRC_PC  : SRC_type_ins := "11";
end package SRC_type;

library IEEE;
use IEEE.std_logic_1164.all;

package control_var is
    subtype compos is std_logic_vector(2 downto 0);
    constant CTRL_ZERO_EXTEND : compos := "000";
    constant CTRL_MEM_VALID   : compos := "001";
    constant CTRL_MEM_WRITE   : compos := "010";
    constant CTRL_IMMEDIATE   : compos := "011";
    constant CTRL_PC          : compos := "100";
end package control_var;
