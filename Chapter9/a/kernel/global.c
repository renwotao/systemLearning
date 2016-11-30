
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            global.c
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    Forrest Yu, 2005
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#define GLOBAL_VARIABLES_HERE

#include "type.h"
#include "const.h"
#include "tty.h"
#include "console.h"
#include "protect.h"
#include "fs.h"
#include "proc.h"
#include "proto.h"
#include "global.h"


PUBLIC	struct proc proc_table[NR_TASKS + NR_PROCS];

PUBLIC	char task_stack[STACK_SIZE_TOTAL];

PUBLIC	struct task task_table[NR_TASKS] = {
				{task_tty, STACK_SIZE_TTY, "TTY"},
				{task_sys, STACK_SIZE_SYS, "SYS"}};

PUBLIC	struct task  user_proc_table[NR_PROCS] = 
					{{TestA, STACK_SIZE_TESTA, "TestA"},
					{TestB, STACK_SIZE_TESTB, "TestB"},
					{TestC, STACK_SIZE_TESTC, "TestC"}};

PUBLIC	irq_handler irq_table[NR_IRQ];

PUBLIC	system_call sys_call_table[NR_SYS_CALL] = {sys_printx, sys_sendrec};

PUBLIC TTY tty_table[NR_CONSOLES];
PUBLIC CONSOLE	console_table[NR_CONSOLES];

/*
 For dd_map[k],
 'k' is the device nr.\ dd_map[k].driver_nr is the driver nr.
 
 Remember to modify include/const.h if the order is changed
*/
struct dev_drv_map dd_map[] = 
{
	/* driver nr.		major device nr.*/
	{INVALID_DRIVER}, 	/**< 0 : Unused */
	{INVALID_DRIVER},	/**< 1 : Reserved for floppy driver */
	{INVALID_DRIVER},	/**< 2 : Reserved for cdrom driver */
	{TASK_HD},		/**< 3 : Hard disk */
	{TASK_TTY},		/**< 4 : TTY */
	{INVALID_DRIVER}	/**< 5 : Reserved for scsi disk driver */
};

/* major device numbers (corresponding to kernel/global.c::dd_map[]) */
#define NO_DEV			0
#define DEV_FLOPPY		1
#define DEV_CDROM		2
#define	DEV_HD			3
#define	DEV_CHAR_TTY		4
#define	DEV_SCSI		5

/* make device number from major and minor mumbers */
#define MAJOR_SHIFT		8
#define MAKE_DEV(a,b)		((a << MAJOR_SHIFT) | b)

/* separate major and minor numbers from device number */
#define MAJOR(x)		((x >> MAJOR_SHIFT) & 0xFF)
#define	MINOR(x)		(x & 0xFF)
