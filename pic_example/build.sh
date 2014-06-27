export PATH=$PATH:/home/tomi/zylin_cpu/new/bin
zpu-elf-gcc -O3 -phi `pwd`/int.c -o int.elf -Wl,--relax -Wl,--gc-sections  -g
zpu-elf-objdump --disassemble-all >int.dis int.elf
zpu-elf-objcopy -O binary int.elf int.bin
zpuromcoegen int.bin int.coe