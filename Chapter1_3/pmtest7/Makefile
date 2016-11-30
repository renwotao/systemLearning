pmtest7.com : pmtest7.asm pm.inc
	nasm pmtest7.asm -o pmtest7.com

.PHONY : everything

everything :
	sudo mount -o loop pm.img /mnt/floppy
	sudo rm /mnt/floppy/*.*
	sudo cp pmtest7.com /mnt/floppy
	sudo umount /mnt/floppy


