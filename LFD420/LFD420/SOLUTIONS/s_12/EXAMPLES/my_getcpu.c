/* **************** LFD420:4.13 s_12/my_getcpu.c **************** */
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
/* my_getcpu program */

#include <stdio.h>
#include <stdlib.h>
#include <sched.h>

int main()
{
        printf("My cpu is %d\n", sched_getcpu());
        exit(EXIT_SUCCESS);
}
