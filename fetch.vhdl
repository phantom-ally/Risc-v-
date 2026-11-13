library IEEE;
use IEEE.std_logic_1164.all;

entity fetch is
    port (
        Instruction_data : in  std_logic_vector(31 downto 0);
        Instruction     : out std_logic_vector(31 downto 0)
    );
end entity fetch;

architecture model of fetch is
begin
    Instruction <= Instruction_data;
end architecture model;
