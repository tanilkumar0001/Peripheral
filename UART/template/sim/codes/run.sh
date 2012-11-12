corea-elf-as $1.s -o $1.o
corea-elf-ld $1.o -o $1 -e main

corea-elf-objcopy -O binary $1 $1.bin
corea-elf-objdump -D $1 > $1.dis

./B2H_CONVERTER $1.bin $1.hex
