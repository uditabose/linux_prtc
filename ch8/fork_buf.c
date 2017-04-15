/**
 * run with console as stdout : 
 *
 * `ch8/fork_buf.o`
 *
 * output : 
 *  
 * a write to stdout.
 * before fork.
 * pid = 0, glob = 10, var = 89
 * pid = 19157, glob = 9, var = 88
 * 
 * run with stdout redirection
 * 
 * `ch8/fork_buf.o > ch8/fork_buf.log`
 * 
 * output : `cat ch8/fork_buf.log`
 *
 * a write to stdout.
 * before fork.
 * pid = 0, glob = 10, var = 89
 * before fork.
 * pid = 19164, glob = 9, var = 88
 *
 * Clue : write is not buffered, printf is. printf is newline
 *        buffered when in interactive mode, when redirected, 
 *        buffer is only spilled as I/O buffer is flushed.
 **/


#include "apue.h"

int globvar = 9;
char buf[] = "a write to stdout.\n";

int main(void) {
	int var;
	pid_t pid;
	
	var = 88;
	
	if (write(STDOUT_FILENO, buf, sizeof(buf) - 1) != sizeof(buf) - 1) {
		err_sys("write error");
	}

	printf("before fork.\n");
	
	if ((pid = fork()) < 0) {
		err_sys("fork error");
	} else if (pid == 0) { // in child process
		globvar++;
		var++;
	} else {
		sleep(2);
	}

	printf("pid = %ld, glob = %d, var = %d\n", (long)pid, globvar, var);
	exit(0);
}
