/* **************** LFD420:4.13 s_16/lab2_priority.c **************** */
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
 * Examining and modifying process priorities with getpriority(),
 * setpriority().
 *
 * Despite their names, the getpriority() and setpriority() functions
 * actually change the  nice values (see man 2 nice) for a process,
 * process group, or user, which are then used to get and set the
 * scheduling priorities in the scheduling algorithm.
 *
 * After examining the man pages for these
 * functions, write a program that can examine and tries to modify the
 * priority of a process.  (This is essentially an implementation of the
 * nice command line utility.)
 *
 * By default it should work with the current process; an optional
 * argument should be the process ID of another running process (You can
 * just run cat&; in the background if you want to be careful).
 *
 * You may want to loop over possible values, from
 * -20 to +19.
 *
 * You should find that only root users can use
 * setpriority() to obtain an advantage in scheduling;
 * normal users can only lower their process priorities.
@*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <errno.h>

int main(int argc, char *argv[])
{
	pid_t mypid;
	int old_prio, new_prio, i, rc;

	if (argc > 1) {
		mypid = atoi(argv[1]);
	} else {
		mypid = getpid();
	}

	printf("\nExamining priorities forPID = %d \n", mypid);
	printf("%10s%10s%10s\n", "Previous", "Requested", "Assigned");

	for (i = -20; i < 20; i += 2) {

		old_prio = getpriority(PRIO_PROCESS, (int)mypid);
		rc = setpriority(PRIO_PROCESS, (int)mypid, i);
		if (rc)
			fprintf(stderr, "setpriority() failed ");

		/* must clear errno before call to getpriority
		   because -1 is a valid return value */
		errno = 0;

		new_prio = getpriority(PRIO_PROCESS, (int)mypid);
		printf("%10d%10d%10d\n", old_prio, i, new_prio);

	}
	exit(EXIT_SUCCESS);
}
