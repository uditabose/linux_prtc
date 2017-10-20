/* **************** LFD420:4.13 s_09/submodule_noexport.c **************** */
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
#include <linux/module.h>
#include <linux/init.h>
#include <asm/unistd.h>

static void **sys_call_table;

static asmlinkage ssize_t(*old_sys_read) (unsigned int fd,
                                          char __user * buf, size_t count);
static asmlinkage ssize_t my_sys_read(unsigned int fd,
                                      char __user * buf, size_t count)
{
        pr_info(" Entering my_sys_read on fd=%d\n", fd);
        return old_sys_read(fd, buf, count);
}

static unsigned long address = 0xc0406820UL;
module_param(address, ulong, S_IRUGO);

static int __init my_init(void)
{
        pr_info("Loading module\n");
        sys_call_table = (void **)address;
        old_sys_read = sys_call_table[__NR_read];
        pr_info("old_sys_read=%p\n", old_sys_read);
        sys_call_table[__NR_read] = my_sys_read;
        return 0;
}

static void __exit my_exit(void)
{
        pr_info("Unloading module\n");
        sys_call_table[__NR_read] = old_sys_read;
        pr_info("Restored the original system call");
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("GPL v2");
