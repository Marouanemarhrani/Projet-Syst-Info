# Projet Systèmes Informatiques — Du compilateur vers le microprocesseur

Compilateur Flex/Bison d'un sous-ensemble du C vers un assembleur orienté mémoire, avec interpréteur du format numérique généré.

Fonctionnalités : déclarations int/const, constantes exponentielles, expressions, affectations, comparaisons, printf, if/else, while et diagnostics de compilation.

## Utilisation

Prérequis : gcc, flex, bison et make.

    make
    bin/compiler tests/fixtures/control.c build/control
    bin/interpreter build/control.obj
    make test

Le fichier ASM est lisible par un humain et le OBJ contient les instructions numériques exécutées par l'interpréteur.
