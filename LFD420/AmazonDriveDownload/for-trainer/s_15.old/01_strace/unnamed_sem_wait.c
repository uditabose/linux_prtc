/*$off*/
/*$4 *******************************************************************************************************************
*
* DESCRIPTION:  unnamed semaphores example 
*
* AUTHOR:       robert.berger@reliableembeddedsystems.com
*
* FILENAME:     unnamed_sem_wait.c
*
* REMARKS:      http://linux.die.net/man/3/sem_wait
*               The (somewhat trivial) program shown below operates on an unnamed semaphore. 
*               The program expects two command-line arguments. 
*               The first argument specifies a seconds value that is used to set an alarm timer 
*               to generate a SIGALRM signal. This handler performs a sem_post() to increment 
*               the semaphore that is being waited on in main() using sem_timedwait(). 
*               The second command-line argument specifies the length of the timeout, in seconds, 
*               for sem_timedwait(). The following shows what happens on two different runs of the program:
*
*                   $ ./unnamed_sem_wait.out 2 3
*                   About to call sem_timedwait()
*                   sem_post() from handler
*                   sem_getvalue() from handler; value = 1
*                   sem_timedwait() succeeded
*                   $ ./unnamed_sem_wait.out 2 1
*                   About to call sem_timedwait()
*
* HISTORY:      001a,18 May 2009,robert.berger    written
*
* COPYRIGHT:    (C) 2009 
*
 *********************************************************************************************************************** */
/*$on*/

/*$3 ===================================================================================================================
    $C                                             Included headers
 ======================================================================================================================= */

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <semaphore.h>
#include <time.h>
#include <assert.h>
#include <errno.h>
#include <signal.h>

/*$3 ===================================================================================================================
    $C                                                 Constants
 ======================================================================================================================= */

/*$3 ===================================================================================================================
    $C                                                  Macros
 ======================================================================================================================= */

#define die(msg)             \
    {                        \
        perror (msg);        \
        exit (EXIT_FAILURE); \
    }

/*$3 ===================================================================================================================
    $C                                                   Types
 ======================================================================================================================= */

/*$3 ===================================================================================================================
    $C                                               Imported data
 ======================================================================================================================= */

/*$3 ===================================================================================================================
    $C                                               Private data
 ======================================================================================================================= */

/*$3 ===================================================================================================================
    $C                                                Public data
 ======================================================================================================================= */

sem_t   sem;

/*$3 ===================================================================================================================
    $C                                      Imported function declarations
 ======================================================================================================================= */

/*$3 ===================================================================================================================
    $C                                       Public function declarations
 ======================================================================================================================= */

/*$3 ===================================================================================================================
    $C                                       Private function declarations
 ======================================================================================================================= */

static void handler (int);

/*$3 ===================================================================================================================
    $C                                       Private function definitions
 ======================================================================================================================= */

static void handler (
    int sig)    /* < @@@ TODO: add comment */
{
    /*~~~~~*/
    int sval;
    /*~~~~~*/

    printf ("sem_post() from handler\n");
    if (sem_post (&sem) == -1)
    {
        die ("sem_post");
    }

    if (sem_getvalue (&sem, &sval) == -1)
    {
        die ("sem_getvalue");
    }

    printf ("sem_getvalue() from handler; value = %d\n", sval);
}               /* handler */

/*$3 ===================================================================================================================
    $C                                        Public function definitions
 ======================================================================================================================= */

int main (
    int     argc,   /* < @@@ TODO: add comment */
    char*   argv[]) /* < @@@ TODO: add comment */
{
    /*~~~~~~~~~~~~~~~~~~~*/
    struct sigaction    sa;
    struct timespec     ts;
    int                 s;
    /*~~~~~~~~~~~~~~~~~~~*/

    assert (argc == 3); /* Usage: ./a.out alarm-secs wait-secs */
    if (sem_init (&sem, 0, 0) == -1)
    {
        die ("sem_init");
    }

    /*
     * Establish SIGALRM handler;
     * set alarm timer using argv[1]
     */
    sa.sa_handler = handler;
    sigemptyset (&sa.sa_mask);
    sa.sa_flags = 0;
    if (sigaction (SIGALRM, &sa, NULL) == -1)
    {
        die ("sigaction");
    }

    alarm (atoi (argv[1]));

    /* Calculate relative interval as current time plus number of seconds given argv[2] */
    if (clock_gettime (CLOCK_REALTIME, &ts) == -1)
    {
        die ("clock_gettime");
    }

    ts.tv_sec += atoi (argv[2]);
    printf ("main() about to call sem_timedwait()\n");
    while ((s = sem_timedwait (&sem, &ts)) == -1 && errno == EINTR)
    {
        continue;       /* Restart when interrupted by handler */
    }

    /* Check what happened */
    if (s == -1)
    {
        if (errno == ETIMEDOUT)
        {
            printf ("sem_timedwait() timed out\n");
        }
        else
        {
            die ("sem_timedwait");
        }
    }
    else
    {
        printf ("sem_timedwait() succeeded\n");
    }

    exit (EXIT_SUCCESS);
}

/* EOF */
