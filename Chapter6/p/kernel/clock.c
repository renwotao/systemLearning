/*
	clock.c
*/
#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "proc.h"
#include "global.h"


/*
	clock_handler
*/
PUBLIC void clock_handler(int irq)
{
	//disp_str("#");
	ticks++;

	if (k_reenter != 0)
	{
		//disp_str("!");
		return;
	}

	schedule();
}

PUBLIC void milli_delay(int milli_sec)
{
	int t = get_ticks();
	
	while (((get_ticks() - t) * 1000 / HZ) < milli_sec) {}
}

