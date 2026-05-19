CC = gcc
NASM = nasm
CFLAGS_BASE = -O3 -Wall
ASMFLAGS = -f elf64

INPUT = test.png
OUTPUT = result.png
COORDS = 100 100 800 800

OPTS = -O0 -O1 -O2 -O3 -Ofast

.PHONY: all clean run_tests run

all: crop_app

main.o: main.c
	$(CC) $(CFLAGS_BASE) -c main.c -o main.o

crop_asm.o: crop_asm.s
	$(NASM) $(ASMFLAGS) crop_asm.s -o crop_asm.o

crop_c.o: crop_c.c
	$(CC) $(CFLAGS_BASE) -c crop_c.c -o crop_c.o

crop_app: main.o crop_c.o crop_asm.o
	$(CC) main.o crop_c.o crop_asm.o -lm -o crop_app

run: crop_app
	@echo "Запуск программы с базовой оптимизацией..."
	./crop_app $(INPUT) $(OUTPUT) $(COORDS)

run_tests: main.o crop_asm.o
	@for opt in $(OPTS); do \
		echo "======================================"; \
		echo "Оптимизация: $$opt"; \
		$(CC) $$opt -c crop_c.c -o crop_c.o; \
		$(CC) main.o crop_c.o crop_asm.o -lm -o crop_app; \
		./crop_app $(INPUT) $(OUTPUT) $(COORDS); \
	done

clean:
	rm -f *.o crop_app $(OUTPUT)
