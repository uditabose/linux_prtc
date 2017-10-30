/* **************** LFD420:4.13 s_17/lab1_cfs.c **************** */
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
 * Simulating the CFS scheduler.
 *
 * Write a program that simulates the operation of the upcoming CFS
 * scheduler.
 *
 * You should consider a fixed number of equal intrinsic priority
 * tasks.  At each scheduling step, the task which has the most fair
 * time due to it should be scheduled to run.
 *
 * The time the task should run (after which the scheduler is run
 * again) should vary up to some maximum amount determined by a randon
 * mumber generator.
 *
 * Keep track of the cumulative CPU time for each task.
 *
 * After each step the fair time missed for each task should be
 * updated to be used for calculating the new relative priority for
 * the next scheduling decision.
 *
 * You may want to limit the maximum number of scheduling steps.
 *
 * Evaluate how well the load is balanced as time proceeds.
 *
@*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int ntask = 10;			/* how many tasks */
int ntime = 10;			/* how much time units to give at max
				 * the actual time given is tim * ntime where
				 * tim < ntask so we can do integer arithmetic */
int modprint = 1000;		/* how often to print out as we go; */
int *prio, *total;		/* priority vector, total time spent vector */
int ktop = 1000000;		/* maximum number of simulations */

static int k = 0;

#define PRINTF if ( k%modprint == 0 ) printf

int schedule()
{
	int j, tsk = 0, test = -1;
	for (j = 0; j < ntask; j++)
		if (prio[j] > test) {
			test = prio[j];
			tsk = j;
		}
	return tsk;
}

void update(int tsk, int tim)
{
	int j, timeslot, fairtime;	/* note fairtime will always be tim ! */
	timeslot = tim * ntask;
	fairtime = timeslot / ntask;
	for (j = 0; j < ntask; j++)
		prio[j] += fairtime;
	prio[tsk] += -timeslot;	/* don't make it not be negative */
	total[tsk] += timeslot;
}

void printit(int tsk, int tim)
{
	int j, diff, totave = 0, disp = 0;

	PRINTF("\nn=%4d, tsk=%d, tim=%d, \n", k, tsk, tim);
	for (j = 0; j < ntask; j++) {
		PRINTF("[%2d]=%3d  ", j, prio[j]);
		totave += total[j];
	}
	PRINTF("\n");

	totave = totave / ntask;
	for (j = 0; j < ntask; j++) {
		diff = total[j] - totave;
		PRINTF("%8d  ", diff);
		if (diff > 0)
			disp += diff;
		else
			disp += -diff;
	}
	PRINTF("\n average=%d, dispersion =%d\n", totave, disp / ntask);
}

int main(int argc, char *argv[])
{
	int tsk, tim;
	if (argc > 1)
		ntask = atoi(argv[1]);
	if (argc > 2)
		modprint = atoi(argv[2]);
	if (argc > 3)
		ktop = atoi(argv[3]);
	srand(getpid());
	prio = calloc(ntask, sizeof(int));
	total = calloc(ntask, sizeof(int));

	for (k = 0; k < ktop; k++) {
		/* select how long to run */
		tim = rand() % ntime + 1;
		/* select which process to run */
		tsk = schedule();
		/* print results */
		printit(tsk, tim);
		/* update priorities and total times */
		update(tsk, tim);
	}
	exit(EXIT_SUCCESS);
}
