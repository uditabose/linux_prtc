/* **************** LFD420:4.13 s_13/lab3_launch_wall.c **************** */
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
 * Launching User Mode Processes: (wall example)
 *
 * Write a kernel module that launches a user mode process.
 *
 * To do this you'll have to use the  call_usermodehelper() function.
 *
 * To begin with you can do something as simple as send a message
 * to everyone logged in with
 *
 *        wall message
 *
 * Once you get this working, try something fancier, such as copying a
 * file.
 *
 * Is it possible to redirect standard input/output while doing this?
@*/

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kmod.h>

static char *str;
module_param(str, charp, S_IRUGO);

static char *argv[] = { "wall", "This is a message from the Kernel", NULL };
static int __init my_init(void)
{
	int rc, j = 0;

	static char *envp[] = { NULL };
	if (str)
		argv[1] = str;

	pr_info("Trying to execute:");
	while (argv[j])
		pr_info(" %s ", argv[j++]);
	pr_info("\n");

	rc = call_usermodehelper("/usr/bin/wall", argv, envp, UMH_NO_WAIT);
	if (rc) {
		pr_info("Failed to execute %s %s\n", argv[0], argv[1]);
		return rc;
	}
	return 0;
}

static void __exit my_exit(void)
{
	pr_info("Unloading Module: %s\n", KBUILD_MODNAME);
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_13/lab3_launch_wall.c");
MODULE_LICENSE("GPL v2");
