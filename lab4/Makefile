AS = /usr/bin/nasm
#LD = /usr/bin/ld
CC = /usr/bin/gcc


ASFLAGS = -g -f elf64

# не -static
LDFLAGS = -no-pie
LIBS = -lm

SRCS = lab4.asm
OBJS = $(SRCS:.asm=.o)

EXE = program
TEST_OUT = result.txt

all: $(EXE)

$(EXE): $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@ $(LIBS)

%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@

run: $(EXE)
	./$(EXE) $(TEST_OUT)
	@echo "\nРезультат записан в $(TEST_OUT):"

clean:
	rm -rf $(OBJS) $(EXE) $(TEST_OUT)

.PHONY: all clean run
