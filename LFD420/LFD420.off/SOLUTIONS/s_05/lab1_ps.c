/* **************** LFD420:4.13 s_05/lab1_ps.c **************** */
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
 * Iterating over processes
 *
 * Write a module that uses the for_each_process() macro to generate
 * some of the information obtained from the ps command.
 *
 * For each task, printout the process ID, state, command line and any
 * other interesting information.
 *
 * You can get the definition of the fields in the task_struct from
 * linux/sched.h.
 *
 * Don't forget to take out appropriate locks.
 *
@*/
#include <linux/module.h>
#include <linux/init.h>
#include <linux/sched.h>
#include <linux/oom.h>

static int __init my_init(void)
{
	struct task_struct *p;
	pr_info("Mini ps: pid, command, state\n\n");

	for_each_process(p) {
		pr_info("pid=%d, comm=%s, state=%ld\n",
			p->pid, p->comm, p->state);
	}
	return 0;
}

static void __exit my_exit(void)
{
	pr_info("Module Unloading\n");
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_05/lab1_ps.c");
MODULE_LICENSE("GPL v2");
