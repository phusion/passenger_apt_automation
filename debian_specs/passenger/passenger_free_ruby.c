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
	try_exec("/usr/bin/ruby4.10", argc, argv);
	try_exec("/usr/bin/ruby4.9", argc, argv);
	try_exec("/usr/bin/ruby4.8", argc, argv);
	try_exec("/usr/bin/ruby4.7", argc, argv);
	try_exec("/usr/bin/ruby4.6", argc, argv);
	try_exec("/usr/bin/ruby4.5", argc, argv);
	try_exec("/usr/bin/ruby4.4", argc, argv);
	try_exec("/usr/bin/ruby4.3", argc, argv);
	try_exec("/usr/bin/ruby4.2", argc, argv);
	try_exec("/usr/bin/ruby4.1", argc, argv);
	try_exec("/usr/bin/ruby4.0", argc, argv);
	try_exec("/usr/bin/ruby3.10", argc, argv);
	try_exec("/usr/bin/ruby3.9", argc, argv);
	try_exec("/usr/bin/ruby3.8", argc, argv);
	try_exec("/usr/bin/ruby3.7", argc, argv);
	try_exec("/usr/bin/ruby3.6", argc, argv);
	try_exec("/usr/bin/ruby3.5", argc, argv);
	try_exec("/usr/bin/ruby3.4", argc, argv);
	try_exec("/usr/bin/ruby3.3", argc, argv);
	try_exec("/usr/bin/ruby3.2", argc, argv);
	try_exec("/usr/bin/ruby3.1", argc, argv);
	try_exec("/usr/bin/ruby3.0", argc, argv);
	try_exec("/usr/bin/ruby2.7", argc, argv);
	try_exec("/usr/bin/ruby2.6", argc, argv);
	try_exec("/usr/bin/ruby2.5", argc, argv);
	try_exec("/usr/bin/ruby2.4", argc, argv);
	try_exec("/usr/bin/ruby2.3", argc, argv);
	try_exec("/usr/bin/ruby2.2", argc, argv);
	try_exec("/usr/bin/ruby2.1", argc, argv);
	try_exec("/usr/bin/ruby2.0", argc, argv);
	try_exec("/usr/bin/ruby1.9.1", argc, argv);
	try_exec("/usr/bin/ruby1.8", argc, argv);

	fprintf(stderr, PROGRAM_NAME ": cannot find suitable Ruby interpreter\n");
	return 1;
}
