BaseOfLoader	equ	09000h ; LOADER.BIN 被加载到的位置
OffsetOfLoader	equ	0100h  ; LOADER.BIN 

BaseOfLoaderPhyAddr	equ	BaseOfLoader*10h ; LOADER.BIN 被加载的物理位置

BaseOfKernelFile	equ	08000h
OffsetOfKernelFile	equ	0h

BaseOfKernelFilePhyAddr	equ	BaseOfKernelFile * 10h
KernelEntryPointPhyAddr	equ	030400h	; 注意：1、必须与 MAKEFILE 中参数 -Ttext 的值相等!!
					;       2、这是个地址而非仅仅是个偏移，如果 -Ttext 的值为 0x400400，则它的值也应该是 0x400400。

PageDirBase		equ	200000h	; 页目录开始地址:		2M
PageTblBase		equ	201000h	; 页表开始地址:			2M + 4K

