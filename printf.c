// Simple implementation of cprintf console output for the kernel,
// based on printfmt() and the kernel console's cputchar().

#include <inc/types.h>
#include <inc/stdio.h>
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
	cputchar(ch);
	*cnt++;
}

int
vcprintf(const char *fmt, va_list ap)
{
	int cnt = 0;

	vprintfmt((void*)putch, &cnt, fmt, ap);
	return cnt;
}

/*int
cprintf(const char *fmt, ...)
{
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
	va_end(ap);

	return cnt;
}
*/
int
cprintf(const char *fmt, ...)
{
        va_list ap, ap_i;
        int val, cnt, arg_cnt;
	register int ch;

        va_start(ap, fmt);
	va_start(ap_i, fmt);
	while ((ch = *(unsigned char *) fmt++) != '\0') {
        	if (ch == '%')
        		++arg_cnt;
        }

	/*
	val = (int) (fmt+1);
	//va_copy(ap_i, ap);
        while(0 != val) {
            val = va_arg(ap_i, int);
            arg_cnt++;
        }
        va_end(ap_i);*/
        cnt = vcprintf(fmt, ap);
	va_end(ap);

        return cnt;
}

