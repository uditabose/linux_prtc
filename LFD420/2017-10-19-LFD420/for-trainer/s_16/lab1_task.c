/* **************** LFD420:4.13 s_16/lab1_task.c **************** */
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
 * Priorities and Timeslices
 *
 * Construct a program that is cpu-intensive, and takes at least 5-10
 ^ seconds to run under normal conditions.
 *    
 * Feed it a nice increment (which can range from -20 to +19) as an
 * argument (you'll have to be superuser to feed negative increments)
 * and have the program call nice() to change its priority.
 *    
 * Have the program, as its last step, open the file
 * /proc/[pid]/schedstat, and read in the three integer values, which
 * correspond to:
 *        
 *   The time spent scheduled in and executing.
 *   The time spent sleeping.
 *   The number of times the process was scheduled in.
 *    
 * where the time units are nanoseconds.
 *    
 * From these values compute the average time slice in the process was
 * granted while holding the CPU.
 *    
 * You may want to separately compute the time executing with the use
 * of gettimeofday().
 *    
 * For best results you should start off a bunch of instances with
 * different priorities simultaneously, so they have to schedule
 * against each other. It would also be a good idea to keep the CPU
 * busy with other work, such as by doing a kernel compile.
 *      
 * In the case of a variable speed CPU you may want to fix the
 * frequency before running your tests.
 *    
 * Note: for this program to work the CONFIG_SCHEDSTATS option has to
 * be set in the kernel configuration file.
@*/

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <unistd.h>
#include <sys/time.h>

#define DEATH(mess) { perror(mess); exit(errno); }

#define GET_ELAPSED_TIME(tv1,tv2) ( \
  (double)( (tv2.tv_sec - tv1.tv_sec) \
            + .000001 * (tv2.tv_usec - tv1.tv_usec)))

#define JMAX (400*100000)
double do_something(void)
{
	int j;
	double x = 0.0;
	struct timeval tv1, tv2;
	gettimeofday(&tv1, NULL);
	for (j = 0; j < JMAX; j++)
		x += 1.0 / (exp((1 + x * x) / (2 + x * x)));
	gettimeofday(&tv2, NULL);
	return GET_ELAPSED_TIME(tv1, tv2);
}

int main(int argc, char *argv[])
{
	int niceval = 0, nsched;
	/* readings are in nanosecs */
	double scale = 1e9;

	long ticks_cpu, ticks_sleep;
	pid_t pid;
	FILE *fp;
	char fname[256];
	double elapsed_time, timeslice, t_cpu, t_sleep;

	if (argc > 1)
		niceval = atoi(argv[1]);
	pid = getpid();

	/* give a chance for other tasks to queue up */
	sleep(3);

	sprintf(fname, "/proc/%d/schedstat", pid);
	/*    printf ("Fname = %s\n", fname); */

	if (!(fp = fopen(fname, "r"))) {
		printf("Failed to open stat file\n");
		exit(EXIT_FAILURE);
	}
	if (nice(niceval) == -1 && niceval != -1) {
		printf("Failed to set nice to %d\n", niceval);
		exit(EXIT_FAILURE);
	}
	elapsed_time = do_something();

	if (fscanf(fp, "%ld %ld %d", &ticks_cpu, &ticks_sleep, &nsched) <= 0)
		perror("fscanf error");
	t_cpu = (float)ticks_cpu / scale;
	t_sleep = (float)ticks_sleep / scale;
	timeslice = t_cpu / (double)nsched;
	printf("\nnice=%3d time=%10g secs pid=%6d"
	       "  t_cpu=%10g  t_sleep=%10g  nsched=%5d"
	       "  avg timeslice = %10g\n",
	       niceval, elapsed_time, pid, t_cpu, t_sleep, nsched, timeslice);
	fclose(fp);

	exit(EXIT_SUCCESS);
}
