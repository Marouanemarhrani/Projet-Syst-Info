library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
entity risc_pipeline_tb is end;
architecture sim of risc_pipeline_tb is
 signal clk:std_logic:='0'; signal rst:std_logic:='0'; signal result:std_logic_vector(7 downto 0);
begin
 clk<=not clk after 5 ns;
 dut:entity work.risc_pipeline port map(clk=>clk,rst=>rst,result_out=>result);
 process
 begin
   wait for 12 ns; rst<='1'; wait for 220 ns;
   assert result=x"0C" report "Le pipeline n'a pas produit 12" severity failure;
   report "Testbench RISC réussi"; stop;
 end process;
end architecture;
