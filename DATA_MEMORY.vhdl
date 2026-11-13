library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Data_type.all;

entity Data_mm is
    generic (
        SPACE     : integer := 8;
        BUS_width : integer := 32
    );
    port (
        Clock         : in  std_logic;
        data_address  : in  std_logic_vector(31 downto 0);
        data1         : in  std_logic_vector(BUS_width - 1 downto 0);
        mm_data_out   : out std_logic_vector(BUS_width - 1 downto 0);
        data_wr_enable: in  std_logic;
        data_size     : in  D_type;
        data_req      : in  std_logic;
        data_zero_exd : in  std_logic
    );
end entity Data_mm;

architecture functionality of Data_mm is
    constant MEMORY_BYTES : integer := 2 ** SPACE;
    type Data_memory is array (0 to MEMORY_BYTES - 1) of std_logic_vector(7 downto 0);
    signal RAM : Data_memory := (others => (others => '0'));
begin
    process(Clock)
        variable data_ptr : integer;
        variable byte_count : integer;
    begin
        if rising_edge(Clock) then
            if data_wr_enable = '1' and data_req = '1' then
                data_ptr := to_integer(unsigned(data_address(SPACE - 1 downto 0)));
                case data_size is
                    when BYTE      => byte_count := 1;
                    when HALF_WORD => byte_count := 2;
                    when WORD      => byte_count := 4;
                    when others    => byte_count := 0;
                end case;
                if byte_count > 0 and data_ptr <= MEMORY_BYTES - byte_count then
                    RAM(data_ptr) <= data1(7 downto 0);
                    if byte_count >= 2 then
                        RAM(data_ptr + 1) <= data1(15 downto 8);
                    end if;
                    if byte_count = 4 then
                        RAM(data_ptr + 2) <= data1(23 downto 16);
                        RAM(data_ptr + 3) <= data1(31 downto 24);
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(data_address, data_wr_enable, data_req, data_size, data_zero_exd, RAM)
        variable data_ptr : integer;
        variable byte_count : integer;
        variable read_value : std_logic_vector(31 downto 0);
    begin
        mm_data_out <= (others => '0');
        if data_wr_enable = '0' and data_req = '1' then
            data_ptr := to_integer(unsigned(data_address(SPACE - 1 downto 0)));
            case data_size is
                when BYTE      => byte_count := 1;
                when HALF_WORD => byte_count := 2;
                when WORD      => byte_count := 4;
                when others    => byte_count := 0;
            end case;
            if byte_count > 0 and data_ptr <= MEMORY_BYTES - byte_count then
                read_value := (others => '0');
                read_value(7 downto 0) := RAM(data_ptr);
                if byte_count >= 2 then
                    read_value(15 downto 8) := RAM(data_ptr + 1);
                end if;
                if byte_count = 4 then
                    read_value(31 downto 16) := RAM(data_ptr + 3) & RAM(data_ptr + 2);
                end if;
                case data_size is
                    when BYTE =>
                        if data_zero_exd = '1' then
                            mm_data_out <= zero_extend(read_value(7 downto 0), BUS_width);
                        else
                            mm_data_out <= sign_extend(read_value(7 downto 0), BUS_width);
                        end if;
                    when HALF_WORD =>
                        if data_zero_exd = '1' then
                            mm_data_out <= zero_extend(read_value(15 downto 0), BUS_width);
                        else
                            mm_data_out <= sign_extend(read_value(15 downto 0), BUS_width);
                        end if;
                    when WORD =>
                        mm_data_out <= read_value;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;
end architecture functionality;
