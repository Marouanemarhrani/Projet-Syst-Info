library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity register_file is
 port(clk,rst,we:in std_logic;ra,rb,rw:in std_logic_vector(3 downto 0);wd:in std_logic_vector(7 downto 0);qa,qb:out std_logic_vector(7 downto 0));
end entity;
architecture rtl of register_file is
 type regs_t is array(0 to 15) of std_logic_vector(7 downto 0);signal regs:regs_t:=(others=>(others=>'0'));
begin
 qa<=wd when we='1' and ra=rw else regs(to_integer(unsigned(ra)));
 qb<=wd when we='1' and rb=rw else regs(to_integer(unsigned(rb)));
 process(clk)begin if rising_edge(clk)then if rst='0' then regs<=(others=>(others=>'0'));elsif we='1' then regs(to_integer(unsigned(rw)))<=wd;end if;end if;end process;
end architecture;
