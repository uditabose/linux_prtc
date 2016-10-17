#include "apue.h"
#include <fcntl.h>

int main(int argc, char* argv[]) {

	if (argc != 2) {
		err_quit("usage:  ./acc.o <pathname>");
	}

	if (access(argv[1], R_OK) < 0) {
		err_ret("access error for %s", argv[1]);
	} else {
		printf("access ok for %s\n", argv[1]);
	}

	if (open(argv[1], O_RDONLY) < 0) {
		err_ret("open error for %s", argv[1]);
	} else {
		printf("open ok for %s\n", argv[1]);
	}

	exit(0);
}
