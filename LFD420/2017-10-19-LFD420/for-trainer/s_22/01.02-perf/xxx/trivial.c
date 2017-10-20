/* **************** LFD331:4.1 s_05/lab6_misc.c **************** */
/*
 * The code herein is: Copyright the Linux Foundation, 2015
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
 * Using the misc API (full solution)
 *
 * Implement your fullest driver from above with the misc API.
 *
 * Once again a second solution is given which includes the same
 * header file previously used.
 *
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
	static int counter/*= 0*/;
	dev_info(my_dev, " attempting to open device: %s:\n", MYDEV_NAME);
	dev_info(my_dev, " MAJOR number = %d, MINOR number = %d\n",
		 imajor(inode), iminor(inode));
	counter++;

	dev_info(my_dev, " successfully open  device: %s:\n\n", MYDEV_NAME);
	dev_info(my_dev, "I have been opened  %d times since being loaded\n",
		 counter);
	dev_info(my_dev, "ref=%d\n", (int)module_refcount(THIS_MODULE));

	return 0;
}

static int mycdrv_release(struct inode *inode, struct file *file)
{
	dev_info(my_dev, " closing device: %s:\n\n", MYDEV_NAME);
	return 0;
}

static void my_print(void) {
        pr_info("Hello: my_print\n");
}

static ssize_t
mycdrv_read(struct file *file, char __user *buf, size_t lbuf, loff_t *ppos)
{
	int nbytes, maxbytes, bytes_to_do;
	maxbytes = ramdisk_size - *ppos;
	bytes_to_do = maxbytes > lbuf ? lbuf : maxbytes;
	if (bytes_to_do == 0)
		dev_warn(my_dev, "Reached end of the device on a read");

	nbytes = bytes_to_do - copy_to_user(buf, ramdisk + *ppos, bytes_to_do);
	*ppos += nbytes;
	dev_info(my_dev, "Leaving the   READ function, nbytes=%d, pos=%d\n",
		 nbytes, (int)*ppos);
        pr_info("Test\n");
        my_print();
	return nbytes;
}

static ssize_t
mycdrv_write(struct file *file, const char __user *buf, size_t lbuf,
	     loff_t *ppos)
{
	int nbytes, maxbytes, bytes_to_do, i;
	maxbytes = ramdisk_size - *ppos;
	bytes_to_do = maxbytes > lbuf ? lbuf : maxbytes;
	if (bytes_to_do == 0)
		dev_warn(my_dev, "Reached end of the device on a write");
	nbytes =
	    bytes_to_do - copy_from_user(ramdisk + *ppos, buf, bytes_to_do);
	*ppos += nbytes;
	dev_info(my_dev, "Leaving the   WRITE function, nbytes=%d, pos=%d\n",
		 nbytes, (int)*ppos);
	for (i=0;i<100;i++)
	    my_print();
	return nbytes;
}

static loff_t mycdrv_lseek(struct file *file, loff_t offset, int orig)
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

static const struct file_operations mycdrv_fops = {
	.owner = THIS_MODULE,
	.read = mycdrv_read,
	.write = mycdrv_write,
	.open = mycdrv_open,
	.release = mycdrv_release,
	.llseek = mycdrv_lseek
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
		pr_err("Couldn't register device misc, ");
		pr_err("%d.\n", my_misc_device.minor);
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
MODULE_DESCRIPTION("LFD331:4.1 s_05/lab6_misc.c");
MODULE_LICENSE("GPL v2");
