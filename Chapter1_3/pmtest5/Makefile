pmtest5.com : pmtest5.asm pm.inc
	nasm pmtest5.asm -o pmtest5.com

.PHONY : everything

everything :
	sudo mount -o loop pm.img /mnt/floppy
	sudo cp pmtest5.com /mnt/floppy
	sudo umount /mnt/floppy


