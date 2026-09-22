# Projet Systèmes Informatiques : Du compilateur vers le microprocesseur

Compilateur Flex/Bison d'un sous-ensemble du C vers un assembleur orienté mémoire, avec interpréteur du format numérique généré.

Fonctionnalités : déclarations int/const, constantes exponentielles, expressions, affectations, comparaisons, printf, if/else, while, pointeurs, fonctions sans paramètres et diagnostics de compilation.

## Utilisation

Prérequis : gcc, flex, bison et make.

    make
    bin/compiler tests/fixtures/control.c build/control
    bin/interpreter build/control.obj
    make test

Le fichier ASM est lisible par un humain et le OBJ contient les instructions numériques exécutées par l'interpréteur.


## Volet RISC et matériel

Le cross-assembleur et les sources VHDL sont dans `compiler/assembler/` et
`microprocessor/`. Pour générer le programme RISC :

    make cross

Pour lancer la simulation VHDL :

    make hardware-test

La checklist détaillée du sujet est disponible dans `docs/TP_CHECKLIST.md`.

La CI GitHub exécute automatiquement la compilation, les tests logiciels et le cross-assemblage.


Les extensions pointeurs et fonctions sans paramètres sont également couvertes côté
compilateur/interpréteur et disposent de tests dédiés.
