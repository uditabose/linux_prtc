/* **************** LFD420:4.13 s_09/lab1_syscall_module.c **************** */
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
 *  LAB: Adding Dynamic System Calls. (KERNEL MODULE)
 *
 *
 * Extend the Linux kernel with a patch that adds one (or more) new
 * system calls, whose work can be implemented through modules.
 *
 * These dynamic system calls should make use of an exported
 * structure, one of whose elements is a function pointer which can be
 * filled in by a module.
 *
 * You'll also have to write a program to exercise the new system
 * call, which can do something trivial.
 *
 * The solution is given in the form of a patch that will work on both
 * the 32- and 64-bit x86 architectures.  In the later case we haven't
 * gone to the further trouble to also patch the kernel to handle
 * running 32-bit binaries. To apply the patch you'll need to do:
 *
 *    cd <kernel source>
 *   patch --dry-run -p1 < lab_syscall_patch
 *
 * Make sure the patch works first with the --dry-run option and then
 * remove it.  Different kernel versions may require some minor
 * adjustments.
 *
 * Warning: you won't be able to compile the test program unless you
 * either define the new system call number in the testing program, or
 * you point to the modify headers in the kernel source rather than
 * those under /usr/include.  With the genmake script you can do this
 * with:
 *
 *   $ CPPFLAGS=-I/lib/modules/$(uname -r)/build/arch/x86/include/generated/uapi ../genmake
@*/

#include <linux/module.h>
#include <linux/init.h>
#include <linux/unistd.h>

void *save_stub;

struct my_sc_struct {
	long (*fun) (unsigned long p1);
};

extern struct my_sc_struct my_sc;

static long test_syscall(unsigned long p1)
{
	long rc;
	rc = 100 * p1;
	pr_info("in test_syscall, p1, rc= %ld, %ld\n", p1, rc);
	return rc;
}

static int __init my_init(void)
{
	struct my_sc_struct *s = &my_sc;
	pr_info("Loading module\n");
	pr_info("s->fun = %p\n", s->fun);
	save_stub = s->fun;
	s->fun = test_syscall;
	pr_info("s->fun = %p\n", s->fun);
	return 0;
}

static void __exit my_exit(void)
{
	struct my_sc_struct *s = &my_sc;
	pr_info("Unloading module\n");
	pr_info("s->fun = %p\n", s->fun);
	s->fun = save_stub;
	pr_info("Restored the original system call");
	pr_info("s->fun = %p\n", s->fun);
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_09/lab1_syscall_module.c");
MODULE_LICENSE("GPL v2");
