/* **************** LFD420:4.13 s_24/lab2_handler.c **************** */
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
 *
 * Suppose a running process has installed a signal handler and you
 * wish to switch it out on the fly, perhaps re-installing the default
 * handler for the signal.
 *
 * An example (which motivated this lab) is given in
 * http://jonebird.com/2007/06/21/stripping-another-process-of-its-signal-handler/,
 * where core dumps (SIGABRT) had been turned off and it was desired
 * to produce one.
 *
 * Write a module which takes as input parameters the process ID of
 * the process you want to interfere with, and the signal number which
 * you want to restore to its default behaviour.
 *
 * Try sending the signal before and after the module is installed and
 * note the difference.
 *
 * In order to do this you will need a short testing program which
 * installs a do-nothing signal handler function for the desired
 * signal.
 *
 * Note you will have to drill your way down from the task structure
 * to find out where the signal handler function is installed.  and
 * you wish to switch it out on the fly, perhaps re-installing the
 * default handler for the signal.
 *
 * It is also possible to accomplish this task completely from user
 * space by use of the LD_PRELOAD environmental variable to replace
 * signal handlers.  See man ld.so to see where to begin.
 *
@*/

#include <linux/module.h>
#include <linux/sched.h>
#include <linux/init.h>
#include <linux/version.h>
/* For changes in signal handler action struction location */
#include <linux/version.h>
#if LINUX_VERSION_CODE >= KERNEL_VERSION(4,11,0)
#include <linux/sched/signal.h>
#endif

static int pid = -1;
static int signo = SIGABRT;
module_param(pid, int, 0);
module_param(signo, int, 0);
static __sighandler_t old_handler;

static int __init my_init(void)
{
	unsigned long flags;
	/*    struct task_struct *p = find_task_by_vpid (pid); */
	struct task_struct *p = pid_task(find_vpid(pid), PIDTYPE_PID);
	if (!p) {
		pr_err("Invalid PID %d specified\n", pid);
		return -EINVAL;
	}
	spin_lock_irqsave(&p->sighand->siglock, flags);
	old_handler = p->sighand->action[signo - 1].sa.sa_handler;
	p->sighand->action[signo - 1].sa.sa_handler = SIG_DFL;
	spin_unlock_irqrestore(&p->sighand->siglock, flags);

	pr_info("Resetting process %s[%d] signal handler for %d to SIG_DFL\n",
		p->comm, p->pid, signo);
	return 0;
}

static void __exit my_exit(void)
{
	/*    struct task_struct *p = find_task_by_vpid (pid); */
	struct task_struct *p = pid_task(find_vpid(pid), PIDTYPE_PID);
	if (!p) {
		pr_err("PID %d already gone!\n", pid);
		return;
	}
	p->sighand->action[signo - 1].sa.sa_handler = old_handler;
	pr_info("Resetting process %s[%d] signal handler for %d to SIG_DFL\n",
		p->comm, p->pid, signo);
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jon Miller");
MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_24/lab2_handler.c");
MODULE_DESCRIPTION("Reverting signal handler for signal SIG_ABRT to SIG_DFL");
MODULE_LICENSE("GPL v2");
