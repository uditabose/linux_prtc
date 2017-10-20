/************************************************************************/
/* Quellcode zum Buch                                                   */
/*                     Linux Treiber entwickeln                         */
/* (4. Auflage) erschienen im dpunkt.verlag                             */
/* Copyright (c) 2004-2015 Juergen Quade und Eva-Katharina Kunst        */
/*                                                                      */
/* This program is free software; you can redistribute it and/or modify */
/* it under the terms of the GNU General Public License as published by */
/* the Free Software Foundation; either version 2 of the License, or    */
/* (at your option) any later version.                                  */
/*                                                                      */
/* This program is distributed in the hope that it will be useful,      */
/* but WITHOUT ANY WARRANTY; without even the implied warranty of       */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the         */
/* GNU General Public License for more details.                         */
/*                                                                      */
/************************************************************************/
#include <linux/module.h>
#include <linux/sched.h>
#include <linux/slab.h>
#include <linux/kthread.h>
#include <linux/sched/signal.h>


static struct task_struct *thread_id1, *thread_id2;
DECLARE_COMPLETION( cmpltn );
static spinlock_t sl;

struct my_list {
	struct list_head link;
	int counter;
};
static struct my_list rootptr;

static int thread_code( void *data )
{
	int i;
	struct my_list *newelement;
	struct list_head *loopvar, *tmp;

	allow_signal( SIGTERM ); 
	pr_info("thread_code %d startet ...\n", current->pid );
	for( i=0; i<5; i++ ) {
		/*
		 * don't use kmalloc in a critical section!
		 */
		newelement = kmalloc( sizeof(struct my_list), GFP_USER );
		spin_lock( &sl );
		newelement->counter = i;
		pr_info( "element: %p- %d\n", newelement, i );
		list_add( &newelement->link, &rootptr.link );
		spin_unlock( &sl );
		pr_info("Thread %d: left critical section ...\n",current->pid);
	}
	/* clean up list */
	spin_lock( &sl );
	list_for_each_safe( loopvar, tmp, &rootptr.link ) {
		i = list_entry( loopvar, struct my_list, link )->counter;
		pr_info( "deleting %p - %d\n", loopvar, i );
		list_del( loopvar );
		kfree( loopvar );
	}
	spin_unlock( &sl );
	complete_and_exit( &cmpltn, 0 );
	return 0;
}

static int __init kthread_init(void)
{
	thread_id1=kthread_create(thread_code, NULL, "Thread1");
	INIT_LIST_HEAD( &rootptr.link );
	if( thread_id1 ) {
		thread_id2=kthread_create(thread_code, NULL, "Thread2");
		if( thread_id2 ) {
			wake_up_process( thread_id1 );
			wake_up_process( thread_id2 );
			return 0;
		}
		/* creation of threads failed */
	}
	return -EIO;
}

static void __exit kthread_exit(void)
{
	kill_pid( task_pid(thread_id1), SIGTERM, 1 );
	kill_pid( task_pid(thread_id2), SIGTERM, 1 );
	wait_for_completion( &cmpltn );
	wait_for_completion( &cmpltn );
}

module_init( kthread_init );
module_exit( kthread_exit );
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Demo fuer die Listenfunktionen im Linux-Kernel.");
