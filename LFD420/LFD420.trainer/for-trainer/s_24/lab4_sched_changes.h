/* **************** LFD420:4.13 s_24/lab4_sched_changes.h **************** */
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
/*  NOMAKE */
struct task_struct {
	/* ... */
	void *journal_info;
	char sigpri[_NSIG];
};

#define INIT_TASK(tsk)  \
{                                                                       \
				/* ... */
journal_info: NULL, sigpri:{
0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
	    20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
	    35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
	    50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63}
}
