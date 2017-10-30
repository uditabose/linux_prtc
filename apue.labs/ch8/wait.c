#include "apue.h"
#include <sys/wait.h>

void pr_exit(int status) {
	if (WIFEXITED(status)) {
		printf("normal exit, status = %d\n", WEXITSTATUS(status));
	} else if (WIFSIGNALED(status)) {
		printf("abnormal exit, signal = %d%s\n", WTERMSIG(status),
		#ifdef WCOREDUMP
			WCOREDUMP(status) ? " (core file generated) " : " (not) " );
		#else
			" (niet) ");
		#endif
	} else if(WIFSTOPPED(status)) {
		printf("stopped, signal = %d\n", WSTOPSIG(status));
	}
}


int main(void) {
	pid_t pid;
	int status;

	if ((pid = fork()) < 0) {
		err_sys("fork error");
	} else if (pid == 0) {
		exit(7);
	}

	if (wait(&status) != pid) {
		err_sys("wait error");
	}
	pr_exit(status);

	if ((pid = fork()) < 0) {
                err_sys("fork error");
        } else if (pid == 0) {
		abort(); // SIGABRT
        }

	if (wait(&status) != pid) {
                err_sys("wait error");
        }
	pr_exit(status);

	if ((pid = fork()) < 0) {
                err_sys("fork error");
        } else if (pid == 0) {
                status /= 0; // SIGFPE
        }

        if (wait(&status) != pid) {
                err_sys("wait error");
        }
        pr_exit(status);	

	exit(0);
}
