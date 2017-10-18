/* **************** LFD420:4.13 s_09/lab1_syscall_test.c **************** */
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
 *  LAB: Adding Dynamic System Calls. (Testing Program)
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
 *   $ CPPFLAGS=-I/lib/modules/$(uname -r)/build/arch/x86/include/generated/uapi ../genmake *
@*/

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/syscall.h>
#include <unistd.h>

#define my_syscall(a) syscall(__NR_my_syscall,a)

int main(int argc, char *argv[])
{

	unsigned long p1 = 1;
	long rc;
	printf("\nDoing my_syscall1, p1 = %ld\n", p1);
	rc = my_syscall(p1);
	printf("\nReturned my_syscall, p1 = %ld, rc = %ld\n", p1, rc);

	exit(EXIT_SUCCESS);
}
