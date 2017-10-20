/*
 * kvalloc.c
 * Testing vmalloc limits...
 *
 * Author:      Robert Berger
 *              Kaiwan N Billimoria
 *              Jerry Cooperstein
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <linux/module.h>
#include <linux/vmalloc.h>
#include "misc_vmalloc.h"

/*
 * This kernel module also demos the common technique of having a global
 * "(device) context" structure, whose pointer is passed around.
 * This also has the advantage of, when debugging, getting to all relevant
 * info via a single pointer!
 *
 * Our context structure
 *
 * */
typedef struct _ST_CTX {
	u32 kvalloc;             /* # bytes to alloc */
	u32 *vm;                 /* address to alloc at */
	char *vname;
} ST_CTX, *PST_CTX;
static PST_CTX gpstCtx;

/*
 * Poke some mem locations.
 * */
static int do_something(void *kvm, u32 len)
{
	void *x;
	if ((kvm == NULL) || (len == 0))
	   return -1;

	for (x = kvm; x < (kvm+len); x += PAGE_SIZE)
	   memset(x, 0xff, 0x10);

	return 0;
}


static inline ssize_t mycdrv_read(struct file *file, char __user *buf,
					  size_t lbuf, loff_t *ppos)
{
	PST_CTX pstCtx = (PST_CTX)buf;
	int n;

	dev_info(my_dev, "Reading!!!");

	n = sprintf(buf, "[%s] Last attempted to allocate via vmalloc: %u bytes\
				(%u Kb, %u MB).\n",
				MYDEV_NAME,
				pstCtx->kvalloc,
				pstCtx->kvalloc/1024,
				pstCtx->kvalloc/(1024*1024));
	return n;

}

static inline ssize_t mycdrv_write(struct file *file, const char __user *buf,
				   size_t lbuf, loff_t *ppos)
{
	PST_CTX pstCtx = (PST_CTX)buf;
	int sz = 18, /* # of digits (=bytes written in) */ status = sz;
	char kbuf[sz+1];

	if (lbuf > sz) {
		dev_info(my_dev, "writing a number > %d digits is invalid\n",
				  sz);
		status = -EINVAL;
		goto out_inval;
	}

	if (copy_from_user(kbuf, buf, sz)) {
		dev_info(my_dev, "copy_from_user() failed!\n");
		status = -EIO;
		goto out_inval;
	}

	kbuf[sz+1] = '\0';

	pstCtx->kvalloc = simple_strtoul(kbuf, NULL, 10);
	if (0 == pstCtx->kvalloc) {
		dev_info(my_dev, "writing invalid numeric value \"%.*s\",aborting...\n",
				  (int)lbuf, kbuf);
		status = -EINVAL;
		goto out_inval;
	}

	pstCtx->vm = vmalloc(pstCtx->kvalloc);
	if (!pstCtx->vm) {
		dev_info(my_dev, "vmalloc of %u bytes FAILED!\n",
				pstCtx->kvalloc);
		status = -ENOMEM;
		goto out_inval;
	}

	dev_info(my_dev, "Successfully allocated via vmalloc %u bytes\n",
			  pstCtx->kvalloc);
	dev_info(my_dev, "(%u Kb) now to location 0x%08x (will kfree..)\n",
			pstCtx->kvalloc/1024,
			(u32)pstCtx->vm);
	do_something(pstCtx->vm, pstCtx->kvalloc);
	vfree(pstCtx->vm);

out_inval:
	return status;
}


static const struct file_operations mycdrv_fops = {
	.owner = THIS_MODULE,
	.read = mycdrv_read,
	.write = mycdrv_write,
	.open = mycdrv_generic_open,
	.release = mycdrv_generic_release,
	.llseek = mycdrv_generic_lseek,
};

static int __init my_init(void)
{
	int status = 0;
	gpstCtx = kzalloc(sizeof(ST_CTX), GFP_KERNEL);
	if (!gpstCtx) {
		dev_info(my_dev, "kmalloc 1 failed, aborting..\n");
		status = -ENOMEM;
		goto out_k1_fail;
	}
	gpstCtx->vname = kmalloc(128, GFP_KERNEL);
	if (!gpstCtx->vname) {
		dev_info(my_dev, "kmalloc 2 failed, aborting..\n");
		status = -ENOMEM;
		goto out_k2_fail;
	}
	strncpy(gpstCtx->vname, "driver/vmalloc_test", 128);

	return my_generic_init();
out_k2_fail:
	kfree(gpstCtx);
out_k1_fail:
	return status;
}

static void __exit my_exit(void)
{
	kfree(gpstCtx->vname);
	kfree(gpstCtx);
	my_generic_exit();
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Robert Berger , Kaiwan N Billimoria, Jerry Cooperstein");
MODULE_DESCRIPTION("vmalloc misc char driver");
MODULE_LICENSE("GPL v2");
