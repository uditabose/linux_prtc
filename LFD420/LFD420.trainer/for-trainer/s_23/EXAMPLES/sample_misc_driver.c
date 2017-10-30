/* **************** LFD420:4.13 s_23/sample_misc_driver.c **************** */
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
Sample Misc Character Driver 
@*/

#include <linux/module.h>	/* for modules */
#include <linux/fs.h>		/* file_operations */
#include <linux/uaccess.h>	/* copy_(to,from)_user */
#include <linux/init.h>		/* module_init, module_exit */
#include <linux/slab.h>		/* kmalloc */
#include <linux/device.h>
#include <linux/miscdevice.h>

#define MYDEV_NAME "mycdrv"

static struct device *my_dev;
static char *ramdisk;
static size_t ramdisk_size = (16 * PAGE_SIZE);

static int mycdrv_open(struct inode *inode, struct file *file)
{
	dev_info(my_dev, " OPENING device: %s:\n\n", MYDEV_NAME);
	return 0;
}

static int mycdrv_release(struct inode *inode, struct file *file)
{
	dev_info(my_dev, " closing device: %s:\n\n", MYDEV_NAME);
	return 0;
}

static ssize_t
mycdrv_read(struct file *file, char __user * buf, size_t lbuf, loff_t * ppos)
{
        int nbytes;
        if ((lbuf + *ppos) > ramdisk_size) {
                dev_info(my_dev, "trying to read past end of device,"
                        "aborting because this is just a stub!\n");
                return 0;
        }
        nbytes = lbuf - copy_to_user(buf, ramdisk + *ppos, lbuf);
        *ppos += nbytes;
        dev_info(my_dev, "\n READING function, nbytes=%d, pos=%d\n", nbytes, (int)*ppos);
        return nbytes;
}



static ssize_t
mycdrv_write(struct file *file, const char __user * buf, size_t lbuf,
             loff_t * ppos)
{
        int nbytes;
        if ((lbuf + *ppos) > ramdisk_size) {
                dev_info(my_dev, "trying to write past end of device,"
                        "aborting because this is just a stub!\n");
                return 0;
        }
        nbytes = lbuf - copy_from_user(ramdisk + *ppos, buf, lbuf);
        *ppos += nbytes;
        dev_info(my_dev, "\n WRITING function, nbytes=%d, pos=%d\n", nbytes, (int)*ppos);
        return nbytes;
}

static const struct file_operations mycdrv_fops = {
	.owner = THIS_MODULE,
	.read = mycdrv_read,
	.write = mycdrv_write,
	.open = mycdrv_open,
	.release = mycdrv_release,
};

static struct miscdevice my_misc_device = {
	.minor = MISC_DYNAMIC_MINOR,
	.name = MYDEV_NAME,
	.fops = &mycdrv_fops,
};

static int __init my_init(void)
{
	ramdisk = kmalloc(ramdisk_size, GFP_KERNEL);
	if (misc_register(&my_misc_device)) {
		pr_err("Couldn't register device misc, %d.\n", 
		       my_misc_device.minor);
		kfree(ramdisk);
		return -EBUSY;
	}
	my_dev = my_misc_device.this_device;
	dev_info(my_dev, "Succeeded in registering device %s\n", MYDEV_NAME);
	return 0;
}

static void __exit my_exit(void)
{
	dev_info(my_dev, "Unregistering Device\n");
	misc_deregister(&my_misc_device);
	kfree(ramdisk);
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_23/sample_misc_driver.c");
MODULE_LICENSE("GPL v2");
