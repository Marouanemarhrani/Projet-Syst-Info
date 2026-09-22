CC=gcc
CFLAGS=-std=gnu11 -Wall -Wextra -Wpedantic -O2
all: bin/compiler bin/interpreter
build:
	mkdir -p build bin
build/parser.tab.c build/parser.tab.h: compiler/parser/parser.y | build
	bison -Wall -d -o build/parser.tab.c $<
build/lex.yy.c: compiler/lexer/lexer.l build/parser.tab.h | build
	flex -o $@ $<
bin/compiler: build/parser.tab.c build/lex.yy.c | build
	$(CC) $(CFLAGS) -Ibuild $^ -o $@
bin/interpreter: compiler/interpreter/interpreter.c | build
	$(CC) $(CFLAGS) $< -o $@
test: all
	bin/compiler tests/fixtures/control.c build/control >/dev/null
	bin/interpreter build/control.obj | diff -u tests/expected/control.txt -
clean:
	rm -rf build bin

cross: all
	bin/compiler tests/fixtures/control.c build/control >/dev/null
	python3 compiler/assembler/cross_assembler.py build/control.obj build/control.hex

hardware-test:
	@command -v ghdl >/dev/null || (echo "ghdl absent: RTL prête pour simulation Vivado/GHDL"; exit 0)
	ghdl -a --std=08 microprocessor/rtl/*.vhd microprocessor/tb/*.vhd
	ghdl -e --std=08 risc_pipeline_tb
	ghdl -r --std=08 risc_pipeline_tb --assert-level=error
