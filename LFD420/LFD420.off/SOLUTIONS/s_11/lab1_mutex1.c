/* **************** LFD420:4.13 s_11/lab1_mutex1.c **************** */
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
 *
 * Write three simple modules where the second and third one use a
 * variable exported from the first one. The second and third one can
 * be identical; just give them different names.
 *
 * Hint: You can use KBUILD_MODNAME to print out the module name.
 *
 * You can implement this by making small modifications to your
 * results from the modules exercise.
 *
 * The exported variable should be a mutex. Have the first module
 * initialize it in the unlocked state.
 *
 * The second (third) module should attempt to lock the mutex and if
 * it is locked, either fail to load or hang until the mutex is
 * available; make sure you return the appropriate value from your
 * initialization function.
 *
 * Make sure you release the mutex in your cleanup function.
 *
 * Test by trying to load both modules simultaneously, and see if it
 * is possible. Make sure you can load one of the modules after the
 * other has been unloaded, to make sure you released the mutex
 * properly.
 @*/

#include <linux/module.h>
#include <linux/init.h>

DEFINE_MUTEX(my_mutex);
EXPORT_SYMBOL(my_mutex);

static int __init my_init(void)
{
	pr_info("\nInit mutex in unlocked state in %s\n", KBUILD_MODNAME);
	return 0;
}

static void __exit my_exit(void)
{
	pr_info("\nExiting from %s\n", KBUILD_MODNAME);
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_11/lab1_mutex1.c");
MODULE_LICENSE("GPL v2");
