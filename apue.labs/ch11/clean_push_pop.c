#include "apue.h"
#include <pthread.h>

void cleanup(void *arg) {
	printf("cleanup %s\n", (char *)arg);
}

void * thr_fn1(void *arg) {
	printf("thread 1 start\n");
	pthread_cleanup_push(cleanup, "1-1 handler");
	pthread_cleanup_push(cleanup, "1-2 handler");
	printf("thread 1 push complete\n");
	pthread_cleanup_pop(0);
	pthread_cleanup_pop(0);
	return((void *)1);
}

void * thr_fn2(void *arg) {
    printf("thread 2 start\n");
    pthread_cleanup_push(cleanup, "2-1 handler");
    pthread_cleanup_push(cleanup, "2-2 handler");
    printf("thread 2 push complete\n");
    pthread_cleanup_pop(1);
    pthread_cleanup_pop(1);
    pthread_exit((void *)2);
}

int main(void) {
	int err;
	pthread_t tid1, tid2;
	void *tret;
	
	err = pthread_create(&tid1, NULL, thr_fn1, (void *)1);
	if (err != 0) {
	    err_exit(err, "can't create thread 1");
	}
	
	err = pthread_create(&tid2, NULL, thr_fn2, (void *)2);
	if (err != 0) {
	    err_exit(err, "can't create thread 2");
	}
	err = pthread_join(tid1, &tret);
	if (err != 0) {
	    err_exit(err, "can't join thread 1");
	}
	printf("thread 1 exit %ld\n", (long)tret);
	err = pthread_join(tid2, &tret);
	if (err != 0) {
	    err_exit(err, "can't join thread 2");
	}
	printf("thread 2 exit %ld\n", (long)tret);                                                          
	exit(0);
}
