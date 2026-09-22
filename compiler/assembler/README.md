# Cross-assembleur

`cross_assembler.py` traduit le format assembleur orienté mémoire produit par le compilateur vers des instructions RISC de quatre octets.

Usage :

    python3 compiler/assembler/cross_assembler.py build/control.obj build/control.hex

Le fichier `.hex` est destiné à la mémoire d instructions ; le fichier `.asm` associé est une version lisible pour le debug.
