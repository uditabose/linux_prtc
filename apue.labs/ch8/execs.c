#include "apue.h"
#include <sys/wait.h>

char *env_init[] = { "USER=unknown", "PATH=/tmp", NULL};

int main(void) {
	pid_t pid;
	
	if ((pid = fork()) < 0) {
		err_sys("fork error");
	} else if (pid == 0) { // child
		if(execle("/bin/echo", "echo", "-e", "papa\\n", "bose\\n", "are jah\\n", (char *)0, env_init) < 0) {
			err_sys("exec error");
		}

	}

	if (waitpid(pid, NULL, 0) < 0) { // let the child die
		err_sys("wait error");
	}

	if ((pid = fork()) < 0) {
                err_sys("fork error");
	} else if (pid == 0) { // second child
		if(execlp("echo", "echo", "-e", "papa bose\\n", (char *)0) < 0) {	
			err_sys("exec error");
		}
	}

	if (waitpid(pid, NULL, 0) < 0) { // let the child die
                err_sys("wait error");
        }

	exit(0);
}
