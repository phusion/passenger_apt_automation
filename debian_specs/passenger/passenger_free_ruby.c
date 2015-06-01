/*
 * This is a simple program for executing either the 'ruby' command in PATH,
 * or one of the Ruby versions installable by APT. This is necessary because
 * Debian 6 and Debian 8 (among others) do not install /usr/bin/ruby upon
 * installing one of the versioned Ruby packages (e.g. apt-get install ruby2.1).
 * Commands such as 'passenger' are supposed to be runnable under any Ruby
 * interpreter the user desires, including non-APT-installed Rubies, but we can't
 * just set the shebang line to '#!/usr/bin/env ruby'. This problem is solved by
 * setting the shebang line to '#!/usr/bin/passenger_default_ruby'.
 */

#define PROGRAM_NAME "passenger_default_ruby"
#include "passenger_ruby_utils.c"

int
main(int argc, const char *argv[]) {
	try_exec("ruby", argc, argv);
	try_exec("/usr/bin/ruby2.5", argc, argv);
	try_exec("/usr/bin/ruby2.4", argc, argv);
	try_exec("/usr/bin/ruby2.3", argc, argv);
	try_exec("/usr/bin/ruby2.2", argc, argv);
	try_exec("/usr/bin/ruby2.1", argc, argv);
	try_exec("/usr/bin/ruby2.0", argc, argv);
	try_exec("/usr/bin/ruby1.9.1", argc, argv);
	try_exec("/usr/bin/ruby1.8", argc, argv);

	fprintf(stderr, "passenger_default_ruby: cannot find suitable Ruby interpreter\n");
	return 1;
}
