#include "apue.h"
#include <pthread.h>

void * thr_fn1(void *arg){
	printf("thread 1 returning\n");
	return((void *)1);
}

void * thr_fn2(void *arg) {
	printf("thread 2 exiting\n");
	pthread_exit((void *)2);
}

int main(void) {
	int err;
	pthread_t tid1, tid2;
	void *tret;
	
	// create threads
	err = pthread_create(&tid1, NULL, thr_fn1, NULL);
	if (err != 0) {
		err_exit(err, "can't create thread 1");
	}

    err = pthread_create(&tid2, NULL, thr_fn2, NULL);
    if (err != 0) {
        err_exit(err, "can't create thread 2");
    }
    
    // join threads
    err = pthread_join(tid1, &tret);
    if (err != 0) {
        err_exit(err, "can't join thread 1");
    }
    printf("thread 1 exit : %ld\n", (long)tret);
    
    err = pthread_join(tid2, &tret);
    if (err != 0) {
        err_exit(err, "can't join thread 2");
    }
    printf("thread 2 exit : %ld\n", (long)tret);
    exit(0);
}
