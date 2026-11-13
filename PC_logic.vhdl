library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity PC_logic is
    port (
        Clock        : in  std_logic;
        Reset        : in  std_logic;
        branch_taken : in  std_logic;
        is_jump      : in  std_logic;
        is_jalr      : in  std_logic;
        immediate    : in  std_logic_vector(31 downto 0);
        register_data: in  std_logic_vector(31 downto 0);
        pc           : out std_logic_vector(31 downto 0);
        pc_plus_four : out std_logic_vector(31 downto 0)
    );
end entity PC_logic;

architecture rtl of PC_logic is
    signal pc_reg  : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_next : std_logic_vector(31 downto 0);
    signal pc_plus_four_i : std_logic_vector(31 downto 0);
begin
    pc <= pc_reg;
    pc_plus_four_i <= std_logic_vector(unsigned(pc_reg) + 4);
    pc_plus_four <= pc_plus_four_i;

    process(pc_reg, pc_plus_four_i, immediate, register_data,
            branch_taken, is_jump, is_jalr)
        variable target : std_logic_vector(31 downto 0);
    begin
        if is_jalr = '1' then
            target := std_logic_vector(unsigned(register_data) + unsigned(immediate));
            target(0) := '0';
        else
            target := std_logic_vector(unsigned(pc_reg) + unsigned(immediate));
        end if;

        if is_jump = '1' or branch_taken = '1' then
            pc_next <= target;
        else
            pc_next <= pc_plus_four_i;
        end if;
    end process;

    process(Clock)
    begin
        if rising_edge(Clock) then
            if Reset = '1' then
                pc_reg <= (others => '0');
            else
                pc_reg <= pc_next;
            end if;
        end if;
    end process;
end architecture rtl;
