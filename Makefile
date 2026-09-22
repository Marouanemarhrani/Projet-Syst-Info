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
	bin/compiler tests/fixtures/pointer.c build/pointer >/dev/null
	bin/interpreter build/pointer.obj | diff -u tests/expected/pointer.txt -
	python3 compiler/assembler/cross_assembler.py build/pointer.obj build/pointer.hex >/dev/null
	bin/compiler tests/fixtures/function.c build/function >/dev/null
	bin/interpreter build/function.obj | diff -u tests/expected/function.txt -
	python3 compiler/assembler/cross_assembler.py build/function.obj build/function.hex >/dev/null
	bin/compiler tests/fixtures/expressions.c build/expressions >/dev/null
	bin/interpreter build/expressions.obj | diff -u tests/expected/expressions.txt -
	if bin/compiler tests/fixtures/invalid_constant.c build/invalid_constant >/dev/null 2>&1; then echo "Une affectation de constante a été acceptée"; exit 1; fi
	bin/compiler tests/fixtures/division_zero.c build/division_zero >/dev/null
	if bin/interpreter build/division_zero.obj >/dev/null 2>&1; then echo "Une division par zéro a été acceptée"; exit 1; fi
clean:
	rm -rf build bin

cross: all
	bin/compiler tests/fixtures/control.c build/control >/dev/null
	python3 compiler/assembler/cross_assembler.py build/control.obj build/control.hex

hardware-test:
	@if command -v ghdl >/dev/null; then \
		ghdl -a --std=08 microprocessor/rtl/*.vhd microprocessor/tb/*.vhd && \
		ghdl -e --std=08 risc_pipeline_tb && \
		ghdl -r --std=08 risc_pipeline_tb --assert-level=error; \
	else \
		echo "ghdl absent: RTL prête pour simulation Vivado/GHDL"; \
	fi
