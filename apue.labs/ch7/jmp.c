/**
 * compiled with no optimization 
 * result is :
 * 
 * in f1():
 * global = 100, auto = 200, register = 300, volatile = 400, static = 500
 * after longjmp:
 * global = 100, auto = 200, register = 300, volatile = 400, static = 500
 *
 * compile with `-O` flag to enable full optimization
 *
 * From root directory : 
 *
 * `cc -O ch7/jmp.c -o ch7/jmp.o apue.3e/lib/libapue.a`
 * result is :
 *
 * in f1():
 * global = 100, auto = 200, register = 300, volatile = 400, static = 500
 * after longjmp:
 * global = 100, auto = 2, register = 3, volatile = 400, static = 500
 */


#include "apue.h"
#include <setjmp.h>

static void f1(int, int, int, int);
static void f2(void);

static jmp_buf jmpbuf;
static int    globval;

int main(void) {
	int autoval;
	register int regval;
	volatile int volval;
	static int statval;

	globval = 1; autoval = 2; regval = 3; volval = 4; statval = 5;
	
	if (setjmp(jmpbuf) != 0) {
		printf("after longjmp:\n");
		printf("global = %d, auto = %d, register = %d, volatile = %d, static = %d \n",
			globval, autoval, regval, volval, statval);
	
		exit(0);
	}

	// change variables after setjmp
	globval = 100; autoval = 200; regval = 300; volval = 400; statval = 500;
	
	f1(autoval, regval, volval, statval);
	exit(0);
}


static void f1(int i1, int i2, int i3, int i4) {

	printf("in f1():\n");
	printf("global = %d, auto = %d, register = %d, volatile = %d, static = %d \n",
                         globval, i1, i2, i3, i4);
	f2();

}

static void f2(void) {
	longjmp(jmpbuf, 1);
}
