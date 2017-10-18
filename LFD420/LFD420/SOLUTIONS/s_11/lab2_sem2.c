/* **************** LFD420:4.13 s_11/lab2_sem3.c **************** */
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
/* **************** LFD420:4.13 s_11/lab2_sem2.c **************** */
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
 * Semaphore Contention
 *
 * second and third module to test semaphore contention.
 @*/

#include <linux/module.h>
#include <linux/init.h>
#include <linux/atomic.h>
#include <linux/errno.h>
#include <linux/version.h>
#include <linux/semaphore.h>

extern struct semaphore my_sem;

static int __init my_init(void)
{
	pr_info("Trying to load module %s\n", KBUILD_MODNAME);
	pr_info("semaphore_count=%u\n", my_sem.count);

#if 0
	/* this branch will return with failure if not available */
	if (down_trylock(&my_sem)) {
		pr_info("Not loading %s; down_trylock() failed\n",
			KBUILD_MODNAME);
		return -EBUSY;
	}
#else
	/* this branch should hang if not available */
	if (down_interruptible(&my_sem)) {
		pr_info("Not loading %s, interrupted by signal\n",
			KBUILD_MODNAME);
		return -EBUSY;
	}
#endif

	pr_info("\nGrabbed semaphore in %s, ", KBUILD_MODNAME);
	pr_info("semaphore_count=%u\n", my_sem.count);
	return 0;
}

static void __exit my_exit(void)
{
	up(&my_sem);
	pr_info("\nExiting semaphore in %s, ", KBUILD_MODNAME);
	pr_info("semaphore_count=%u\n", my_sem.count);
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_11/lab2_sem2.c");
MODULE_LICENSE("GPL v2");
