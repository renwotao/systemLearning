pmtest9.com : pmtest9.asm pm.inc
	nasm pmtest9.asm -o pmtest9.com

.PHONY : everything

everything :
	sudo mount -o loop pm.img /mnt/floppy
	sudo rm /mnt/floppy/*.*
	sudo cp pmtest9.com /mnt/floppy
	sudo umount /mnt/floppy
	echo $?	#[ $? != 0 ] && echo "error" || echo "right"


