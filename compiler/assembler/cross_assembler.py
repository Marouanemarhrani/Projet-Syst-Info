#!/usr/bin/env python3
"""Cross-assembleur mémoire -> RISC 8 bits à instructions de 4 octets."""
import argparse
from pathlib import Path
MEM_NAMES={1:"ADD",2:"MUL",3:"SOU",4:"DIV",5:"COP",6:"AFC",7:"JMP",8:"JMF",9:"INF",10:"SUP",11:"EQU",12:"PRI",13:"ADR",14:"LDP",15:"STP"}
RISC_NAMES={1:"ADD",2:"MUL",3:"SOU",4:"DIV",5:"COP",6:"AFC",7:"LOAD",8:"STORE",9:"JMP",10:"JMF",11:"INF",12:"SUP",13:"EQU",14:"PRI",18:"LDIND",19:"STIND",20:"CALL",21:"RET"}
def read_memory(path):
    rows=[]
    for line_no,line in enumerate(Path(path).read_text().splitlines(),1):
        if line.strip(): rows.append((line_no,[int(x) for x in line.split()]))
    return rows
def size(v): return 2 if v[0] in (5,6,12,13,14,15) else 1 if v[0] in (7,8,16,17) else 4
def assemble(rows):
    starts={}; pc=0
    for i,(_,v) in enumerate(rows): starts[i]=pc; pc+=size(v)
    out=[]
    def emit(o,a=0,b=0,c=0): out.append((o,a,b,c))
    for i,(_,v) in enumerate(rows):
        op,a=v[0],v[1]; b=v[2] if len(v)>2 else 0; c=v[3] if len(v)>3 else 0
        if op in (1,2,3,4):
            emit(7,1,b); emit(7,2,c); emit(op,3,1,2); emit(8,a,3)
        elif op==5: emit(7,1,b); emit(8,a,1)
        elif op==6: emit(6,1,b); emit(8,a,1)
        elif op==7: emit(9,a)
        elif op==8: emit(7,1,a); emit(10,1,starts.get(b,b))
        elif op in (9,10,11):
            target = {9:11,10:12,11:13}[op]
            emit(7,1,b); emit(7,2,c); emit(target,3,1,2); emit(8,a,3)
        elif op==12: emit(7,1,a); emit(14,1)
        elif op==13: emit(6,1,b); emit(8,a,1)
        elif op==14: emit(7,1,b); emit(18,1,1)
        elif op==15: emit(7,1,a); emit(7,2,b); emit(19,1,2)
        elif op==16: emit(20,a,starts.get(b,b))
        elif op==17: emit(21,a)
        else: raise ValueError(f"opcode mémoire inconnu: {op}")
    return out
def write_outputs(program,asm_path,hex_path):
    with Path(hex_path).open("w") as h,Path(asm_path).open("w") as a:
        for pc,(op,x,y,z) in enumerate(program):
            if any(v < 0 or v > 255 for v in (op,x,y,z)): raise ValueError(f"valeur hors 8 bits à l'instruction {pc}: {(op,x,y,z)}")
            h.write(f"{op:02X}{x:02X}{y:02X}{z:02X}\n")
            a.write(f"{pc:04d}: {RISC_NAMES[op]} " + (f"R{x}, {y}" if op == 6 else (f"@{x}, R{y}" if op == 8 else (f"R{x}, @{y}" if op == 7 else f"R{x}, R{y}, R{z}"))) + "\n")
def main():
    p=argparse.ArgumentParser();p.add_argument("input",type=Path);p.add_argument("hex_output",type=Path);p.add_argument("--asm",type=Path);args=p.parse_args()
    program=assemble(read_memory(args.input));write_outputs(program,args.asm or args.hex_output.with_suffix(".asm"),args.hex_output);print(f"{len(program)} instructions RISC générées")
if __name__=="__main__":main()
