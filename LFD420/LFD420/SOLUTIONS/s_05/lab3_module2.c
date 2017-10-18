/* **************** LFD420:4.13 s_05/lab3_module2.c **************** */
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
 * Modules and Exporting Symbols: Module 2
 *
 * Write a pair of modules where the second one calls a
 * function in the first one.

 * Load them in the correct order and make sure all symbols are
 * resolved.
 @*/

#include <linux/module.h>
#include <linux/init.h>

void mod1fun(void);

static int __init my_init(void)
{
	pr_info("Hello world from mod2\n");
	mod1fun();
	return 0;
}

static void __exit my_exit(void)
{
	pr_info("Goodbye world from mod2\n");
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_05/lab3_module2.c");
MODULE_LICENSE("GPL v2");
