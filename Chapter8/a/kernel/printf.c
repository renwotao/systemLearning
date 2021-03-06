/*
	printf.c
*/

#include "type.h"
#include "const.h"

/*
	printf
*/
int printf(const char* fmt, ...)
{
	int i;
	char buf[256];
		
	va_list arg = (va_list)((char*)(&fmt) + 4);/*4 是参数fmt所占堆栈中的大小*/
	i = vsprintf(buf, fmt, arg);
	buf[i] = 0;
	printx(buf);

	return i;
}
