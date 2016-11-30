pmtest6.com : pmtest6.asm pm.inc
	nasm pmtest6.asm -o pmtest6.com

.PHONY : everything

everything :
	sudo mount -o loop pm.img /mnt/floppy
	sudo rm /mnt/floppy/*.*
	sudo cp pmtest6.com /mnt/floppy
	sudo umount /mnt/floppy


