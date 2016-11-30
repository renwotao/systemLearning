pmtest8.com : pmtest8.asm pm.inc
	nasm pmtest8.asm -o pmtest8.com

.PHONY : everything

everything :
	sudo mount -o loop pm.img /mnt/floppy
	sudo rm /mnt/floppy/*.*
	sudo cp pmtest8.com /mnt/floppy
	sudo umount /mnt/floppy


