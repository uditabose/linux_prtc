#include "apue.h"
#include <fcntl.h>

int main(void) {

	struct stat statbuf;
	if (stat("foo", &statbuf) < 0) {
		err_sys("error stat-ing foo");
	}

	if (chmod("foo", (statbuf.st_mode & ~S_IXGRP) | S_ISGID) < 0) {
		err_sys("error changing mode for foo");
	}

	if (chmod("bar", S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH) < 0) {
		err_sys("error changing mode for bar");
	}
	exit(0);
}
