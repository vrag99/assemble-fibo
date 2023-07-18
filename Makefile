fileName = fibonacci

all: $(fileName)
	./$(fileName)

$(fileName): $(fileName).o
	ld -o $(fileName) $(fileName).o

$(fileName).o: $(fileName).asm
	nasm -f elf64 $(fileName).asm

clean:
	rm $(fileName) $(fileName).o