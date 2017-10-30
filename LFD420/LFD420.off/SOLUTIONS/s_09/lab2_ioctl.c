/* **************** LFD420:4.13 s_09/lab2_ioctl.c **************** */
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
 * Using ioctl() for Anything. (driver)
 *
 * As we commented, one reason for resistance to adding dynamic system
 * calls it that the ioctl() system call can already be used for
 * almost any purpose.
 *
 * One minor drawback is that you have to have a device node and write
 * a user application to access the node and pass ioctl() commands to
 * it.
 *
 * For those of you who know how to do a character driver, write a
 * very very brief character driver that has only an ioctl() entry
 * point.  (You don't even need open() or release()).
 *
 * Write a companion program that shows how you can use it.
 *
@*/

#include <linux/module.h>	/* for modules */
#include <linux/fs.h>		/* file_operations */
#include <linux/init.h>		/* module_init, module_exit */
#include <linux/device.h>	/* class create, destroy to make nodes */
#include <linux/miscdevice.h>

#define MYDEV_NAME "mycdrv"

static inline long
mycdrv_unlocked_ioctl(struct file *fp, unsigned int cmd, unsigned long arg)
{
	pr_info(" I entered the ioctl with cmd=%d, do what you want!\n", cmd);
	return 0;
}

static const struct file_operations mycdrv_fops = {
	.owner = THIS_MODULE,
	.unlocked_ioctl = mycdrv_unlocked_ioctl,
};

static struct miscdevice my_misc_device = {
	.minor = MISC_DYNAMIC_MINOR,
	.name = MYDEV_NAME,
	.fops = &mycdrv_fops,
};

static int __init my_init(void)
{
	if (misc_register(&my_misc_device)) {
		pr_err("Couldn't register device misc %d.\n", 
		       my_misc_device.minor);
		return -EBUSY;
	}

	pr_info("\nSucceeded in registering character device %s\n", MYDEV_NAME);
	return 0;
}

static void __exit my_exit(void)
{
	misc_deregister(&my_misc_device);
	pr_info("\ndevice unregistered\n");
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_09/lab2_ioctl.c");
