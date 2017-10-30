/* **************** LFD420:4.13 s_05/lab3_module1.c **************** */
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
 * Modules and Exporting Symbols: Module 1
 *
 * Write a pair of modules where the second one calls a
 * function in the first one.
 *
 * Load them in the correct order and make sure all symbols are
 * resolved.
 *
 @*/

#include <linux/module.h>
#include <linux/init.h>

static int __init my_init(void)
{
	pr_info("Hello world from mod1\n");
	return 0;
}

static void __exit my_exit(void)
{
	pr_info("Goodbye world from mod1\n");
}

static void mod1fun(void)
{
	pr_info(" VOILA! I got into mod1fun\n");
}
EXPORT_SYMBOL(mod1fun);

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_05/lab3_module1.c");
MODULE_LICENSE("GPL v2");
