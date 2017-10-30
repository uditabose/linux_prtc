/* **************** LFD420:4.13 s_24/lab4_sigprocess.c **************** */
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
/* NOMAKE
 * Changing Signal Priorities for a Process.

 * Add a new system call, setsigpriority(), to allow the signal
 * processing sequence (order) to be specified for an individual
 * process or process group.

 * The system call should provide the capability to specify a signal
 * priority to be used by the function next_signal() on an individual
 * process, process group, or process owner basis.

 * There is no one way to implement this, but our solution modifies
 * the task_struct defined in linux/sched.h in order to specify a
 * vector of signal priorities, and a flag to indicate whether to use
 * it or not.

 * In addition you will have to modify the usual files that have to be
 * worked on to add a new system call.

 * You can modify the solution developed in the first exercise to test the
 * new system call.

@*/

#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <unistd.h>

#define setsigpriority(a,b) syscall(__NR_setsigpriority,a,b)

void odd_even(char *sigpri);

/* prototypes of locally-defined signal handlers */

void (sig_handler) (int);

int sigCount[64];		/* counter for signals received */
volatile static int line = 0;
volatile int signumbuf[6400], sigcountbuf[6400];

int main(int argc, char *argv[])
{
	sigset_t sigmaskNew, sigmaskOld;
	struct sigaction sigact, oldact;
	int signum, rc, i;
	pid_t pid;
	char sigpri[64];

	/* TODO: this doesn't really work for examining what happens
	   when you change the sigpriorities for another process. */

	pid = getpid();
	if (argc > 1)
		pid = atoi(argv[1]);
	printf("I'm resetting signal priorities for pid=%d\n", (int)pid);

	/* block all possible signals */
	rc = sigfillset(&sigmaskNew);
	rc = sigprocmask(SIG_SETMASK, &sigmaskNew, &sigmaskOld);

	/* set up new priorities */
	odd_even(sigpri);
	rc = setsigpriority(getpid(), sigpri);
	if (rc) {
		printf("failed to reset the signal priorities; quitting\n");
		printf(" rc = %d\n", rc);
		exit(EXIT_FAILURE);
	} else {
		printf("I reset the signal priorities to:");
		for (i = 0; i < 64; i++) {
			if (((i % 16) == 0))
				printf("\n");
			printf("%3d", (int)sigpri[i]);
		}
		printf("\n");
	}

	/* Assign values to members of sigaction structures */
	memset(&sigact, 0, sizeof(struct sigaction));
	sigact.sa_handler = sig_handler;	/* we use a pointer to a handler */
	sigact.sa_flags = 0;	/* no flags */

	/*
	 * Now, use sigaction to create references to local signal
	 * handlers and raise the signal
	 */

	printf
	    ("Installing signal handler and Raising signal for signal number:\n");
	for (signum = 1; signum < 64; signum++) {
		if ((signum == SIGKILL) || (signum == SIGSTOP))
			continue;
		sigaction(signum, &sigact, &oldact);
		/* send the signal 3 times! */
		rc = kill(pid, signum);
		rc = kill(pid, signum);
		rc = kill(pid, signum);
		if (rc) {
			printf("Failed on Signal %d\n", signum);
		} else {
			if (signum % 16 == 0)
				printf("\n");
			printf("%4d", signum);
		}
	}
	printf("\n");
	fflush(stdout);

	/* restore original mask */
	rc = sigprocmask(SIG_SETMASK, &sigmaskOld, NULL);

	printf("\nSignal  Number(Times Processed)\n");
	printf("--------------------------------------------\n");
	for (i = 0; i < 64; i++) {
		printf("%4d:%3d  ", i, sigCount[i]);
		if (i % 8 == 0)
			printf("\n");
	}
	printf("\n");

	printf("\nHistory: Signal  Number(Count Processed)\n");
	printf("--------------------------------------------\n");
	for (i = 0; i <= line; i++) {
		if (i % 8 == 0)
			printf("\n");
		printf("%4d(%1d)", signumbuf[i], sigcountbuf[i]);
	}
	printf("\n");
	exit(EXIT_SUCCESS);
}

void sig_handler(int sig)
{
	sigCount[sig]++;
	signumbuf[line] = sig;
	sigcountbuf[line] = sigCount[sig];
	line++;
}

void odd_even(char *sigpri)
{
	int j;
	for (j = 0; j < 32; j++) {
		sigpri[2 * j] = (char)j;
		sigpri[2 * j + 1] = (char)(j + 32);
	}
}
