BaseOfLoader	equ	09000h ; LOADER.BIN 被加载到的位置
OffsetOfLoader	equ	0100h  ; LOADER.BIN 

BaseOfLoaderPhyAddr	equ	BaseOfLoader*10h ; LOADER.BIN 被加载的物理位置
BaseOfKernelFile	equ	08000h
OffsetOfKernelFile	equ	0h
