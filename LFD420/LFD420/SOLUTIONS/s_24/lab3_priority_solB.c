/* **************** LFD420:4.13 s_24/lab3_priority_solB.c **************** */
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
 * Changing Signal Priorities. (Solution B)
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
	int sigtest, j;

	static int sigpri[_NSIG];
	static int sigpri_set = 0;

	/*
	 * sigpri is an array where sigpri[0]=k means
	 * highest priority for signal k
	 * The first time through we evaluate it.
	 */
#undef NORMAL_ORDER
	if (!sigpri_set) {
		for (j = 0; j < _NSIG; j++) {
#ifdef NORMAL_ORDER
			sigpri[j] = j;
#else
			sigpri[j] = _NSIG - j - 1;
#endif
		}
		sigpri_set = 1;
	}
	s = pending->signal.sig;

	m = mask->sig;
	switch (_NSIG_WORDS) {
	default:
		/* this isn't correct! have to finesse */
		for (i = 0; i < _NSIG_WORDS; ++i, ++s, ++m)
			if ((x = *s & ~*m) != 0) {
				sig = ffz(~x) + i * _NSIG_BPW + 1;
				break;
			}
		break;
	case 2:
		for (j = 0; j < _NSIG; j++) {

			sigtest = sigpri[j];

			/* in the first word */

			if ((sigtest < _NSIG_BPW) &&
			    ((x = s[0] & ~m[0]) != 0) && (x & (1 << sigtest))) {
				sig = sigtest + 1;
				/*pr_info("j=%d, sig =%d, sigtest = %d\n", j,sig,sigtest); */
				goto out1;
			}
			/* in the second word */

			if ((sigtest >= _NSIG_BPW) && ((x = s[1] & ~m[1]) != 0)
			    && (x & (1 << (sigtest - _NSIG_BPW)))) {
				sig = sigtest + 1;
				/* pr_info("j=%d, sig =%d, sigtest = %d\n", j,sig,sigtest); */
				goto out1;
			}
		}
	      out1:
		break;

	case 1:
		if ((x = *s & ~*m) != 0) {
			for (j = 0; j < _NSIG_BPW; j++) {
				sigtest = sigpri[j];
				if (x & (sigtest << 1)) {
					sig = sigtest + 1;
					break;
				}
			}
		}
		break;
	}

	return sig;
}
