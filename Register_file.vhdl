library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Register_b is
    port (
        r1          : in  std_logic_vector(4 downto 0);
        r2          : in  std_logic_vector(4 downto 0);
        rd          : in  std_logic_vector(4 downto 0);
        write_data  : in  std_logic_vector(31 downto 0);
        write_enable: in  std_logic;
        data1       : out std_logic_vector(31 downto 0);
        data2       : out std_logic_vector(31 downto 0);
        reset       : in  std_logic;
        clock       : in  std_logic
    );
end entity Register_b;

architecture behavior of Register_b is
    type register_memory is array (0 to 31) of std_logic_vector(31 downto 0);
    signal reg_mm : register_memory := (others => (others => '0'));
begin
    process(clock)
        variable rd_index : integer;
    begin
        if rising_edge(clock) then
            if reset = '1' then
                reg_mm <= (others => (others => '0'));
            elsif write_enable = '1' then
                rd_index := to_integer(unsigned(rd));
                if rd_index /= 0 then
                    reg_mm(rd_index) <= write_data;
                end if;
            end if;
        end if;
    end process;

    process(r1, r2, reg_mm)
        variable r1_index : integer;
        variable r2_index : integer;
    begin
        r1_index := to_integer(unsigned(r1));
        r2_index := to_integer(unsigned(r2));
        if r1_index = 0 then
            data1 <= (others => '0');
        else
            data1 <= reg_mm(r1_index);
        end if;
        if r2_index = 0 then
            data2 <= (others => '0');
        else
            data2 <= reg_mm(r2_index);
        end if;
    end process;
end architecture behavior;
