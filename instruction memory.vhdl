library IEEE;
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
    signal memory : memory_type := (others => (others => '0'));
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
