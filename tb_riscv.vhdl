library ieee;
use ieee.std_logic_1164.all;

entity tb_riscv is
end entity tb_riscv;

architecture sim of tb_riscv is
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    constant clk_period : time := 10 ns;
begin
    uut: entity work.top_level
        port map (
            Reset => reset,
            Clock => clk
        );

    clk_process : process
    begin
        while now < 150 ns loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    stim_process : process
    begin
        reset <= '1';
        wait for 25 ns;
        reset <= '0';
        wait;
    end process;
end architecture sim;
