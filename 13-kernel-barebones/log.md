the sequence of commands that i ran

x86_64-elf-gcc -ffreestanding -c kernel.c -o kernel.o
nasm kernel_entry.asm -f elf -o kernel_entry.o
x86_64-elf-ld -o kernel.bin -Ttext 0x1000 kernel_entry.o kernel.o --oformat binary

then i recieved

x86_64-elf-ld: i386 architecture of input file `kernel_entry.o' is incompatible with i386:x86-64 output
x86_64-elf-ld: warning: cannot find entry symbol _start; defaulting to 0000000000001000

Now im using 

x86_64-elf-gcc -m32 -c kernel.c -o kernel.o # use a flag to generate 32 bit machine code
x86_64-elf-ld -m elf_i386 -o kernel.bin kernel_entry.o kernel.o --oformat binary # link as 32-bit executable
qemu-system-i386 os-image.bin

qemu-system-i386 -s -S os-image.bin