/* **************** LF331:3.12 s_05/lab_miscdev.h **************** */
/*
 * The code herein is: Copyright the Linux Foundation, 2013
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
 @*/
#ifndef _LAB_CHAR_H
#define _LAB_CHAR_H

#include <linux/module.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/sched.h>
#include <linux/init.h>
#include <linux/slab.h>
#include <linux/device.h>
#include <linux/miscdevice.h>

#define MYDEV_NAME "kmalloc_test"

static struct device *my_dev;
static char *ramdisk;
static size_t ramdisk_size = (16 * PAGE_SIZE);

static const struct file_operations mycdrv_fops;

/* generic entry points */

static inline int mycdrv_generic_open(struct inode *inode, struct file *file)
{
	dev_info(my_dev, "ref=%d\n", (int)module_refcount(THIS_MODULE));

	return 0;
}

static inline int mycdrv_generic_release(struct inode *inode, struct file *file)
{
	dev_info(my_dev, " closing device: %s:\n\n", MYDEV_NAME);
	return 0;
}
/* just to show how to use the simple_read/write functions */

static inline ssize_t mycdrv_generic_read(struct file *file, char __user *buf,
					  size_t lbuf, loff_t *ppos)
{
	int nbytes =
	    simple_read_from_buffer(buf, lbuf, ppos, ramdisk, ramdisk_size);
	dev_info(my_dev, "Leaving the   READ function, nbytes=%d, pos=%d\n",
		 nbytes, (int)*ppos);
	return nbytes;

}
static inline ssize_t mycdrv_generic_write(struct file *file,
					   const char __user *buf, size_t lbuf,
					   loff_t *ppos)
{
	int nbytes =
	    simple_write_to_buffer(ramdisk, ramdisk_size, ppos, buf, lbuf);
	dev_info(my_dev, "Leaving the   WRITE function, nbytes=%d, pos=%d\n",
		 nbytes, (int)*ppos);
	return nbytes;
}
static inline loff_t mycdrv_generic_lseek(struct file *file, loff_t offset,
					  int orig)
{
	loff_t testpos;
	switch (orig) {
	case SEEK_SET:
		testpos = offset;
		break;
	case SEEK_CUR:
		testpos = file->f_pos + offset;
		break;
	case SEEK_END:
		testpos = ramdisk_size + offset;
		break;
	default:
		return -EINVAL;
	}
	testpos = testpos < ramdisk_size ? testpos : ramdisk_size;
	testpos = testpos >= 0 ? testpos : 0;
	file->f_pos = testpos;
	dev_info(my_dev, "Seeking to pos=%ld\n", (long)testpos);
	return testpos;
}

static struct miscdevice my_misc_device = {
	.minor = MISC_DYNAMIC_MINOR,
	.name = MYDEV_NAME,
	.fops = &mycdrv_fops,
};

static int __init my_generic_init(void)
{
	ramdisk = kmalloc(ramdisk_size, GFP_KERNEL);
	if (misc_register(&my_misc_device)) {
		pr_err("Couldn't register device misc, ");
		pr_err("%d.\n", my_misc_device.minor);
		kfree(ramdisk);
		return -EBUSY;
	}
	my_dev = my_misc_device.this_device;
	dev_info(my_dev, "Succeeded in registering device %s\n", MYDEV_NAME);
	return 0;
}

static void __exit my_generic_exit(void)
{
	dev_info(my_dev, "Unregistering Device\n");
	misc_deregister(&my_misc_device);
	kfree(ramdisk);
}
/*
MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LF331:3.12 s_05/lab_miscdev.h");
MODULE_LICENSE("GPL v2");
*/
#endif
