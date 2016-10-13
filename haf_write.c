#include "apue.h"
#include <fcntl.h>

int main(void) {
	
	int fd;
	char buf[] = "abcdefghij";
	
	if ((fd = creat("haf", FILE_MODE)) == -1) {
		err_sys("create error");
	}
	
	if (write(fd, buf, 5) < 0) {
		err_sys("write error");
	}
	
	exit(0);
}
