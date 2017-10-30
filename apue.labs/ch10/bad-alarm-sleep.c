#include <setjmp.h>
#include <signal.h>
#include <unistd.h>

#include "apue.h"

/**
* @sleep problems :
* 	race cond between alarm can be fired before the pause
*	first call to alarm wipes the previous alarm
*	disposition of sigalrm should be reset
*/

static jmp_buf env_alrm;

static void sig_alrm_do_nothing(int signo) {
	// do nothing, just to let wake up from pause
}


/**
* just waits to be woken up by the alarm 
*/
unsigned int sleep1(int seconds) {
	if (signal(SIGALRM, sig_alrm_do_nothing) == SIG_ERR) {
		return(seconds);
	}
	
	alarm(seconds);
	pause();
	return(alarm(0));
}


static void sig_alrm_longjmp(int signo) {
	longjmp(env_alrm, 1);
}

unsigned int sleep2(int seconds) {
	if (signal(SIGALRM, sig_alrm_longjmp) == SIG_ERR) {
		return(seconds);
	}
	
	if (setjmp(env_alrm) == 0) {
		alarm(seconds);
		pause();
	}
	
	return(alarm(0));
}

static void sig_int(int signo) {
	int i, j;
	volatile int k;
	
	printf("\nsig_int started\n");
	
	// this is more than 5 seconds, so alarm returns wiping the sigint
	for (i = 0; i < 300000; i++) {
		for (j = 0; j < 400000; j++) {
			k += i*j;
		}
	}
	printf("\nsig_int done\n");
	
}

int main() {
	unsigned int unslept;
	
	if (signal(SIGINT, sig_int) == SIG_ERR) {
		err_sys("SIGINT error");
	}
	
	unslept = sleep2(5);
	printf("sleep2 return %d\n", unslept);
	exit(0);
}
