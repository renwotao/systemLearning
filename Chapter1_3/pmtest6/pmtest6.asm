%include "pm.inc"

; 页目录及页表地址
PageDirBase	equ	200000h ; 页目录开始地址：2M
PageTblBase	equ	201000h ; 页表开始地址：2M+4K

org 0100h
	jmp LABEL_BEGIN
[SECTION .gdt]

; Descriptor                  Base,    Limit,            Attribute
LABEL_GDT:         Descriptor 0,       0,                0
LABEL_DESC_NORMAL: Descriptor 0,       0ffffh,           DA_DRW
LABEL_DESC_CODE32: Descriptor 0,       SegCode32Len - 1, DA_C + DA_32
LABEL_DESC_CODE16: Descriptor 0,       0ffffh,           DA_C 
LABEL_DESC_DATA:   Descriptor 0,       DataLen - 1,      DA_DRW
LABEL_DESC_STACK:  Descriptor 0,       TopOfStack,       DA_DRWA + DA_32
LABEL_DESC_TEST:   Descriptor 0500000h,0ffffh,           DA_DRW
LABEL_DESC_VIDEO:  Descriptor 0B8000h, 0ffffh,           DA_DRW
LABEL_DESC_PAGE_DIR:Descriptor PageDirBase, 4095, 	 DA_DRW
LABEL_DESC_PAGE_TBL:Descriptor PageTblBase, 1023, 	 DA_DRW|DA_LIMIT_4K
; GDT结束

GdtLen equ $ - LABEL_GDT ; GDT长度
GdtPtr dw  GdtLen - 1    ; GDT界限
       dd  0             ; GDT基地址


; GDT选择子，就是在Descriptor数组中的索引
SelectorNormal  equ LABEL_DESC_NORMAL   -       LABEL_GDT
SelectorCode32	equ LABEL_DESC_CODE32	-	LABEL_GDT
SelectorCode16  equ LABEL_DESC_CODE16   -	LABEL_GDT
SelectorData  	equ LABEL_DESC_DATA	-	LABEL_GDT
SelectorStack	equ LABEL_DESC_STACK	-	LABEL_GDT
SelectorTest	equ LABEL_DESC_TEST	-	LABEL_GDT
SelectorVideo 	equ LABEL_DESC_VIDEO	-	LABEL_GDT
SelectorPageDir equ LABEL_DESC_PAGE_DIR	-	LABEL_GDT
SelectorPageTbl equ LABEL_DESC_PAGE_TBL	-	LABEL_GDT
; 选择子结束


 
[SECTION .data1]
ALIGN 32
[BITS 32]
LABEL_DATA:
SPValueInRealMode	dw	0
PMMessage		db	"In Protect Mode. ^-^", 0
OffsetPMMessage		equ 	PMMessage - $$
DataLen			equ 	$ - LABEL_DATA

;全局堆栈段
[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
	times 512 db 0
TopOfStack	equ	$ - LABEL_STACK - 1


[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov 	es, ax
	mov	ss, ax
	mov 	sp, 0100h
	
	mov	[LABEL_GO_BACK_TO_REAL + 3], ax
	mov	[SPValueInRealMode], sp
	
	; 初始化 16 位 代码段描述符
	mov	ax, cs
	movzx	eax,ax
	shl	eax, 4
	add	eax, LABEL_SEG_CODE16
	mov	word [LABEL_DESC_CODE16 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE16 + 4], al
	mov 	byte [LABEL_DESC_CODE16 + 7], ah

	; 初始化32位代码段描述符
	xor	eax, eax
	mov 	ax, cs
	shl	eax, 4
	add 	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr 	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov 	byte [LABEL_DESC_CODE32 + 7], ah
	
	; 初始化数据段描述符
	xor	eax, eax
	mov 	ax, ds
	shl	eax, 4
	add	eax, LABEL_DATA
	mov	word [LABEL_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_DATA + 4], al
	mov	byte [LABEL_DESC_DATA + 7], ah

	; 初始化堆栈段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK
	mov	word [LABEL_DESC_STACK + 2], ax
	shr	eax, 16
	mov 	byte [LABEL_DESC_STACK + 4], al
	mov 	byte [LABEL_DESC_STACK + 7], ah

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
	jmp	dword SelectorCode32:0 ; 执行这一句会把SelectorCode32装入cs，					 ; 并跳转到 Code32Selector:0处


LABEL_REAL_ENTRY:
	mov	ax, cs
	mov	ds, ax
	mov 	es, ax
	mov	ss, ax
	mov 	sp, [SPValueInRealMode]
	
	in	al, 92h
	and	al, 11111101b ; 关闭 A20 地址线
	out	92h, al
	
	sti                   ; 开中断
	
	mov 	ax, 4c00h
	int	21h           ; 回到 DOS

; 结束

[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
	call	SetupPaging
		
	mov	ax, SelectorData
	mov	ds, ax
	mov	ax, SelectorTest
	mov	es, ax
	mov 	ax, SelectorVideo
	mov	gs, ax
	
	mov	ax, SelectorStack
	mov 	ss, ax
	mov	esp,TopOfStack
	
	mov	ah, 0ch
	xor	esi,esi
	xor	edi,edi
	mov 	esi,OffsetPMMessage
	mov	edi, (80 * 10 + 0) * 2
	cld
	
.1:	
	lodsb
	test	al, al
	jz	.2
	mov	[gs:edi], ax
	add	edi, 2
	jmp 	.1

.2:			
	jmp	SelectorCode16:0
	
; 启动分页机制
SetupPaging:
	; 为了简化处理，所有线性地址对应相等的物理地址
	
	; 首先初始化页目录
	mov	ax, SelectorPageDir
	mov	es, ax
	mov	ecx, 1024
	xor	edi, edi
	xor	eax, eax
	mov	eax, PageTblBase |PG_P |PG_USU |PG_RWW
.1:
	stosd
	add 	eax, 4096
	loop	.1
	
	; 再初始化所有页表 (1k 个，4M 内存空间)
	mov	ax, SelectorPageTbl
	mov	es, ax
	mov	ecx, 1024 * 1024
	xor	edi, edi
	xor	eax, eax
	mov	eax, PG_P | PG_USU |PG_RWW
 	
.2:
	stosd
	add	eax, 4096
	loop	.2

	mov	eax, PageDirBase
	mov	cr3, eax
	mov	eax, cr0
	or	eax, 80000000h ; cr0 的 bit31 为 PG 设置为 1 
	mov	cr0, eax
	jmp	short .3
.3:
	nop
	
	ret
; 分页机制启动完毕

SegCode32Len	equ	$ - LABEL_SEG_CODE32

; 16 位代码段，由 32 位代码段跳入，跳出后到实模式
[SECTION .s16code]
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
	; 跳回实模式
	mov	ax, SelectorNormal
	mov	ds, ax
	mov 	es, ax
	mov 	fs, ax
	mov	gs, ax
	mov	ss, ax
	
	mov	eax, cr0
	and	eax, 7FFFFFFEh ; PE=0, PG=0
	mov	cr0, eax
	
LABEL_GO_BACK_TO_REAL:
	jmp	0:LABEL_REAL_ENTRY

Code16Len	equ	$ - LABEL_SEG_CODE16

