/* **************** LFD420:4.13 s_19/lab3_hugewaste.c **************** */
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
/* simple program to defragment memory using huge pages, J. Cooperstein 2/2010
 @*/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <hugetlbfs.h>
#define MB (1024*1024)

int main(int argc, char **argv)
{
	int j;
	char *c;
	int m = atoi(argv[1]);
	for (j = 0; j < m; j++) {
		/* yes we know this is a memory leak, no free, that's the idea!  */
		c = get_hugepage_region(MB, GHR_DEFAULT);
		memset(c, j, MB);
		printf("%5d", j);
		fflush(stdout);
	}
	printf("All memory allocated, pausing 5 seconds\n");
	sleep(5);
	printf("Quitting and releasing memory\n");
	exit(EXIT_SUCCESS);
}
