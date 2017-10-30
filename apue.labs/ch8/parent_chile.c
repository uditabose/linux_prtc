#include <stdio.h>
#include <sys/types.h>

#define MAX_COUNT 200

void child_proc(void);
void parent_proc(void);

void main(void) {
	pid_t pid;
	
	pid = fork();
	if (pid == 0) {
		child_proc();
	} else {
		parent_proc();
	}

	printf("main done\n");

}

void child_proc(void) {
	int i;

	for(i = 0; i < MAX_COUNT; i++) {
		printf("Child : %d\n", i);
	}

	printf("****** Child Done *******\n");
}

void parent_proc(void) {
        int i;

        for(i = 0; i < MAX_COUNT; i++) {
                printf("Parent : %d\n", i);
        }

        printf("****** Parent Done *******\n");
}

