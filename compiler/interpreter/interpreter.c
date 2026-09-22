#include <stdio.h>
#include <stdlib.h>

enum {
    ADD = 1, MUL, SOU, DIV, COP, AFC, JMP, JMF,
    INF, SUP, EQU, PRI, ADR, LDP, STP, CALL, RET
};

typedef struct {
    int opcode;
    int a;
    int b;
    int c;
} Instruction;

enum { MEMORY_SIZE = 256, PROGRAM_SIZE = 8192, STACK_SIZE = 64 };

static int valid_address(int address) {
    return address >= 0 && address < MEMORY_SIZE;
}

static int operand_count(int opcode) {
    switch (opcode) {
        case ADD: case MUL: case SOU: case DIV:
        case INF: case SUP: case EQU:
        case ADR: case LDP: case STP:
            return 3;
        case AFC: case COP: case JMF: case CALL:
            return 2;
        case JMP: case PRI: case RET:
            return 1;
        default:
            return -1;
    }
}

static int load_program(const char *path, Instruction *program) {
    FILE *file = fopen(path, "r");
    if (!file) {
        perror(path);
        return -1;
    }

    int count = 0;
    while (count < PROGRAM_SIZE && fscanf(file, "%d", &program[count].opcode) == 1) {
        int operands = operand_count(program[count].opcode);
        if (operands < 0 ||
            fscanf(file, "%d", &program[count].a) != 1 ||
            (operands > 1 && fscanf(file, "%d", &program[count].b) != 1) ||
            (operands > 2 && fscanf(file, "%d", &program[count].c) != 1)) {
            fprintf(stderr, "Instruction invalide à la ligne %d\n", count + 1);
            fclose(file);
            return -1;
        }
        count++;
    }

    fclose(file);
    return count;
}

static int check_address(int address, int pc) {
    if (!valid_address(address)) {
        fprintf(stderr, "Adresse mémoire invalide %d à l'instruction %d\n", address, pc);
        return 0;
    }
    return 1;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s programme.obj\n", argv[0]);
        return EXIT_FAILURE;
    }

    Instruction program[PROGRAM_SIZE];
    long memory[MEMORY_SIZE] = {0};
    int return_pc[STACK_SIZE];
    int return_destination[STACK_SIZE];
    int stack_pointer = 0;

    int program_size = load_program(argv[1], program);
    if (program_size < 0) {
        return EXIT_FAILURE;
    }

    for (int pc = 0; pc < program_size; pc++) {
        Instruction instruction = program[pc];

        if (instruction.opcode == ADD || instruction.opcode == MUL ||
            instruction.opcode == SOU || instruction.opcode == DIV ||
            instruction.opcode == INF || instruction.opcode == SUP ||
            instruction.opcode == EQU) {
            if (!check_address(instruction.a, pc) ||
                !check_address(instruction.b, pc) ||
                !check_address(instruction.c, pc)) return EXIT_FAILURE;
        }

        switch (instruction.opcode) {
            case ADD: memory[instruction.a] = memory[instruction.b] + memory[instruction.c]; break;
            case MUL: memory[instruction.a] = memory[instruction.b] * memory[instruction.c]; break;
            case SOU: memory[instruction.a] = memory[instruction.b] - memory[instruction.c]; break;
            case DIV:
                if (memory[instruction.c] == 0) {
                    fprintf(stderr, "Division par zéro à l'instruction %d\n", pc);
                    return EXIT_FAILURE;
                }
                memory[instruction.a] = memory[instruction.b] / memory[instruction.c];
                break;
            case COP:
                if (!check_address(instruction.a, pc) || !check_address(instruction.b, pc)) return EXIT_FAILURE;
                memory[instruction.a] = memory[instruction.b];
                break;
            case AFC:
                if (!check_address(instruction.a, pc)) return EXIT_FAILURE;
                memory[instruction.a] = instruction.b;
                break;
            case ADR:
                if (!check_address(instruction.a, pc) || !check_address(instruction.b, pc)) return EXIT_FAILURE;
                memory[instruction.a] = instruction.b;
                break;
            case LDP:
                if (!check_address(instruction.a, pc) || !check_address(instruction.b, pc) ||
                    !check_address((int)memory[instruction.b], pc)) return EXIT_FAILURE;
                memory[instruction.a] = memory[memory[instruction.b]];
                break;
            case STP:
                if (!check_address(instruction.a, pc) || !check_address(instruction.b, pc) ||
                    !check_address((int)memory[instruction.a], pc)) return EXIT_FAILURE;
                memory[memory[instruction.a]] = memory[instruction.b];
                break;
            case JMP:
                if (instruction.a < 0 || instruction.a > program_size) {
                    fprintf(stderr, "Saut invalide à l'instruction %d\n", pc);
                    return EXIT_FAILURE;
                }
                pc = instruction.a - 1;
                break;
            case JMF:
                if (!check_address(instruction.a, pc) ||
                    instruction.b < 0 || instruction.b > program_size) {
                    fprintf(stderr, "Saut conditionnel invalide à l'instruction %d\n", pc);
                    return EXIT_FAILURE;
                }
                if (memory[instruction.a] == 0) pc = instruction.b - 1;
                break;
            case INF: memory[instruction.a] = memory[instruction.b] < memory[instruction.c]; break;
            case SUP: memory[instruction.a] = memory[instruction.b] > memory[instruction.c]; break;
            case EQU: memory[instruction.a] = memory[instruction.b] == memory[instruction.c]; break;
            case PRI:
                if (!check_address(instruction.a, pc)) return EXIT_FAILURE;
                printf("%ld\n", memory[instruction.a]);
                break;
            case CALL:
                if (stack_pointer >= STACK_SIZE ||
                    instruction.b < 0 || instruction.b > program_size ||
                    !check_address(instruction.a, pc)) {
                    fprintf(stderr, "Appel de fonction invalide à l'instruction %d\n", pc);
                    return EXIT_FAILURE;
                }
                return_pc[stack_pointer] = pc;
                return_destination[stack_pointer++] = instruction.a;
                pc = instruction.b - 1;
                break;
            case RET:
                if (stack_pointer == 0 || !check_address(instruction.a, pc)) {
                    fprintf(stderr, "Retour de fonction invalide à l'instruction %d\n", pc);
                    return EXIT_FAILURE;
                }
                memory[return_destination[--stack_pointer]] = memory[instruction.a];
                pc = return_pc[stack_pointer];
                break;
            default:
                fprintf(stderr, "Opcode inconnu %d à l'instruction %d\n", instruction.opcode, pc);
                return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}
