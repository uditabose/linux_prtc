#include "apue.h"

int globvar = 9;

int main(void) {

	int var; 
	pid_t pid;

	var = 78;
	printf("before fork.\n");
	if ((pid = vfork()) < 0) {
		err_sys("vfork failed");
	} else if (pid == 0) {
		globvar++;
		var++;
		_exit(0);
	}

	printf("pid = %ld, globvar = %d, var = %d\n", (long)pid, globvar, var);

	exit(0);
}
