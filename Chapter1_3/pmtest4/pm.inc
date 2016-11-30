;段描述符中属性的定义
; 描述符类型
DA_32		EQU	4000h	; 32 位段

DA_DPL0		EQU	  00h	; DPL = 0
DA_DPL1		EQU	  20h	; DPL = 1
DA_DPL2		EQU	  40h	; DPL = 2
DA_DPL3		EQU	  60h	; DPL = 3

; 存储段描述符类型
DA_DR		EQU	90h	; 存在的只读数据段类型值
DA_DRW		EQU	92h	; 存在的可读写数据段属性值
DA_DRWA		EQU	93h	; 存在的已访问可读写数据段类型值
DA_C		EQU	98h	; 存在的只执行代码段属性值
DA_CR		EQU	9Ah	; 存在的可执行可读代码段属性值
DA_CCO		EQU	9Ch	; 存在的只执行一致代码段属性值
DA_CCOR		EQU	9Eh	; 存在的可执行可读一致代码段属性值

; 系统段描述符类型
DA_LDT		EQU	  82h	; 局部描述符表段类型值
DA_TaskGate	EQU	  85h	; 任务门类型值
DA_386TSS	EQU	  89h	; 可用 386 任务状态段类型值
DA_386CGate	EQU	  8Ch	; 386 调用门类型值
DA_386IGate	EQU	  8Eh	; 386 中断门类型值
DA_386TGate	EQU	  8Fh	; 386 陷阱门类型值

;----------------------------------------------------------------------------
; 选择子类型值说明
; 其中:
;       SA_  : Selector Attribute

SA_RPL0		EQU	0	; ┓
SA_RPL1		EQU	1	; ┣ RPL
SA_RPL2		EQU	2	; ┃
SA_RPL3		EQU	3	; ┛

SA_TIG		EQU	0	; ┓TI
SA_TIL		EQU	4	; ┛

;通过宏得到真正的段描述符定义

;usage: Descripter Base, Limit, Attr
;	Base:  dd
;	Limit: dd
; 	Attr:  dw

%macro Descriptor 3
	dw %2 & 0FFFFh
	dw %1 & 0FFFFh
	db (%1 >> 16) & 0FFh
	dw ((%2 >> 8) & 0F00h) | (%3 &0F0FFh)
	db (%1 >> 24) & 0FFh
%endmacro ;(8 bytes Segment Descripter)

;usage: Gate Selector, offset, DCount, Attr
;	Selector: dd
; 	offset:	  dd
;	DCount:   db
;	Attr:	  db
%macro Gate 4
	dw	(%2 & 0FFFFh)                      ; 偏移
	dw	%1				   ; 选择子
	dw 	(%3 & 1Fh) | ((%4 << 8) & 0FF00h) ; 属性
	dw 	((%2 >> 16) & 0FFFFh)		   ; 偏移2
%endmacro ; 共 8 字节

