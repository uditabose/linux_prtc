#include "apue.h"
#include <sys/wait.h>

static void sig_cld(int);

int main(void) {
	pid_t pid;
	
	if (signal(SIGCLD, sig_cld) == SIG_ERR) {
		perror("signal error");
	}
	
	if ((pid = fork()) < 0) {
		perror("fork error");
	} else if (pid == 0) { // child
		sleep(2);
		_exit(0);
	}
	
	pause(); // parent
}


static void sig_cld(int signo) {
	
	pid_t pid;
	int status;
	
	printf("in signal handler\n");
	
	// moved the wait beforesignal re-register
	if ((pid = wait(&status)) < 0) {
		perror("wait error");
	}
	
	if (signal(SIGCLD, sig_cld) == SIG_ERR) { // re-establish handler
	    perror("signal error");
	}
	
	printf("pid = %d\n", pid);
	
}
