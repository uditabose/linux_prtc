/* **************** LFD420:4.13 s_24/blocksig.c **************** */
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
#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
        int rc;
        sigset_t sigsus, oldset;

        /* block all possible signals */
        rc = sigfillset(&sigsus);
        rc = sigprocmask(SIG_SETMASK, &sigsus, &oldset);

        printf(" going to sleep 5 seconds, try control-C!\n");
        sleep(5);
        printf(" going ahead\n");

        /* restore original mask */
        rc = sigprocmask(SIG_SETMASK, &oldset, NULL);

        /* the program should terminate before the next loop if you
           sent a Ctl-C while the signals were blocked */

        /* Do something pointless, forever */
        for (;;) {
                printf("This is a pointless message.\n");
                sleep(1);
        }
        return 0;
}
