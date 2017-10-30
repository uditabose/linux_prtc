/* **************** LFD420:4.13 s_16/lab3_scheduler.c **************** */
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
 * Using sched_getscheduler() and sched_setscheduler() to
 * examinine and modify process priorities and scheduling
 * policy
 *
 * Accomplish essentially the same task as in the previous
 * exercise. However, this time use the sched_getscheduler(),
 * sched_setscheduler() functions.
 *
 * To keep it simple, just work with the current process.
 *
 * Find out what its current policy is and then
 * try to modify it to one of the real time ones (SCHED_FIFO,
 * SCHED_RR).  When doing so change the current priority to some
 * value, say p.sched_priority = 50.
@*/

#include <sched.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

#define DEATH(mess) { perror(mess); exit(errno); }

void printpolicy(int policy)
{

	/* SCHED_NORMAL = SCHED_OTHER in user-space */

	if (policy == SCHED_OTHER)
		printf("policy = SCHED_OTHER = %d\n", policy);
	if (policy == SCHED_FIFO)
		printf("policy = SCHED_FIFO = %d\n", policy);
	if (policy == SCHED_RR)
		printf("policy = SCHED_RR = %d\n", policy);
}

int main(int argc, char **argv)
{
	int policy;
	struct sched_param p;

	/* obtain current scheduling policy for this process */

	policy = sched_getscheduler(0);
	printpolicy(policy);

	/* reset scheduling policy */

	printf("\nTrying sched_setscheduler...\n");
	policy = SCHED_FIFO;
	printpolicy(policy);
	p.sched_priority = 50;
	if (sched_setscheduler(0, policy, &p))
		DEATH("sched_setscheduler:");
	printf("p.sched_priority = %d\n", p.sched_priority);
	exit(EXIT_SUCCESS);
}
