AS = /usr/bin/nasm
LD = /usr/bin/ld

ASFLAGS = -g -f elf64
LDFLAGS = -static

SRCS = lab2.s
OBJS = $(SRCS:.s=.o)

EXE = program

ifeq ($(SORT),ascending)
    ASFLAGS += -DSORT_ASCENDING
    EXE := program_asc
else
    EXE := program_desc
endif

all: $(EXE)

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

clean:
	rm -rf $(OBJS) program_asc program_desc

ascending:
	$(MAKE) all SORT=ascending

descending:
	$(MAKE) all SORT=descending

.PHONY: all clean ascending descending
