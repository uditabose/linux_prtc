/* **************** LFD420:4.13 s_24/lab2_handler_test.c **************** */
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
 * Changing Signal Handlers for a Running Process.
 * (TESTING PROGRAM)
@*/

#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#define DEATH(mess) { perror(mess); exit(errno); }

void sig_han(int signo)
{
	printf("We have received signal %d.\n", signo);
}

int main(int argc, char *argv[])
{
	int signo = SIGINT;	/* for CTRL-C */
	struct sigaction act;

	if (argc > 1)
		signo = atoi(argv[1]);

	memset(&act, 0, sizeof(act));

	/* Install signal handler */
	act.sa_handler = sig_han;
	if (sigaction(signo, &act, NULL) < 0)
		DEATH("sigaction");

	printf("Process %d has installed the handler for signal %d\n",
	       getpid(), signo);

	/* Do something pointless, forever */
	for (;;)
		sleep(1);

	return 0;
}
