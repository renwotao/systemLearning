;%define	_BOOT_DEBUG_

%ifdef	_BOOT_DEBUG_
	org	0100h		;调试状态，作成 .COM 文件，可调试
%else
	org	07c00h		; Boot 状态，Bios 将把 Boot Sector 加载到 0:7c00 处开始执行
%endif
;======================================================================
%ifdef	_BOOT_DEBUG_
BaseOfStack	equ	0100h
%else
BaseOfStack	equ	07c00h
%endif

BaseOfLoader	equ	09000h  ; LOADER.BIN 被加载到的位置 --- 段地址
OffsetOfLoader	equ	0100h	; LOADER.BIN 被加载到的位置 --- 偏移地址

RootDirSectors	equ	14	; 根目录占用空间
SectorNoOfRootDirectory	equ	19	; Root Directory 的第一个扇区
SectorNoOfFAT1	equ	1	; FAT1 的第一个扇区号 = BPB——RsvdSecCnt
DeltaSectorNo	equ	17	; DeltaSectorNo = BPB_RsvdSecCnt + (BPB_NumFATs * FATSz) -2
; 文件的开始Sector号 = DirEntry中的开始Sector号 + 根目录占用Sector书目 + DeltaSectorNo
;======================================================================
	; Dos 可识别引导形式
	jmp	short LABEL_START	; Start to boot.
	nop				; nop 不可少？

	; FAT12 磁盘的头
	%include "fat12hdr.h"

LABEL_START:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, BaseOfStack
	
	; 清屏
	mov	ax, 0600h	; AH = 6, AL = 0h
	mov	bx, 0700h	; 黑底白字(BL = 07h)
	mov	cx, 0		; 左上角:(0, 0)
	mov	dx, 0184fh	; 右下角:(80, 50)
	int 	10h
	
	mov	dh, 0		; "Booting  "
	call	DispStr		; 显示字符串
	
	; 软驱复位
	xor	ah, ah
	xor	dl, dl
	int 	13h
; 在 A 盘的根目录找 LOADER.BIN
	mov	word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0
	jz	LABEL_NO_LOADERBIN
	dec	word [wRootDirSizeForLoop]
	mov	ax, BaseOfLoader
	mov	es, ax
	mov	bx, OffsetOfLoader
	mov	ax, [wSectorNo]
	mov	cl, 1
	call	ReadSector	
	
	mov 	si, LoaderFileName		; ds:si -> "LOADER  BIN"
	mov	di, OffsetOfLoader		; es:di -> BaseOfLoader:0100
	cld
	mov	dx, 10h
LABEL_SEARCH_FOR_LOADERBIN:
	cmp	dx, 0
	jz	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
	dec	dx
	mov	cx, 11
LABEL_CMP_FILENAME:
	cmp 	cx, 0
	jz	LABEL_FILENAME_FOUND
	dec	cx
	lodsb
	cmp	al, byte [es:di]
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT

LABEL_GO_ON:
	inc	di
	jmp	LABEL_CMP_FILENAME

LABEL_DIFFERENT:
	and	di, 0FFE0h
	add	di, 20h
	mov	si, LoaderFileName
	jmp	LABEL_SEARCH_FOR_LOADERBIN

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov 	dh, 2		; "No LOADER."
	call	DispStr
%ifdef	_BOOT_DEBUG_
	mov	ax, 4c00h
	int 	21h		; 没有找到 LOADER.BIN，回到 DOS
%else
	jmp 	$		; 没有找到 LOADER.BIN，死循环在这里
%endif

LABEL_FILENAME_FOUND:
	mov	ax, RootDirSectors	; 代码暂停在这里
	and 	di, 0FFE0h		; di -> 当前条目的开始
	add	di, 01Ah		; di -> 首 Sector
	mov	cx, word [es:di]		
	push	cx			; 保存此 Sector 在FAT中的序号
	add	cx, ax
	add	cx, DeltaSectorNo	; cl <- LOADER.BIN 的起始扇区号
	mov 	ax, BaseOfLoader
	mov	es, ax			
	mov	bx, OffsetOfLoader	
	mov	ax, cx

LABEL_GOON_LOADING_FILE:
	push	ax
	push	bx
	mov	ah, 0Eh
	mov	al, '.'
	mov	bl, 0Fh
	int 	10h
	pop	bx
	pop	ax		; 每读一个扇区就在 "Booting "后面打一个点

	mov 	cl, 1
	call	ReadSector
	pop	ax
	call	GetFATEntry
	cmp	ax, 0FFFh
	jz	LABEL_FILE_LOADED
	push	ax
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo
	add	bx, [BPB_BytsPerSec]
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:
	mov	dh, 1			; "Ready"
	call	DispStr			; 显示字符串
