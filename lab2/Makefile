AS = /usr/bin/nasm
LD = /usr/bin/ld

ASFLAGS = -g -f elf64 #-D SORT_ASCENDING 
LDFLAGS = -static

SRCS = lab2.s
OBJS = $(SRCS:.s=.o)

EXE = lab2

all: $(SRCS) $(EXE)

clean:
	rm -rf $(EXE) $(OBJS)

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@

.s.o:
	$(AS) $(ASFLAGS) $< -o $@














