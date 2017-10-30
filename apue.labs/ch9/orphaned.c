#include "apue.h"
#include <errno.h>

static void sig_hup(int signo) {
	printf("SIGHUP pid = %ld\n", (long)getpid());
}

static void pr_ids(char *name) {
	printf("%s: pid = %ld, ppid = %ld, pgrp = %ld, tgrp = %ld\n",
			name, (long)getpid(), (long)getppid(), (long)getpgrp(), (long)tcgetpgrp(STDIN_FILENO));
	fflush(stdout);
}


int main(void) {
	char c;
	pid_t pid;

	pr_ids("parent");
	if ((pid = fork()) < 0) {
		err_sys("fork error");
	} else if (pid > 0) {
		sleep(15); // let parent sleep
	} else {
		pr_ids("child");
		signal(SIGHUP, sig_hup);
		kill(getpid(), SIGTSTP); // stop me, equivalent of Ctrl+z
		pr_ids("child");

		if (read(STDIN_FILENO, &c, 1) != 1) {
			printf("read error %d tty\n", errno);
		}
	}

	exit(0);
}
