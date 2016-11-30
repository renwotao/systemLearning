%include "pm.inc"

org 07c00h
	jmp LABEL_BEGIN
[SECTION .gdt]

; Descriptor Base, Limit, Attribute
LABEL_GDT:         Descriptor 0,       0,                0
LABEL_DESC_CODE32: Descriptor 0,       SegCode32Len - 1, DA_C + DA_32
LABEL_DESC_VIDEO:  Descriptor 0B8000h, 0ffffh,           DA_DRW
; GDT结束

GdtLen equ $ - LABEL_GDT ; GDT长度
GdtPtr dw  GdtLen - 1    ; GDT界限
       dd  0             ; GDT基地址

; GDT选择子，就是在Descriptor数组中的索引
SelectorCode32	equ LABEL_DESC_CODE32	-	LABEL_GDT
SelectorVideo 	equ LABEL_DESC_VIDEO	-	LABEL_GDT
; SECTION结束

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov 	es, ax
	mov	ss, ax
	mov 	sp, 0100h
	
	; 初始化32位代码段描述符
	xor	eax, eax
	mov 	ax, cs
	shl	eax, 4
	add 	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr 	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov 	byte [LABEL_DESC_CODE32 + 7], ah
	
	; 为加载 GDTR 作准备
	xor 	eax, eax
	mov 	ax, ds
	shl	eax, 4
	add 	eax, LABEL_GDT
	mov 	dword [GdtPtr + 2], eax ; 保存GDT基地址
	
	; 加载 GDTR
	lgdt [GdtPtr]
	
	; 关中断
	cli
	
	; 打开地址线A20
	in 	al, 92h
	or	al, 00000010b
	out 	92h, al
	
	; 准备切换到保护模式
	mov	eax, cr0
	or 	eax, 1
	mov 	cr0, eax ; 保护模式cr0指定位为1
	
	; 真正进入保护模式
	jmp	dword SelectorCode32:0 ; 执行这一句会把SelectorCode32装入cs，					   ; 并跳转到 Code32Selector:0处
; 结束

[SECTION .s32]
[BITS 32]

LABEL_SEG_CODE32:
	mov 	ax, SelectorVideo
	mov	gs, ax
	mov	edi, (80 * 11 + 79) * 2 ;屏幕第11行，第79列
	mov 	ah, 0ch
	mov 	al, 'P'
	mov	[gs:edi], ax
	
	jmp	$

SegCode32Len	equ	$ - LABEL_SEG_CODE32

