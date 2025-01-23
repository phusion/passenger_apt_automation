/*
 * This is a simple program for executing either the 'ruby' command in PATH,
 * or one of the Ruby versions installable by APT. This is necessary because
 * Debian 6 and Debian 8 (among others) do not install /usr/bin/ruby upon
 * installing one of the versioned Ruby packages (e.g. apt-get install ruby2.1).
 * Commands such as 'passenger' are supposed to be runnable under any Ruby
 * interpreter the user desires, including non-APT-installed Rubies, but we can't
 * just set the shebang line to '#!/usr/bin/env ruby'. This problem is solved by
 * setting the shebang line to '#!/usr/bin/passenger_free_ruby'.
 */

#define PROGRAM_NAME "passenger_free_ruby"
#include "passenger_ruby_utils.c"

int
main(int argc, const char *argv[]) {
	try_exec("ruby", argc, argv);
	char* exe = "/usr/bin/rubyX.XX";
	for(int m = 4; m > 0; m--) {
		for(int n = 10; n > -1; n--) {
			snprintf(exe, 18, "/usr/bin/ruby%i.%i", m, n);
			try_exec(exe, argc, argv);
		}
	}
	try_exec("/usr/bin/ruby1.9.1", argc, argv);

	fprintf(stderr, PROGRAM_NAME ": cannot find suitable Ruby interpreter\n");
	return 1;
}
