/*
	vsprintf.c
*/

#include "type.h"
#include "const.h"
#include "string.h"

/*
	vsprintf
*/
int vsprintf(char* buf, const char* fmt, va_list args)
{
	char* p;
	char tmp[256];
	va_list p_next_arg = args;

	for (p = buf; *fmt; fmt++)
	{
		if (*fmt != '%')
		{
			*p++ = *fmt;
			continue;
		}
	
		fmt++;
		
		switch(*fmt)
		{
		case 'x':
			itoa(tmp, *((int*)p_next_arg));
			strcpy(p, tmp);
			p_next_arg += 4;
			p += strlen(tmp);
			break;
		case 's':
			break;
		default:
			break;
		}
	}
	
	return (p - buf);
}

/*
	sprintf
*/
int sprintf(char *buf, const char *fmt, ...)
{
	va_list arg = (va_list)((char*)(&fmt) + 4);
	return vsprintf(buf, fmt, arg);
}
