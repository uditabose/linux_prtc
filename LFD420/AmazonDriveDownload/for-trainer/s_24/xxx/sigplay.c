// sigplay.c --- illustrate some aspects of Linux signals.
//
//  Illustrate setting up handlers for "normal" and "real time" signals.
//   (Note:  the uses of the siginfo_t struct passed to real time
//    signal handlers is left as an exercise ...)
//
//  Set up a test to illustrates the need to protect data structures
//    from concurrent updates by the process thread and the process's
//    signal handlers.
//
//  The simulation is done by forking of child processes, each of which
//    repeatedly sends a designated signal to the parent many times at
//    random, asynchronous intervals
//
//  During one test run, the parent process BLOCKS relevant signals
//    while simulating a process-level update of the data structure.
//
//  During the other test run, the parent does NOT block relevant signals,
//    so we may see whether corruption can happen (and can be protected
//    against).
//
//  As part of setting up the framework for the two test runs, this program
//    necessarily demonstrates some other aspects of Linux user-space
//    programming, e.g. SIGCHLD, waitpid(2), and so forth.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>

// protected_struct --- this is the data structure that will be subjected
//   to simulated concurrent updates by the process thread and its
//   signal handlers.
struct protected_struct {
        // process_is_touching -- set TRUE when main-line process
        //    is doing a simulated update.  It signals are blocked,
        //    then no signal handler should see this be TRUE.
	volatile int process_is_touching;
	int num_normal_signals;
	int num_normal_handler_breakage;
	int num_rt_signals;
	int num_rt_handler_breakage;
} sp;

pid_t   parent_pid;

// normal_signal_handler and real_time_signal_handler:
//    signal handler functions that simulate concurrent updates of the
//    simple data structure used in this program
void normal_signal_handler(int signo)
{
	if (sp.process_is_touching) {
		++sp.num_normal_handler_breakage;
	}
	++sp.num_normal_signals;
}

void real_time_signal_handler(int signo, siginfo_t * sinfo, void *empty)
{
	if (sp.process_is_touching) {
		++sp.num_rt_handler_breakage;
	}
	++sp.num_rt_signals;
}

// sigs_to_catch[] --- array of some specific signals used in this
//   demonstration program
// NOTE:  in some implementations SIGRTMIN is not a constant.  Use
//   NEGATIVE number to denote an RT signal value -- patch later.
int sigs_to_catch[] = {
	SIGQUIT, 
        SIGUSR1, 
        -4,  // patch to SIGRTMIN + 4, 
        -5,  // patch to SIGRTMIN + 5,
        SIGUSR2,
        -8,  // patch to SIGRTMIN + 8
        0    // mark end of array
};

// kid_procs_running --- incremented at each fork(), decremented at
//    each waitpid()
//   
int kid_procs_running;

void sigchld_handler(int signo)
{
	int status;

	// reap the status of ALL children who have exited, or been
	//   terminated, but just toss the specific exit codes.
	while (1) {
		if (waitpid(-1, &status, WNOHANG) <=0) {
			// no more childern have changed state
			break;
		}
		if (WIFEXITED(status) || WIFSIGNALED(status)) {
			// child terminated or exited
			--kid_procs_running;
			// stay in loop --- there MAY be more than one
		}
	}
}


// Mechanism to delay for random small intervals.
#define MIN_NANOSECONDS_TO_DELAY  100000
#define MAX_NANOSECONDS_TO_DELAY  500000
#define NANOSECDIFF (MAX_NANOSECONDS_TO_DELAY - MIN_NANOSECONDS_TO_DELAY)

int num_nanosleep_restarts;
int num_nanosleep_restarts_while_updating;

void delay_small_random_interval(void)
{
        struct timespec requested, remaining;

        requested.tv_sec = 0;
        requested.tv_nsec = (random() % NANOSECDIFF) + 
                MIN_NANOSECONDS_TO_DELAY;
        
        // This is important:  nanosleep(2) can be interrupted by
        //  handling a signal, which is a likely occurrence in this
        //  program.  Check the return value, and if non-zero,
        //  issue another nanosleep(2) call to wait the remaining time.
        // In fact, using nanosleep() inside a simulated update is
        //  a MAGNET for signal handlers to run, for the simple reason
        //  that the kernel will wake a process blocked in the kernel
        //  right away to "steer" the process thread to handle the
        //  signal.  (If the process thread is doing something other
        //  than sleeping, it might not be preempted right away, making
        //  it more likely that a main-thread structure update can
        //  escape interruption without taking the step of blocking
        //  signals.)
        while (1) {
                if (nanosleep(&requested, &remaining) == 0) {
                        return;  // we completed the entire interval
                }
                // keep count of times we were interrupted inside nanosleep.
                ++num_nanosleep_restarts;
                // also count interruptions of main thread's update
                if (sp.process_is_touching && getpid() == parent_pid) {
                        ++num_nanosleep_restarts_while_updating;
                }
                requested = remaining;  // try to sleep the remaining time
        }
}


// sigs_to_block_when_protecting_code_region --- a sigset_t of
//   signals will will block during the test run where we actually
//   protect the data structure being tested.
sigset_t  sigs_to_block_when_protecting_code_region;

