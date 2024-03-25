AS=nasm
ASFLAGS=-f elf64 -g
LD=g++
LDFLAGS= -no-pie -m64 -z noexecstack
ASSRC=$(wildcard *.asm)
CSRC=$(wildcard *.cpp)
ASOBJ=$(ASSRC:.asm=.o)
COBJ=$(CSRC:.cpp=.o)
EXECUTABLE=play

all: $(EXECUTABLE)

$(EXECUTABLE): $(ASOBJ) $(COBJ)
	$(LD) $(LDFLAGS) $(ASOBJ) $(COBJ) -o $(EXECUTABLE)

$(COBJ): $(CSRC)
	$(LD) -c -o $@ $<

$(ASOBJ): $(ASSRC)
	$(AS) $(ASFLAGS) $(ASSRC)

clean:
	rm -rf *o $(EXECUTABLE)
