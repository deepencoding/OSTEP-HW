#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char* argv[]) {
	int x = 100;
	int is_parent = fork();
	if (is_parent < 0) {
		fprintf(stderr, "fork failed.\n");
		exit(1);
	} else if (!is_parent) {
		x = 150;
		printf("Child: %d\n", x);
	} else {
		x = 200;
		printf("Parent: %d\n", x);
	}
	return 0;
}
