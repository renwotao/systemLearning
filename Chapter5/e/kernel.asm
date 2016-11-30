; $ nasm -f elf kernel.asm -o  kernel.o
; $ ld -s kernel.o -o kernel.bin 	# '-s'选项意为"strip all"

[section .text]

global _start

_start:
	mov	ah, 0Fh			; 0000:黑底 1111:白字
	mov	al, 'K'
	mov	[gs:((80 * 1 + 39) * 2)], ax
	jmp 	$
