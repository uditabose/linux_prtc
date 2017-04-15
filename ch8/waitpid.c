#include "apue.h"
#include <sys/wait.h>

int main(void) {
	pid_t pid;

	if((pid = fork()) < 0) {
		err_sys("fork error");
	} else if (pid == 0) { // first child
		if((pid = fork()) < 0) {
			err_sys("fork error");
		} else if (pid > 0) { // parent of second child aka the `first child`
			exit(0);
		}

		/**
		 * In the second child, child of first child, grandchild of main
		 * will sleep to allow to current parent or the `first child` to die
		 * will become zombie for a while, parent will be `init`
		 * then will die too
		 */

		sleep(2);
		printf("second child, parent pid = %ld\n", (long)getppid());
		exit(0);
	}

	/**
	 * back in main process
	 */

	if (waitpid(pid, NULL, 0) != pid) {
		err_sys("waitpid error");
	} else {
		printf("done with first child\n");

	}
	printf("me done\n");
	// me done
	exit(0);
}

