#include "apue.h"

static void charatatime(char *);

int main(void) {
	pid_t pid;

	if ((pid = fork()) < 0) {
		err_sys("fork error");
	} else if (pid == 0) { // child
		charatatime("from child\n");
	} else { // parent
		charatatime("from parent\n");
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
