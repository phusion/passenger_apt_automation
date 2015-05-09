/*
 * This file is included in passenger_free_ruby.c and passenger_system_ruby.c.
 * It requires the PROGRAM_NAME macro to be defined.
 */

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

static char **
construct_forwarding_argv(const char *ruby, int argc, const char *argv[]) {
	char **result = malloc(sizeof(char *) * (argc + 1));
	int i;

	if (result == NULL) {
		fprintf(stderr, PROGRAM_NAME ": cannot allocate memory\n");
		_exit(1);
	}

	if (strcmp(argv[0], "/usr/bin/" PROGRAM_NAME) == 0
	 || strcmp(argv[0], PROGRAM_NAME) == 0)
	{
		result[0] = ruby;
	} else {
		// Preserve custom argv0
		result[0] = argv[0];
	}

	for (i = 1; i < argc; i++) {
		result[i] = argv[i];
	}

	result[argc] = NULL;
	return result;
}

static void
try_exec(const char *ruby, int argc, const char **argv) {
	char **forwarding_argv = construct_forwarding_argv(ruby, argc, argv);
	int e;

	execvp(ruby, (char * const *) forwarding_argv);
	if (errno == ENOENT) {
		free(forwarding_argv);
	} else {
		e = errno;
		fprintf(PROGRAM_NAME ": cannot execute '%s': %s\n",
			ruby, strerror(e));
		_exit(1);
	}
}
