/* **************** LFD420:4.13 s_20/lab1_cache.c **************** */
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
 * Making a Private Memory Cache.
 *
 * Write a module that allocates a buffer by using your own memory
 * cache.
 *
 * The size of the objects can be an optional parameter supplied when
 * loading the module.
 *
 * Set up the cache and allocate at least one object when loading the
 * module.
 *
 * Make sure you free up the object(s) and then the cache when
 * unloading the module.
 *
 * Make sure you free any objects you create, as well as the
 * memory cache itself. If you don't, the driver won't unload.
@*/

#include <linux/module.h>
#include <linux/mm.h>
#include <linux/slab.h>
#include <linux/init.h>

static char *kbuf;
static int size = 21*PAGE_SIZE;
static struct kmem_cache *my_cache;
module_param(size, int, S_IRUGO);

static int __init my_init(void)
{
	/* create a memory cache */
	pr_info("==================================\n");
	if (size > (1024 * PAGE_SIZE)) {
		pr_err
		    (" size=%d is too large; you can't have more than 1024 pages!\n",
		     size);
		return -1;
	}
	/* before 2.6.23 there was a destructor method also */
	my_cache = kmem_cache_create("mycache", size, 0,
				     SLAB_HWCACHE_ALIGN, NULL);
	if (!my_cache) {
		pr_err("kmem_cache_create failed\n");
		return -ENOMEM;
	}
	pr_info("allocated memory cache correctly\n");

	/* allocate a memory cache object */

	kbuf = kmem_cache_alloc(my_cache, GFP_ATOMIC);
	if (!kbuf) {
		pr_err(" failed to create a cache object\n");
		(void)kmem_cache_destroy(my_cache);
		return -1;
	}
	pr_info(" successfully created a cache object\n");
	return 0;
}

static void __exit my_exit(void)
{
	/* destroy a memory cache object */
	kmem_cache_free(my_cache, kbuf);
	pr_info("destroyed a memory cache object\n");

	/* destroy the memory cache */
	(void)kmem_cache_destroy(my_cache);
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_20/lab1_cache.c");
