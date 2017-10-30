/* **************** LFD420:4.13 s_13/lab3_launch_cp.c **************** */
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
 * Launching User Mode Processes: (cp example)
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

static char *argv[] = { "cp", "/var/log/syslog", "/tmp/syslog", NULL };
static int __init my_init(void)
{
	static int j;

	pr_info("Trying to execute:");
	j = 0;
	while (argv[j])
		pr_info(" %s ", argv[j++]);
	pr_info("\n");

	if (call_usermodehelper("/bin/cp", argv, NULL, UMH_NO_WAIT))
		pr_info("Failed to make run the program\n");
	return 0;
}

static void __exit my_exit(void)
{
	pr_info("Unloading Module: %s\n", KBUILD_MODNAME);
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_13/lab3_launch_cp.c");
MODULE_LICENSE("GPL v2");
