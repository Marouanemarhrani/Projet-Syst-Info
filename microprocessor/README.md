# Microprocesseur RISC pipeline

Le dossier rtl contient les briques matérielles demandées : UAL 8 bits, banc de
16 registres avec bypass et mémoire de données synchrone. Les instructions ont
quatre octets fixes : opcode, A, B, C.

Cross-assemblage :
  python3 compiler/assembler/cross_assembler.py build/control.obj build/control.hex

Opcodes RISC : ADD=01, MUL=02, SOU=03, DIV=04, COP=05, AFC=06,
LOAD=07, STORE=08, JMP=09, JMF=0A, INF=0B, SUP=0C, EQU=0D, PRI=0E.

La synthèse FPGA et les mesures de fréquence/consommation nécessitent Vivado et une
carte, absents de l'environnement. Les sources RTL restent simulables avec GHDL/Vivado.


L'extension logicielle accepte aussi des fonctions sans paramètres :
`int triple() { return 3 * 3; }`. Les opcodes CALL/RET sont compris par le compilateur
et l'interpréteur ; leur intégration RTL reste une extension matérielle distincte.
