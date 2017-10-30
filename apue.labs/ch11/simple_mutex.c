#include <stdlib.h>
#include <pthread.h>

struct foo {
	int f_count;
	pthread_mutex_t f_lock;
	int f_id;
	/*... other stuff ...*/
};

struct foo * foo_alloc(int id) {
	struct foo *fp;
	
	// allocate, free memory if can't lock
	if ((fp = malloc(sizeof(struct foo))) != NULL) {
		fp->f_count = 1;
		fp->f_id = id;
		
		if (pthread_mutex_init(&fp->f_lock, NULL) != 0) {
			free(fp);
			return(NULL);
		}
		/*... cont init ...*/
	}
	
	return(fp);
}

void foo_hold(struct foo *fp) {
	pthread_mutex_lock(&fp->f_lock);
	fp->f_count++;
	pthread_mutex_unlock(&fp->f_lock);
}

void foo_rele(struct foo *fp) {
	pthread_mutex_lock(&fp->f_lock);
	if(--fp->f_count == 0) { // the last one
		pthread_mutex_unlock(&fp->f_lock);
		pthread_mutex_destroy(&fp->f_lock);
		free(fp);
	} else {
		pthread_mutex_unlock(&fp->f_lock);
	}
}

int main(void) {
	return 0;
}
