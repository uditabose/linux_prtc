/* **************** LFD420:4.13 s_12/lab2_percpu.c **************** */
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
 * Per Cpu Variables
 *
 * Write a trivial module that creates per-cpu variables, and modifies
 * and prints out their values.
 *
 * Try using both methods; a fixed allocation and a dynamical
 * allocation.
@*/

#include <linux/module.h>
#include <linux/init.h>
#include <linux/percpu.h>

static DEFINE_PER_CPU(long, cpuvar) = 10;
static long __percpu *cpualloc;

static DEFINE_SPINLOCK(dumb_lock);
static int which_cpu(void)
{
	int cpu;
	spin_lock(&dumb_lock);
	cpu = smp_processor_id();
	spin_unlock(&dumb_lock);
	return cpu;
}

static int __init my_init(void)
{
	int cpu;
	pr_info("cpuvar=%ld\n", get_cpu_var(cpuvar)++);
	cpu = which_cpu();
	put_cpu_var(cpuvar);
	cpualloc = alloc_percpu(long);
	*per_cpu_ptr(cpualloc, cpu) = 1000;
	pr_info("Hello: module loaded at 0x%p\n", my_init);
	return 0;
}

static void __exit my_exit(void)
{
	int cpu;
	pr_info("cpuvar=%ld\n", get_cpu_var(cpuvar));
	cpu = which_cpu();
	put_cpu_var(cpuvar);
	pr_info("per_cpu_ptr = %ld\n", *per_cpu_ptr(cpualloc, cpu));
	free_percpu(cpualloc);
	pr_info("Bye: module unloaded from 0x%p\n", my_exit);
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_12/lab2_percpu.c");
MODULE_LICENSE("GPL v2");
