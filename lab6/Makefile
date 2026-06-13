CC = gcc
ASM = nasm

CFLAGS = -Wall -g -O2 
LDFLAGS = -lm -Wl,-z,noexecstack
ASMFLAGS = -f elf64 -g

all: run_sobel run_timing

run_sobel: main.c sobel_c.c sobel_asm.o sobel_simd.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

run_timing: timing.c sobel_c.c sobel_asm.o sobel_simd.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

sobel_asm.o: sobel_asm.s
	$(ASM) $(ASMFLAGS) $< -o $@

sobel_simd.o: sobel_simd.s
	$(ASM) $(ASMFLAGS) $< -o $@

clean:
	rm -f *.o run_sobel run_timing
