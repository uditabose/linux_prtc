/* **************** LFD420:4.13 s_20/lab3_maxvmalloc.c **************** */
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
 * Testing Maximum Memory Allocation (vmalloc)
 @*/

#include <linux/module.h>
#include <linux/init.h>
#include <linux/vmalloc.h>

static int mem = 64;
module_param(mem, int, S_IRUGO);

#define MB (1024*1024)

static int __init my_init(void)
{
	static char *vm_buff;
	long size;

	/* try vmalloc */

	for (size = 4 * MB; size <= mem * MB; size += 4 * MB) {
		pr_info(" pages=%6ld, size=%8ld ", size / PAGE_SIZE, size / MB);
		vm_buff = vmalloc(size);
		if (!vm_buff) {
			pr_err("... vmalloc failed\n");
			break;
		}
		pr_info("... vmalloc OK\n");
		vfree(vm_buff);
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
MODULE_DESCRIPTION("LFD420:4.13 s_20/lab3_maxvmalloc.c");
MODULE_LICENSE("GPL v2");
