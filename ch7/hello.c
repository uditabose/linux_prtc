# compile with `gcc -std=c99 hello.c`
# implicit return value is 0

# compile with `gcc -std=c90 hello.c`
# no implicit return value, return value is random integer

#include <stdio.h>

main() {
	printf("Hello! \n");
}
