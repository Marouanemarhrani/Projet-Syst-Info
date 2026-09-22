library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity data_memory is
 port(clk,rst,we:in std_logic;address:in std_logic_vector(7 downto 0);din:in std_logic_vector(7 downto 0);dout:out std_logic_vector(7 downto 0));
end entity;
architecture rtl of data_memory is
 type mem_t is array(0 to 255) of std_logic_vector(7 downto 0);signal mem:mem_t:=(others=>(others=>'0'));
begin
 dout<=mem(to_integer(unsigned(address)));
 process(clk)begin if rising_edge(clk)then if rst='0' then mem<=(others=>(others=>'0'));elsif we='1' then mem(to_integer(unsigned(address)))<=din;end if;end if;end process;
end architecture;
