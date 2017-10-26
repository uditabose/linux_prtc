/* **************** LFD420:4.13 s_05/lab2_utsname.c **************** */
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
 * Getting System Information

 * System information is readily obtained with the command uname -a
 * Write a kernel module that returns the same information.
 *
 * You'll have to examine and print out the fields in a structure of
 * type new_utsname, as defined in
 * /usr/src/linux/include/linux/utsname.h. This can be accessed
 * through the name element in the exported structure init_uts_ns,
 * or through the inline function init_utsname() defined in
 * include/linux/utsname.h.
 *
 * Compare your results with the results of uname -a.
 */

#include <linux/module.h>
#include <linux/init.h>
#include <linux/utsname.h>

static int __init my_init(void)
{
	/* either method works, but the first shows exports */
	/*	struct new_utsname *utsname = &init_uts_ns.name; */
	struct new_utsname *utsname = init_utsname();

	pr_info("============================\n");
	pr_info("sysname    = %s\n"
		"nodename   = %s\n"
		"release    = %s\n"
		"version    = %s\n"
		"machine    = %s\n"
		"domainname = %s\n",
		utsname->sysname, utsname->nodename, utsname->release,
		utsname->version, utsname->machine, utsname->domainname);

	return 0;
}

static void __exit my_exit(void)
{
	pr_info("Module Unloading\n");
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_05/lab2_utsname.c");
MODULE_LICENSE("GPL v2");
