/* **************** LFD420:4.13 s_24/lab4_signal_changes.c **************** */
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
/*  NOMAKE */
/* System call to Reset signal priority order */

asmlinkage long sys_setsigpriority(pid_t pid, char *sigpri_new)
{
	char *sigpri;
	struct task_struct *p;
	int j;

	/*
	 * TODO: The below is definitely _NOT_ SMP-safe; It needs some
	 * locks so race conditions don't happen
	 */

	p = current;
	if (pid)
		/*    p = find_task_by_vpid (pid); */
		p = pid_task(find_vpid(pid), PIDTYPE_PID);

	/* check we are the owner or are root */

	if ((current->euid != p->euid) && (current->euid != p->uid) &&
	    !capable(CAP_SYS_NICE))
		return -EPERM;

	sigpri = p->sigpri;
	if (copy_from_user(sigpri, sigpri_new, 64)) {
		pr_err
		    ("Failed to copy the new signal priorities into the task_struct\n");
		return -EFAULT;
	}
	pr_info("Reset the signal priorities for process %d\n", (int)p->pid);
	pr_info("New priority order is\n");
	for (j = 0; j < 64; j++) {
		pr_info("%3d", (int)p->sigpri[j]);
		if ((j % 16 == 0))
			pr_info("\n");
	}
	pr_info("\n");
	return 0;
}

/* Given the mask, find the first available signal that should be serviced. */

static int next_signal(struct sigpending *pending, sigset_t * mask)
{
	unsigned long i, *s, *m, x;
	int sig = 0;
	int sigtest, j;
	char *sigpri;

	sigpri = current->sigpri;
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

			sigtest = (int)sigpri[j];

			/* in the first word */

			if ((sigtest < _NSIG_BPW) &&
			    ((x = s[0] & ~m[0]) != 0) && (x & (1 << sigtest))) {
				sig = sigtest + 1;
				/*pr_info("j=%d, sig =%d, sigtest = %d\n", j,sig,sigtest); */
				goto out1;
			}
			/* in the second word */

			if ((sigtest >= _NSIG_BPW) &&
			    ((x = s[1] & ~m[1]) != 0) &&
			    (x & (1 << (sigtest - _NSIG_BPW)))) {
				sig = sigtest + 1;
				/*pr_info("j=%d, sig =%d, sigtest = %d\n", j,sig,sigtest); */
				goto out1;
			}
		}
		/*        pr_err("Failed find signal for j=%d,sigtest=%d\n", j,sigtest); */
	      out1:
		break;

	case 1:
		if ((x = *s & ~*m) != 0) {
			for (j = 0; j < _NSIG_BPW; j++) {
				sigtest = (int)sigpri[j];
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
