/* **************** LFD420:4.13 s_21/ml.c **************** */
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
#include <sys/mman.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <unistd.h>

#define DEATH(mess) { perror(mess); exit(errno); }

int main(int argc, char *argv[])
{
        char *buf;
        int length, np = 4;
        if (argc > 1)
                np = atoi(argv[1]);
        length = np * getpagesize();

        if ((buf = malloc(length)) == NULL)
                DEATH("mallocing");

        if (mlock(buf, length))
                DEATH("mlock:");
        printf("Succeeding in locking memory, %d pages!\n", np);

        /* do something with locked memory */

        if (munlock(buf, length))
                DEATH("munlock:");
        printf("Succeeding in unlocking memory!\n");
        exit(EXIT_SUCCESS);
}
