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
LABEL_DESC_PAGE_TBL:Descriptor PageTblBase, 4096*8-1, 	 DA_DRW|DA_LIMIT_4K
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
; 实模式下使用这些符号
; 字符串
LABEL_DATA:
_szPMMessage:		db	"In Protect Mode now. ^-^", 0Ah, 0Ah, 0
_szMemChkTitle:		db	"BaseAddrL BaseAddrH LengthLow LengthHigh	type", 0Ah, 0
_szRAMSize		db 	"RAM size:", 0
_szReturn		db	0Ah, 0
; 变量
_wSPValueInRealMode	dw	0
_dwMCRNumber:		dd	0 ; Memory check result
_dwDispPos:		dd	(80 * 6 + 0) * 2
_dwMemSize:		dd	0
_ARDStruct:		; Address Range Descriptor structure
	_dwBaseAddrLow:	dd	0
	_dwBaseAddrHigh:dd	0
	_dwLengthLow:	dd	0
	_dwLengthHigh:	dd	0
	_dwType:	dd	0

_MemChkBuf:	times	256 	db 	0

; 保护模式下使用这些符号
szPMMessage		equ	_szPMMessage	- $$
szMemChkTitle		equ	_szMemChkTitle  - $$
szRAMSize		equ	_szRAMSize	- $$
szReturn		equ	_szReturn	- $$
dwDispPos		equ	_dwDispPos	- $$
dwMemSize		equ	_dwMemSize	- $$
dwMCRNumber		equ	_dwMCRNumber	- $$
ARDStruct		equ	_ARDStruct	- $$
	dwBaseAddrLow	equ	_dwBaseAddrLow	- $$
	dwBaseAddrHigh	equ	_dwBaseAddrHigh	- $$
	dwLengthLow	equ	_dwLengthLow	- $$
	dwLengthHigh	equ	_dwLengthHigh	- $$
	dwType		equ	_dwType		- $$
MemChkBuf		equ	_MemChkBuf	- $$

DataLen			equ	$ - LABEL_DATA
; END of [SECTION .data1]

;全局堆栈段
[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
	times 512 db 0
TopOfStack	equ	$ - LABEL_STACK - 1
; End of [SECTION .gs]

; 16 位代码段，实模式可跳入 32 位的保护模式
[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov 	es, ax
	mov	ss, ax
	mov 	sp, 0100h
	
	mov	[LABEL_GO_BACK_TO_REAL + 3], ax
	mov	[_wSPValueInRealMode], sp
	
	; 得到内存数
	mov	ebx, 0
	mov	di, _MemChkBuf
.loop:	
	mov	eax, 0E820h
	mov	ecx, 20
	mov	edx, 0534d4150h
	int 	15h
	jc	LABEL_MEM_CHK_FAIL
	add	di, 20
	inc 	dword [_dwMCRNumber]
	cmp	ebx, 0
	jne	.loop
	jmp	LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
	mov	dword [_dwMCRNumber], 0
LABEL_MEM_CHK_OK:
	
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
	mov 	sp, [_wSPValueInRealMode]
	
	in	al, 92h
	and	al, 11111101b ; 关闭 A20 地址线
	out	92h, al
	
	sti                   ; 开中断
	
	mov 	ax, 4c00h
	int	21h           ; 回到 DOS

; END of [SECTION .s16]

; 32 位代码段，由实模式跳入
[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
	call	SetupPaging
		
	mov	ax, SelectorData
	mov	ds, ax               ; 数据段选择子
	mov	ax, SelectorData
	mov	es, ax
	mov 	ax, SelectorVideo
	mov	gs, ax               ; 视频段选择子
	
	mov	ax, SelectorStack
	mov 	ss, ax               ; 堆栈段选择子
	mov	esp,TopOfStack
	
	; 下面显示一个字符串
	push 	szPMMessage
	call	DispStr
	add	esp, 4
	
	push	szMemChkTitle
	call	DispStr
	add	esp, 4
	
	call	DispMemSize	     ; 显示内存信息
	
	call	SetupPaging	     ; 启动分页机制

	; 到此结束		
	jmp 	SelectorCode16:0

; 启动分页机
SetupPaging:
	; 根据内存大小计算应初始化多少 PDE 以及多少页表
	xor	edx, edx
	mov	eax, [dwMemSize]
	mov	ebx, 400000h		; 400000h = 4M = 4096 * 1024，一个页表对应的内存大小
	div	ebx
	mov	ecx, eax		; 此时 ecx 为页表的个数
	test	edx, edx
	jz	.no_remainder
	inc	ecx            		; 如果余数不为 0 就需增加一个页表
.no_remainder:
	push	ecx			; 暂存页表个数
	
	; 为了简化处理，所有线性地址对应相等的物理地址. 并且不考虑内存空洞
	; 首先初始化页目录
	mov	ax, SelectorPageDir
	mov	es, ax
	xor	edi, edi
	xor	eax, eax
	mov	eax, PageTblBase |PG_P |PG_USU |PG_RWW
.1:
	stosd
	add 	eax, 4096			; 为了简化，所有页表在内存中是连续的
	loop	.1
	
	; 再初始化所有页表
	mov	ax, SelectorPageTbl		; 此段首地址为 PageTblBase
	mov	es, ax
	pop	eax				; 页表个数
	mov	ebx, 1024			; 每个页表 1024 个 PTE
	mul	ebx
	mov	ecx, eax			; PTE 个数 = 页表个数 * 1024
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

DispMemSize:
	push	esi
	push	edi
	push	ecx
	
	mov	esi, MemChkBuf
	mov	ecx, [dwMCRNumber]
.loop:				  
	mov	edx, 5		  
	mov	edi, ARDStruct
.1:
	push	dword [esi]
	call	DispInt
	pop	eax
	stosd
	add	esi, 4
	dec	edx
	cmp	edx, 0
	jnz	.1
	call	DispReturn
	cmp	dword [dwType], 1
	jne	.2
	mov	eax, [dwBaseAddrLow]
	add	eax, [dwLengthLow]	
	cmp	eax, [dwMemSize]
	jb	.2
	mov	[dwMemSize], eax
.2:
	loop	.loop

	call	DispReturn
	push	szRAMSize
	call	DispStr
	add	esp, 4
	
	push	dword [dwMemSize]
	call	DispInt
	add	esp, 4
	
	pop 	ecx
	pop	edi
	pop	esi
	ret
%include	"lib.inc"		; 库函数

SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]


; 16 位代码段.由 32 位代码段跳入，跳出后到实模式
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
	and	eax, 07FFFFFFEh ; PE=0, PG=0
	mov	cr0, eax
	
LABEL_GO_BACK_TO_REAL:
	jmp	0:LABEL_REAL_ENTRY

Code16Len	equ	$ - LABEL_SEG_CODE16
; END of [SECTION .s16code]