/**********************************************
 *
 *  parent_thread_test_loop() --  Parent thread
 *        runs this during a test run.  If
 *        protect_code_region is TRUE, then
 *        attempt to block signals while SIMULATING
 *        a slow update of the data structure.
 *
 *    If do_protection is FALSE we do NOT
 *        protect the code region, in order to
 *        measure the consequences.
 *
 ***********************************************/
void parent_thread_test_loop(int do_protection)
{
        sigset_t  old_sigset;

        while (kid_procs_running > 0) {
                delay_small_random_interval();

                if (do_protection) {
                        sigprocmask(SIG_BLOCK,
                                    &sigs_to_block_when_protecting_code_region,
                                    &old_sigset);
                }
                // simulate taking some time updating the data structure
                //  set 'process_is_touching' so that we may detect breakage.
                //  As noted elsewhere, blocking the process thread in
                //  the kernel will make it more likely that a sent signal
                //  will be accepted for processing.  This is good for
                //  tests like this, as it sets a situation where we're
                //  likely to be interrupted updating the struct, so we
                //  can better see if blocking sigs is actually effective.
                sp.process_is_touching = 1;
                delay_small_random_interval();
                sp.process_is_touching = 0;
                
                if (do_protection) {
                        sigprocmask(SIG_SETMASK, &old_sigset, NULL);
                }
        }
}


/*
 *   child_process_loop() --- run as a child of the parent.  Send
 *     the designated signal to the parent at short intervals
 *     until 1000 signals have been sent.  Exit when done.
 */
void child_process_loop(int designated_signal)
{
        int loops;

        // re-initialize the random number generator for THIS process
        srandom(getpid());

        for (loops = 0; loops < 1000; loops++) {
                delay_small_random_interval();
                (void) kill(getppid(), designated_signal);
        }
        _exit(0);  // child process terminates when done
}

/*
 *  run_the_test() --- run the test, either protecting the code
 *    region against signals sent by the child processes, or not.
 *
 *    PRINT THE TEST RUN RESULTS at completion.
 */
void run_the_test(int do_protection)
{
        int i;
        int kidpid;

        // zero out the struct we simulate protecting for each test run
        memset(&sp, 0, sizeof(sp));

        // zero count of times nanosleep(2) restarted
        num_nanosleep_restarts = 0;
        num_nanosleep_restarts_while_updating = 0;

        // start the child processes, one for each signal
        //  we've chosen to punish us.
        kid_procs_running = 0;
        for (i = 0; sigs_to_catch[i] > 0; i++) {
                if ((kidpid = fork()) < 0) {
                        // too tired now to watch for EAGAIN, but
                        //  a production program should retry fork()
                        //  if it temporarily fails.
                        fprintf(stderr, "fork failed:  giving up.  There"
                                " MAY be orphaned child procs\n");
                        exit(1);
                }
                if (kidpid == 0) {
                        child_process_loop(sigs_to_catch[i]);
                }
                // parent --- increment count of kids running
                ++kid_procs_running;
        }
        // now run the parent process loop, simulating updates of
        //  the data structure.
        parent_thread_test_loop(do_protection);

        // sll child processes have exited.  print results of test run.
        printf("Test results when %sblocking signals\n",
               do_protection ? "" : "NOT ");
        printf("  num_normal_signals received:  %d\n",
               sp.num_normal_signals);
        printf("      num_normal_handler_breakage:  %d\n",
               sp.num_normal_handler_breakage);
        printf("  num_rt_signals received:  %d\n",
               sp.num_rt_signals);
        printf("      num_rt_handler_breakage:  %d\n",
               sp.num_rt_handler_breakage);
        printf("num_nanosleep_restarts:  %d\n", num_nanosleep_restarts);
        printf("num_nanosleep_restarts_while_updating:  %d\n",
               num_nanosleep_restarts_while_updating);
        printf("================\n");
}

int main(void)
{
        int i;

        parent_pid = getpid();

        srandom(getpid());
        struct sigaction sa;

        // activate the SIGCHLD handler we use to reap child processes
        //   during each test run.
        memset(&sa, 0, sizeof(sa));
        sa.sa_handler = sigchld_handler;
        (void) sigaction(SIGCHLD, &sa, NULL);

        // construct the set of sigs to block during the test loop
        //  there we protect the code region.  Also, activate the
        //  signal handlers we will use for this test.  Note that
        //  we have to patch up the array values that are meant
        //  to denote RT signals
        sigemptyset(&sigs_to_block_when_protecting_code_region);
        for (i = 0; sigs_to_catch[i] != 0; i++) {

                if (sigs_to_catch[i] < 0) {
                        // patch value
                        sigs_to_catch[i] = SIGRTMIN + -(sigs_to_catch[i]);
                }

                sigaddset(&sigs_to_block_when_protecting_code_region,
                          sigs_to_catch[i]);

                memset(&sa, 0, sizeof(sa));
                if (sigs_to_catch[i] >= SIGRTMIN)
                        sa.sa_sigaction = real_time_signal_handler;
                else
                        sa.sa_handler = normal_signal_handler;
                (void) sigaction(sigs_to_catch[i], &sa, NULL);
        }

        run_the_test(0);  // test without protecting the code region
        run_the_test(1);  // re-run test, this time protecting the region

        return 0;
}
