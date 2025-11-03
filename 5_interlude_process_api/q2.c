#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

int main(int argc, char* argv[]) {
	int f = open("./q1.c", O_RDONLY);
	int is_Parent = fork();
	if (is_Parent < 0) {
		fprintf(stderr, "fork failed.\n");
		exit(1);
	} else if (!is_Parent) {
		printf("Child: ");
	} else {
		printf("Parent: ");
	}
	return 0;
}
