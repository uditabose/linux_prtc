/* **************** LFD420:4.13 s_11/lab1_mutex3.c **************** */
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
/* **************** LFD420:4.13 s_11/lab1_mutex2.c **************** */
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
 * Mutex Contention
 *
 * second and third module to test mutexes
 @*/

#include <linux/module.h>
#include <linux/init.h>
#include <linux/mutex.h>
#include <linux/atomic.h>
#include <linux/errno.h>

extern struct mutex my_mutex;

static int __init my_init(void)
{
	pr_info("Trying to load module %s\n", KBUILD_MODNAME);
#if 0
	/* this branch should hang if not available */
	if (mutex_lock_interruptible(&my_mutex)) {
		pr_info("mutex unlocked by signal in %s\n", KBUILD_MODNAME);
		return -EBUSY;
	}
#else
	/* this branch will return with failure if not available */
	if (!mutex_trylock(&my_mutex)) {
		pr_info("mutex_trylock failed in %s\n", KBUILD_MODNAME);
		return -EBUSY;
	}
#endif
	pr_info("\n%s mutex grabbed mutex\n", KBUILD_MODNAME);

	return 0;
}

static void __exit my_exit(void)
{
	mutex_unlock(&my_mutex);
	pr_info("\nUnlocking and Exiting from %s\n", KBUILD_MODNAME);
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Tatsuo Kawasaki");
MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_11/lab1_mutex2.c");
MODULE_LICENSE("GPL v2");
