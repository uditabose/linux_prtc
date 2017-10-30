#include "apue.h"
#include <pwd.h>

static void my_alarm(int signo) {
	struct passwd *rootptr;
	
	printf("in signal handler\n");
	if ((rootptr = getpwnam("root")) == NULL) {
		err_sys("root password failed");
	}
	alarm(1);
}

int main(void) {
	struct passwd *ptr;
	
	signal(SIGALRM, my_alarm);
	alarm(1);
	for ( ; ; ) {
		if ((ptr = getpwnam("papa")) == NULL) {
			err_sys("papa password fail");
		}
		
		if (strcmp(ptr->pw_name, "papa") != 0) {
			printf("corrupted! pw_name = %s\n", ptr->pw_name);
		}
	}

}

