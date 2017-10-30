#include "apue.h"

static void charatatime(char *);

int main(void) {
	pid_t pid;

	TELL_WAIT();

	if((pid = fork()) < 0) {
		err_sys("fork error");
	} else if (pid == 0) { // child 
		WAIT_PARENT();
		charatatime("from child proc\n");
	} else { // parent
		charatatime("from parent proc\n");
		TELL_CHILD(pid);
	}


	/**
	 * This part does not work, with or without the TELL_WAIT.
	 * Race condition occurs.
	 */
	TELL_WAIT();
	// printf("\n\n");
 
	if((pid = fork()) < 0) {
                err_sys("fork error");
        } else if (pid == 0) { // child
                charatatime("first child proc\n");
		TELL_PARENT(getppid());
        } else { // parent
		WAIT_CHILD();
                charatatime("next parent proc\n");
        }

	exit(0);
}

static void charatatime(char *str) {
	char *ptr;
	int c;

	setbuf(stdout, NULL);

	for (ptr = str; (c = *ptr++) != 0;) {
		putc(c, stdout);
	}
}
