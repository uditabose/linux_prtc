/* **************** LFD420:4.13 s_24/lab3_priority_solA.c **************** */
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
 *
 * Changing Signal Priorities. (Solution A)
 *
 * Under the simplest conditions, the kernel dispatches signals to
 * processes in the order in which the signals are received.
 *
 * However, sometimes multiple signals may be blocked for a
 * process. This may happen due to use of sigprocmask(), or when a
 * process is swapped out and multiple signals arrive before it
 * reacquires the CPU.  In these cases, when signal processing resumes
 * the signals are dispatched to the process using a signal selection
 * algorithm in the function next_signal() found in
 * kernel/signal.c. This algorithm selects signals by signal number in
 * ascending order, subject to the limitations of the signal mask.
 *
 * Modify the function next_signal() to select the highest numbered
 * signal first and so on; i.e., it should select signals using a
 * descending order sequence.
 *
 * To keep things simple, you may modify only the branch in
 * next_signal() that pertains to the architecture of your current
 * system: for x86, this means _NSIG_WORDS = 2.
 *
 * You may use the test programs from the first exercise to test your
 * changes to next_signal().
 *
 * Note that POSIX standards do not give complete freedom in the order
 * in which signals should be dealt with.  In particular, real time
 * signals should be dealt with from lowest to highest number, and if
 * more than one similar stop signal is received, only one may be
 * dealt with; the kernel has special handling in this case.
 *
 * You make want to make your changes to the kernel code in such a way
 * that the original algorithm is still used until you are satisfied
 * that the new algorithm works correctly.  Otherwise, the kernel will
 * not boot because signals must work in order to boot.
 *
 * Note: We present solutions as just the new next_signal() functions.
 */

/* Given the mask, find the first available signal that should be serviced. */

static int next_signal(struct sigpending *pending, sigset_t * mask)
{
	unsigned long i, *s, *m, x;
	int sig = 0;
	s = pending->signal.sig;
	m = mask->sig;
	switch (_NSIG_WORDS) {
	default:
		/* this isn't correct! have to finesse */
		for (i = 0; i < _NSIG_WORDS; ++i, ++s, ++m)
			if ((x = *s & ~*m) != 0) {
				sig = fls(x) + i * _NSIG_BPW;
				break;
			}
		break;

	case 2:
		if ((x = s[1] & ~m[1]) != 0)
			sig = _NSIG_BPW;
		else if ((x = s[0] & ~m[0]) != 0)
			sig = 0;
		else
			break;

		sig += fls(x);

		break;

	case 1:
		if ((x = *s & ~*m) != 0)
			sig = fls(x);
		break;
	}

	return sig;
}
