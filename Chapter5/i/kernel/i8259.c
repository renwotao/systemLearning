/*
	i8259.c
*/

#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"

PUBLIC void init_8259A()
{
	/* Master 8259, ICW1. */
	out_byte(INT_M_CTL, 0x11);
	
	/* Slave 8259, ICW1. */
	out_byte(INT_S_CTL, 0X11);

	/* Master 8259, ICW2. 设置 '主8259'的中断入口地址 0x20.*/
	out_byte(INT_M_CTLMASK, INT_VECTOR_IRQ0);
	
	/* Slave 8259, ICW2. 设置 '从8259'的中中断入口地址 0x28.*/
	out_byte(INT_S_CTLMASK, INT_VECTOR_IRQ8);
	
	/* Master 8259, ICW3. IR2 对应'从8259'.*/
	out_byte(INT_M_CTLMASK, 0X4);

	/* Slave 8259, ICW3. 对应'主8259'的IR2.*/
	out_byte(INT_S_CTLMASK, 0X2);

	/* Master 8259, ICW4. */
	out_byte(INT_M_CTLMASK, 0X1);

	/* Slave 8259, ICW4. */
	out_byte(INT_S_CTLMASK, 0X1);

	/* Master 8259, OCW1.*/
	out_byte(INT_M_CTLMASK, 0xFD); // 打开键盘硬件中断
	
	/* Slave 8259, OCW1.*/
	out_byte(INT_S_CTLMASK, 0xFF);
	 
}

/*======================================================================*
                           spurious_irq
 *======================================================================*/
PUBLIC void spurious_irq(int irq)
{
        disp_str("spurious_irq: ");
        disp_int(irq);
        disp_str("\n");
}