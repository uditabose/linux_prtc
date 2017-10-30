/* **************** LFD420:4.13 s_09/lab2_ioctl_test.c **************** */
/*
 * The code herein is: Copyright the Linux Foundation, 2017
 *
 * This Copyright is retained for the purpose of protecting free
 * redistribution of source.
 *
 *     URL:    http://training.linuxfoundation.org
 *     email:  trainingquestions@linuxfoundation.org
 *
 * This code is distributed under Version 2 of the GNU General Public
 * License, which you should have received with the source.
 *
 */
/*
 * Using ioctl() for Anything. (test program)
 *
 * As we commented, one reason for resistance to adding dynamic system
 * calls it that the ioctl() system call can already be used for
 * almost any purpose.
 *
 * One minor drawback is that you have to have a device node and write
 * a user application to access the node and pass ioctl() commands to
 * it.
 *
 * For those of you who know how to do a character driver, write a
 * very very brief character driver that has only an ioctl() entry
 * point.  (You don't even need open() or release()).
 *
 * Write a companion program that shows how you can use it.
 *
 @*/
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

int main(int argc, char *argv[])
{
	int fd, j;
	char *devname = "/dev/mycdrv";
	if (argc > 1)
		devname = argv[1];
	fd = open(devname, O_RDWR);
	for (j = 100; j < 110; j++)
		printf("ioctl(%d) = %d\n", j, ioctl(fd, j, NULL));
	exit(EXIT_SUCCESS);
}
