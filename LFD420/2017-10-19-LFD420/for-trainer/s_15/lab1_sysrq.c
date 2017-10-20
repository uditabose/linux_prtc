/* **************** LFD420:4.13 s_15/lab1_sysrq.c **************** */
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
 * Extending SysRq keys.
 *
 * It is possible to extend they SysRq key mechanism to enable custom
 * defined keys and actions.  All the information needed can be found
 * in linux/sysrq.h.
 *
 * The relevant structures and functions are:
 *
 *  #include <linux/sysrq.h>
 *
 *  struct sysrq_key_op {
 *      void (*handler)(int, struct tty_struct *);
 *      char *help_msg;
 *      char *action_msg;
 *  };
 *  int register_sysrq_key(int, struct sysrq_key_op *);
 *  int unregister_sysrq_key(int, struct sysrq_key_op *);
 *
 * where the key value (say 'x') is supplied as the first argument to
 * the handler function.
 *
 * Note: in kernels previous to version 2.6.36 kernel the handler
 * function had a second argument as in
 *
 *       void (*handler)(int, struct tty_struct *);
 *
 * The purpose and usage of the other functions and variables should
 * be clear from the definition.
 *
 * Write a simple module that registers a new key, that can do as
 * little as print a message.  See what occurs when you get the help
 * message.
 *
 * Make sure you that you have turned this option on in your kernel at
 * compilation and in /proc/sys/kernel/sysrq.  If you have keyboard
 * problems you may need to do something like
 *
 *     echo x > /proc/sysrq-trigger
 *
@*/

#include <linux/module.h>
#include <linux/init.h>
#include <linux/sysrq.h>
#include <linux/version.h>

#define MY_SYSRQ_KEY 'x'

#if LINUX_VERSION_CODE < KERNEL_VERSION(2, 6, 36)
static void my_sysrq_handler(int key, struct tty_struct *ttystruct)
#else
static void my_sysrq_handler(int key)
#endif
{
	pr_info("Hello from function %s\n", __func__);
	pr_info("Key pressed was '%c'\n", key);
}

static struct sysrq_key_op my_sysrq_key_op = {
	.handler = my_sysrq_handler,
	.help_msg = "e(x)ample",
	.action_msg = "e(x)ample action message",
};

static int __init my_init(void)
{
	int rc = register_sysrq_key(MY_SYSRQ_KEY, &my_sysrq_key_op);
	if (rc == 0) 
		pr_info("sysrq key registered\n");
	else 
		pr_err("sysrq key failed to register\n");
	return rc;
}

static void __exit my_exit(void)
{
	int rc = unregister_sysrq_key(MY_SYSRQ_KEY, &my_sysrq_key_op);
	if (rc == 0) 
		pr_info("sysrq key unregistered\n");
	else 
		pr_err("sysrq key failed to unregister\n");
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Terry Griffin");
MODULE_AUTHOR("Jerry Cooperstein");
MODULE_DESCRIPTION("LFD420:4.13 s_15/lab1_sysrq.c");
MODULE_LICENSE("GPL v2");
