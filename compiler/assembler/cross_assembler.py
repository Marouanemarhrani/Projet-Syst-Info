#!/usr/bin/env python3
"""Cross-assembleur mémoire -> RISC 8 bits à instructions de 4 octets."""
import argparse
from pathlib import Path
OP={"ADD":1,"MUL":2,"SOU":3,"DIV":4,"COP":5,"AFC":6,"LOAD":7,"STORE":8,"JMP":9,"JMF":10,"INF":11,"SUP":12,"EQU":13,"PRI":14}
NAMES={v:k for k,v in OP.items()}
def read_memory(path):
    rows=[]
    for line_no,line in enumerate(Path(path).read_text().splitlines(),1):
        if line.strip(): rows.append((line_no,[int(x) for x in line.split()]))
    return rows
def size(v): return 2 if v[0] in (5,6,12,13,14) else 1 if v[0] in (7,8,9,10) else 4
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
        elif op in (7,8): emit(op,a,b)
        elif op==9: emit(9,a)
        elif op==10: emit(7,1,a); emit(10,1,starts.get(b,b))
        elif op in (11,12,13):
            emit(7,1,b); emit(7,2,c); emit(op,3,1,2); emit(8,a,3)
        elif op==14: emit(7,1,a); emit(14,1)
        else: raise ValueError(f"opcode mémoire inconnu: {op}")
    return out
def write_outputs(program,asm_path,hex_path):
    with Path(hex_path).open("w") as h,Path(asm_path).open("w") as a:
        for pc,(op,x,y,z) in enumerate(program):
            if any(v < 0 or v > 255 for v in (op,x,y,z)): raise ValueError(f"valeur hors 8 bits à l'instruction {pc}: {(op,x,y,z)}")
            h.write(f"{op:02X}{x:02X}{y:02X}{z:02X}\n")
            a.write(f"{pc:04d}: {NAMES[op]} " + (f"R{x}, {y}" if op == 6 else (f"@{x}, R{y}" if op == 8 else (f"R{x}, @{y}" if op == 7 else f"R{x}, R{y}, R{z}"))) + "\n")
def main():
    p=argparse.ArgumentParser();p.add_argument("input",type=Path);p.add_argument("hex_output",type=Path);p.add_argument("--asm",type=Path);args=p.parse_args()
    program=assemble(read_memory(args.input));write_outputs(program,args.asm or args.hex_output.with_suffix(".asm"),args.hex_output);print(f"{len(program)} instructions RISC générées")
if __name__=="__main__":main()
