/* **************** LFD420:4.13 s_10/lab2_sparse_corrected.c **************** */
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
/* Finding Errors With Sparse (FIXED SOLUTION 1)
 *
 * We give you a minimal module that compiles cleanly, but has at
 * least two errors that show up with the use of sparse.
 *
 * Install sparse according to the description given earlier and
 * correct the errors.
 *
 @*/
#include <linux/module.h>
#include <linux/init.h>
#include <linux/uaccess.h>

static void my_fun(char *buf1, char *buf2, int count, struct task_struct *s)
{
	memcpy(buf2, buf1, count);
}

static int __init my_init(void)
{
	int count = 32;
	char buf1[32], buf2[32];
	my_fun(buf1, buf2, count, NULL);
	return 0;
}

static void __exit my_exit(void)
{
}

module_init(my_init);
module_exit(my_exit);
MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_10/lab2_sparse_corrected.c");
