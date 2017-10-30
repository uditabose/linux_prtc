#include "apue.h"

static void sig_alrm(int);

int main(void) {
	int n;
	char line[MAXLINE];
	
	if (signal(SIGALRM, sig_alrm) == SIG_ERR) {
		err_sys("sig_alrm error");
	}
	
	// expectation is that the process won't block for more than
	// 10 seconds. Then the read would be performed. If read blocks
	// alarm would be delivered, read will be interrupted. Program will move 
	// forward. Depends on alarm to break the read blocking forever.
	
	// That expectation will not hold well, 
	// 1. if process blocks for more than 10 seconds between alarm and read calls
	// 2. If read is automatically restarted by OS 
	alarm(10);
	if ((n = read(STDIN_FILENO, line, MAXLINE)) < 0) {
		err_sys("read error");
	}
	
	alarm(0);
	
	write(STDOUT_FILENO, line, n);
	exit(0);
}

static void sig_alrm(int signo) {
	// nothing to do
}

