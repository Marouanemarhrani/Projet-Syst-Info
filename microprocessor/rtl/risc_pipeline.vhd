library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity risc_pipeline is
  port(clk,rst : in std_logic; result_out : out std_logic_vector(7 downto 0));
end entity;

architecture rtl of risc_pipeline is
  type byte_mem is array(0 to 255) of std_logic_vector(7 downto 0);
  type instr_mem is array(0 to 255) of std_logic_vector(31 downto 0);
  signal regs : byte_mem := (others => (others => '0'));
  signal data : byte_mem := (others => (others => '0'));
  constant program : instr_mem := (
    0 => x"06010700", 1 => x"06020500", 2 => x"01030102",
    3 => x"08000300", 4 => x"07040000", others => (others => '0'));
  signal pc : integer range 0 to 255 := 0;
  signal ifid : std_logic_vector(31 downto 0) := (others=>'0');
  signal ifid_valid : std_logic := '0';
  signal idex_op,idex_a,idex_b,idex_c : integer range 0 to 255 := 0;
  signal idex_va,idex_vb : std_logic_vector(7 downto 0) := (others=>'0');
  signal idex_valid : std_logic := '0';
  signal exmem_op,exmem_a,exmem_b : integer range 0 to 255 := 0;
  signal exmem_value,exmem_store : std_logic_vector(7 downto 0) := (others=>'0');
  signal exmem_valid : std_logic := '0';
  signal memwb_op,memwb_a : integer range 0 to 255 := 0;
  signal memwb_value : std_logic_vector(7 downto 0) := (others=>'0');
  signal memwb_valid : std_logic := '0';
begin
  result_out <= regs(4);

  process(clk)
    variable op,a,b,c : integer;
    variable alu_value : integer;
    variable stall : boolean;
    variable decoded : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      if rst='0' then
        pc<=0; ifid_valid<='0'; idex_valid<='0'; exmem_valid<='0'; memwb_valid<='0';
        regs<=(others=>(others=>'0')); data<=(others=>(others=>'0'));
      else
        if memwb_valid='1' and (memwb_op=1 or memwb_op=2 or memwb_op=3 or memwb_op=4 or memwb_op=5 or memwb_op=6 or memwb_op=7 or memwb_op=11 or memwb_op=12 or memwb_op=13) then
          regs(memwb_a) <= memwb_value;
        end if;
        memwb_valid <= exmem_valid; memwb_op<=exmem_op; memwb_a<=exmem_a; if exmem_op=7 then memwb_a<=exmem_b; end if;
        if exmem_valid='1' and exmem_op=8 then
          data(exmem_a) <= exmem_store; memwb_value <= exmem_store;
        elsif exmem_valid='1' and exmem_op=7 then
          memwb_value <= data(exmem_b);
        else
          memwb_value <= exmem_value;
        end if;

        exmem_valid<=idex_valid; exmem_op<=idex_op; exmem_a<=idex_a; exmem_b<=idex_b;
        exmem_store<=idex_vb; exmem_value<=(others=>'0');
        alu_value:=0;
        if idex_valid='1' then
          case idex_op is
            when 1 => alu_value:=to_integer(unsigned(idex_va))+to_integer(unsigned(idex_vb));
            when 2 => alu_value:=to_integer(unsigned(idex_va))*to_integer(unsigned(idex_vb));
            when 3 => alu_value:=to_integer(unsigned(idex_va))-to_integer(unsigned(idex_vb));
            when 4 => if unsigned(idex_vb)=0 then alu_value:=0; else alu_value:=to_integer(unsigned(idex_va))/to_integer(unsigned(idex_vb)); end if;
            when 5 => alu_value:=to_integer(unsigned(idex_vb));
            when 6 => alu_value:=idex_b;
            when 11 => if unsigned(idex_va) < unsigned(idex_vb) then alu_value:=1; else alu_value:=0; end if;
            when 12 => if unsigned(idex_va) > unsigned(idex_vb) then alu_value:=1; else alu_value:=0; end if;
            when 13 => if unsigned(idex_va) = unsigned(idex_vb) then alu_value:=1; else alu_value:=0; end if;
            when others => null;
          end case;
          if (idex_op<=6 or (idex_op>=11 and idex_op<=13)) then exmem_value<=std_logic_vector(to_unsigned((alu_value mod 256 + 256) mod 256,8)); end if;
        end if;

        if idex_valid='1' and idex_op=9 then pc<=idex_a; ifid_valid<='0'; end if;
        if idex_valid='1' and idex_op=10 and unsigned(idex_va)=to_unsigned(0,8) then pc<=idex_b; ifid_valid<='0'; end if;
        stall:=false;
        if ifid_valid='1' and idex_valid='1' and (idex_op=1 or idex_op=2 or idex_op=3 or idex_op=4 or idex_op=5 or idex_op=6 or idex_op=7) then
          if (ifid(23 downto 20)=std_logic_vector(to_unsigned(idex_a,4))) or (ifid(19 downto 16)=std_logic_vector(to_unsigned(idex_a,4))) then stall:=true; end if;
        end if;
        if stall then
          idex_valid<='0';
        else
          idex_valid<=ifid_valid;
          op:=to_integer(unsigned(ifid(31 downto 24))); a:=to_integer(unsigned(ifid(23 downto 16))); b:=to_integer(unsigned(ifid(15 downto 8))); c:=to_integer(unsigned(ifid(7 downto 0)));
          idex_op<=op; idex_a<=a; idex_b<=b; idex_c<=c; idex_va<=regs(b); idex_vb<=regs(c);
          if op=6 then idex_vb<=std_logic_vector(to_unsigned(b,8)); end if;
          if op=7 then idex_b<=b; elsif op=8 then idex_vb<=regs(b); end if;
        end if;
        if not stall then decoded:=program(pc); ifid<=decoded; ifid_valid<='1'; if pc<255 then pc<=pc+1; end if; end if;
      end if;
    end if;
  end process;
end architecture;