;*****************************************************************
	jmp	BaseOfLoader:OffsetOfLoader	; 这一句正式跳转到已加载到内
						; 存中的 LOADER.BIN 的开始处
						; 开始执行 LOADER.BIN 的代码
						; Boot Sector 的使命到此结束
;*****************************************************************

;=================================================================
; 变量
wRootDirSizeForLoop	dw	RootDirSectors  ; Root Directory占用的扇区数
					        ; 在循环中会递减至零
wSectorNo		dw 	0		; 要读取的扇区号
bOdd			db	0		; 奇数还是偶数

; 字符串
LoaderFileName		db	"LOADER  BIN", 0
; 为了简化代码，下面每个字符串的长度均为 MessageLength
MessageLength		equ	9
BootMessage:		db	"Booting  "
Message1		db	"Ready    "
Message2		db	"No LOADER"
;=================================================================

;-----------------------------------------------------------------
; 函数名：DispStr
; 作用：显示一个字符串，函数开始时 dh 中应该是字符串序号(0-baseed)
;-----------------------------------------------------------------	
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, BootMessage
	mov	bp, ax
	mov	ax, ds
	mov	es, ax			; ES:BP = 串地址
	mov	cx, MessageLength	; CX = 串长度
	mov	ax, 01301h		; AH = 13, AL = 01h
	mov	bx, 0007h		; 页号为 0 黑底白字
	mov	dl, 0
	int 	10h
	ret

;-----------------------------------------------------------------
; 函数名：ReadSector
; 作用：从第 ax 个 Sector 开始，将 cl 个 Sector 读如 es:bx 中
;-----------------------------------------------------------------
ReadSector:
	push	bp
	mov	bp, sp
	sub	esp, 2 			; 保存要读的扇区
	
	; 得到柱面号，起始扇区，磁头号
	mov	byte [bp - 2 ], cl
	push	bx
	mov	bl, [BPB_SecPerTrk]	; bl:除数
	div	bl			; 
	inc	ah
	mov	cl, ah
	mov	dh, al
	shr	al, 1
	mov	ch, al
	and	ch, al
	pop	bx
	
	mov	dl, [BS_DrvNum]
.GoOnReading:
	mov	ah, 2
	mov	al, byte [bp - 2]	; 读 al 个扇区
	int 	13h
	jc	.GoOnReading		; 如果读取错误，CF 会被置 1
					; 这时就不停地读，直到正确为止

	add 	esp, 2
	pop	bp

	ret
;---------------------------------------------------------------------
; 函数名： GetFATEntry
; 作用：找到序号为 ax 的 Sector 在FAT 中的条目，结果放在 ax 中需要注意的是
;	中间需要读FAT 的扇区到 es:bx 处， 所以函数一开始保存了 es 和bx
;---------------------------------------------------------------------
GetFATEntry:
	push	es
	push	bx
	push	ax
	mov	ax, BaseOfLoader
	sub	ax, 0100h
	mov	es, ax
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx
	mov	bx, 2
	div	bx
	cmp 	dx, 0
	jz	LABEL_EVEN
	mov	byte [bOdd], 1
LABEL_EVEN:
	; 现在 ax 中是 FATEntry 在 FAT 中的偏移量，下面来计算 FATEntry 在
	; 哪个扇区中(FAT 占用不止一个扇区)
	xor	dx, dx
	mov	bx, [BPB_BytsPerSec]	
	div	bx	; ax <- 商(FATEntry 所在的扇区相对于 FAT 的扇区号
			; dx <- 余数 (FATEntry 在扇区内的偏移)
	push 	dx
	mov	bx, 0
	add	ax, SectorNoOfFAT1 ; 此举之后的ax就是 FATEntry 所在的扇区号
	mov	cl, 2
	call	ReadSector	; 读取 FATEntry 所在的扇区,一次读两个，避免
				; 在边界发生错误，因为一个 FATEntry 可能跨越
				; 两个扇区

	pop	dx
	add	bx, dx
	mov	ax, [es:bx]
	cmp	byte [bOdd], 1
	jnz	LABEL_EVEN_2
	shr	ax, 4
LABEL_EVEN_2:
	and	ax, 0FFFh

LABEL_GET_FAT_ENRY_OK:
	pop	bx
	pop	es
	ret
;------------------------------------------------------------------------
	
times	510 - ($-$$)	db	0
dw	0xaa55
