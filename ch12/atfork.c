#include "apue.h"
#include <pthread.h>

pthread_mutex_t lock1 = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t lock2 = PTHREAD_MUTEX_INITIALIZER;

void prepare(void) {
	int err;
	
	printf("preparing lock ...\n");
	if ((err = pthread_mutex_lock(&lock1)) != 0) {
		err_cont(err, "lock1 not prepped");
	}
	if ((err = pthread_mutex_lock(&lock2)) != 0) {
		err_cont(err, "lock2 not prepped");
	}
}

void parent(void) {
	int err;
	
	printf("parent unlocking locks ...\n");
	if ((err = pthread_mutex_unlock(&lock1)) != 0) {
		err_cont(err, "parent lock1 not unlocked");
	}
	if ((err = pthread_mutex_lock(&lock2)) != 0) {
	    err_cont(err, "parent lock2 not unlocked");
	}
}

void child(void) { 
    int err;
        
    printf("child unlocking locks ...\n");
    if ((err = pthread_mutex_unlock(&lock1)) != 0) {
        err_cont(err, "child lock1 not unlocked");
    }
    if ((err = pthread_mutex_lock(&lock2)) != 0) {
        err_cont(err, "child lock2 not unlocked");
    }
}

void * thr_fn(void *arg) {
	printf("thread started...\n");
	pause();
	return(0);
}

int main(void) {
	int err;
	pid_t pid;
	pthread_t tid;
	
	if ((err = pthread_atfork(prepare, parent, child)) != 0) {
		err_exit(err, "can't install fork handlers");
	} 
	
	if ((err = pthread_create(&tid, NULL, thr_fn, 0)) != 0) {
		err_exit(err, "can't create thread");
	}
	
	sleep(2);
	printf("parent about to fork...\n");
	
	if ((pid == fork()) < 0) {
		err_quit("fork failed");
	} else if (pid == 0) {
		printf("child returned from fork\n");
	} else {
		printf("parent returned from fork\n");
	}
	exit(0);
}
