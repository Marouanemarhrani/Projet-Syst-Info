# Checklist du TP

## Partie compilateur Flex/Bison

- [x] Reconnaissance de main, blocs et déclarations int/const
- [x] Déclarations multiples et initialisations
- [x] Identifiants, entiers décimaux et exponentiels
- [x] Expressions +, -, *, / et parenthèses
- [x] Affectations et printf
- [x] Génération assembleur orienté mémoire lisible
- [x] Génération du format numérique
- [x] Interpréteur assembleur
- [x] Diagnostics principaux
- [x] if / else, while et comparaisons

## Cross-assembleur

- [x] Format RISC fixe de 4 octets
- [x] Traduction des instructions mémoire vers registres
- [x] Traduction LOAD / STORE avec registres temporaires
- [x] Traduction des sauts et comparaisons
- [x] Sorties hexadécimale et lisible
- [ ] Validation FPGA

## Microprocesseur RISC VHDL

- [x] UAL 8 bits et drapeaux N/O/Z/C
- [x] Banc de 16 registres, double lecture, écriture et bypass
- [x] Mémoire de données synchrone
- [x] Mémoire d'instructions ROM
- [x] Chemin de données et contrôle
- [x] Pipeline 5 étages
- [x] Instructions arithmétiques, COP, AFC, LOAD, STORE
- [ ] Extension saut/comparaison dans le RTL (présente dans le format cross-assemblé, à finaliser matériellement)
- [x] Détection simple des aléas
- [ ] Synthèse Xilinx et mesure fréquence/consommation

## Validation

- [x] Tests logiciel
- [x] Programme RISC de démonstration
- [ ] Simulation du testbench VHDL (GHDL absent dans l'environnement)
- [x] Pointeurs côté compilateur/interpréteur/cross-assembleur
- [ ] Fonctions utilisateur (extension facultative du sujet)
