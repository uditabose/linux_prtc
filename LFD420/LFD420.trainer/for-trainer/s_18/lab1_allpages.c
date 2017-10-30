/* **************** LFD420:4.13 s_18/lab1_allpages.c **************** */
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
 * Gathering Memory Statistics
 *
 * There is a struct page for every physical page on the system, with
 * the exported symbol mem_map pointing to the page with PFN = 0;
 * there are num_physpages pages in total.

 * Write a module that works through the entire array and gathers
 * statistics on memory usage, reporting quantities such as free
 * pages, those used in slab caches, etc.
 *
 * To do this, you'll need to use the macros in
 * /usr/src/linux/include/linux/page-flags.h and the macro
 * pfn_to_page().
 *
 * Note that the best way to check if a page is free is to require
 * page_count(page) = 0.
 *
 *       Note: Before using pfn_to_page() you should make sure you
 *       have a valid page frame number with pfn_valid(unsigned long
 *       pfn).
 *
 *       On some systems with 4 GB of RAM or more, there may be some
 *       re-mapping which creates holes so that num_physpages is
 *       greater than the actual number of physical pages, depending
 *       on kernel configuration options.
 *
@*/
#include <linux/version.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/mm.h>

#define PRT(a, b) pr_info("%-15s=%10d %10ld %8ld\n", \
			 a, b, (PAGE_SIZE*b)/1024, (PAGE_SIZE*b)/1024/1024)

static int __init my_init(void)
{
	struct page *p;
	unsigned long pfn, valid = 0;
	int free = 0, locked = 0, reserved = 0, swapcache = 0,
	    referenced = 0, slab = 0, private = 0, uptodate = 0,
	    dirty = 0, active = 0, writeback = 0, mappedtodisk = 0;
	/* Note this appears only in 3.11 kernel, but RHEL6
	   3.10 kernel already has the function */
	unsigned long num_physpages;
	num_physpages = get_num_physpages();
	for (pfn = 0; pfn < num_physpages; pfn++) {
		/* may be holes due to remapping */
		if (!pfn_valid(pfn))
			continue;
		valid++;
		p = pfn_to_page(pfn);
		/* page_count(page) == 0 is a free page. */
		if (!page_count(p)) {
			free++;
			continue;
		}
		if (PageLocked(p))
			locked++;
		if (PageReserved(p))
			reserved++;
		if (PageSwapCache(p))
			swapcache++;
		if (PageReferenced(p))
			referenced++;
		if (PageSlab(p))
			slab++;
		if (PagePrivate(p))
			private++;
		if (PageUptodate(p))
			uptodate++;
		if (PageDirty(p))
			dirty++;
		if (PageActive(p))
			active++;
		if (PageWriteback(p))
			writeback++;
		if (PageMappedToDisk(p))
			mappedtodisk++;
	}

	pr_info("\nExamining %ld pages (num_phys_pages) = %ld MB\n",
		num_physpages, num_physpages * PAGE_SIZE / 1024 / 1024);
	pr_info("Pages with valid PFN's=%ld, = %ld MB\n", valid,
		valid * PAGE_SIZE / 1024 / 1024);
	pr_info("\n                     Pages         KB       MB\n\n");

	PRT("free", free);
	PRT("locked", locked);
	PRT("reserved", reserved);
	PRT("swapcache", swapcache);
	PRT("referenced", referenced);
	PRT("slab", slab);
	PRT("private", private);
	PRT("uptodate", uptodate);
	PRT("dirty", dirty);
	PRT("active", active);
	PRT("writeback", writeback);
	PRT("mappedtodisk", mappedtodisk);

	return 0;
}

static void __exit my_exit(void)
{
	pr_info("Module Unloading\n");
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_18/lab1_allpages.c");
MODULE_LICENSE("GPL v2");
