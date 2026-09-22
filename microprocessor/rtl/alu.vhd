library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity alu is
 port(a,b:in std_logic_vector(7 downto 0);op:in std_logic_vector(2 downto 0);result:out std_logic_vector(7 downto 0);n,overflow,z,carry:out std_logic);
end entity;
architecture rtl of alu is begin
 process(a,b,op) variable av,bv,v:integer;
 begin
  av:=to_integer(unsigned(a));bv:=to_integer(unsigned(b));
  case op is when "001"=>v:=av+bv; when "010"=>v:=av*bv; when "011"=>v:=av-bv; when others=>if bv=0 then v:=0;else v:=av/bv;end if;end case;
  result<=std_logic_vector(to_unsigned(v mod 256,8));if v<0 then n<='1';else n<='0';end if;if v=0 then z<='1';else z<='0';end if;if v>255 or v<0 then overflow<='1';else overflow<='0';end if;if v>255 then carry<='1';else carry<='0';end if;
 end process;
end architecture;
