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
    signal memory : memory_type := (
        -- 0x00: lui x1, 0x80000 (0x800000B7)
        0 => x"B7", 1 => x"00", 2 => x"00", 3 => x"80",
        -- 0x04: addi x2, x0, -1 (0xFFF00113)
        4 => x"13", 5 => x"01", 6 => x"F0", 7 => x"FF",
        -- 0x08: div x3, x1, x2 (0x0220C1B3)
        8 => x"B3", 9 => x"C1", 10 => x"20", 11 => x"02",
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
