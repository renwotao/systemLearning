boot.bin:boot.asm
	nasm boot.asm -o boot.bin

.PHONY: everything

everything:
	dd if=boot.bin of=a.img bs=512 count=1 conv=notrunc
