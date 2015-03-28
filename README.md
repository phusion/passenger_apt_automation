# Phusion Passenger Debian packaging project

This repository contains Debian package definitions for [Phusion Passenger](https://www.phusionpassenger.com/), as well as tools for automatically building Passenger packages for multiple distributions and architectures.

The goal is project is to allow Phusion to release Debian packages for multiple distributions and architectures, immediately after a Passenger source release, in a completely automated manner.

This project utilizes Docker for isolation. Because of the usage of Docker, these tools can be run on any 64-bit Linux system, including non-Debian-based systems. Though in practice, we've only tested on Ubuntu.

**Table of Contents**

 * [Overview](#overview)
 * [Development](#development)
 * [Package building process](#package-building-process)
   - [The build script](#the-build-script)
   - [The test script](#the-test-script)
   - [The publish script](#the-publish-script)
 * [Maintenance](#maintenance)
   - [When a new distribution has been released](#when-a-new-distribution-has-been-released)
   - [Building Nginx packages only](#building-nginx-packages-only)
 * [Jenkins integration](#jenkins-integration)
   - [Debugging a packaging test failure](#debugging-a-packaging-test-failure)
 * [Related projects](#related-projects)

## Overview

This project consists of three major tools:

 * **build** -- Given a Passenger source directory, this script builds Debian packages for it.
 * **test** -- Given a directory with built Debian packages (as produced by the `build` script), this script runs tests against them.
 * **publish** -- Given a directory with built Debian packages, this script publishes them to [PackageCloud](https://packagecloud.io/).

Debian package definitions are located in the `debian_specs` directory:

 * `debian_specs/passenger` -- Package definitions for Passenger, open source edition.
 * `debian_specs/passenger-enterprise` -- Package definitions for [Passenger Enterprise](https://www.phusionpassenger.com/enterprise).
 * `debian_specs/nginx` -- Package definitions for Nginx, with Passenger compiled in.

Other noteworthy tools:

 * `jenkins` -- Scripts to be run by our Jenkins continuous integration jobs, either after every commit or during release time.

## Development

This repository is included as a git submodule in the Passenger git repository, under the directory `packaging/debian`. Instead of cloning the `passenger_apt_automation` repository directly, you should clone the Passenger git repository, and work in the `packaging/debian` directory instead. This scheme allows each Passenger version to lock down to a specific version of `passenger_apt_automation`.

A Vagrantfile is provided so that you can develop this project in a VM. To get started, run:

    host$ vagrant up

The Passenger source directory (`../..`) will be automatically mounted inside the VM under `/passenger`.

## Package building process

The package build process is as follows. First, the `build` script is used to build Debian packages from a Passenger source code directory. Next, either the `test` script is run to test the built packages, or the `publish` script is run to publish the built packages to PackageCloud.

    build   ------------>   test
                 \
                  \----->   publish

### The build script

Everything begins with the `build` script and a copy of the Passenger source code. Here's an example invocation:

    ./build -p /passenger -w work -c cache -o output pkg:all

 * `-p` tells it where the Passenger source code is.
 * `-w` tells it where it's work directory is. This is a directory in which in stores temporary files while building packages. WARNING: everything inside this directory will be deleted before the build begins, so only specify a directory that doesn't contain anything important.
 * `-c` tells it where the cache directory is. The build script caches files into this directory so that subsequent runs will be faster.
 * `-o` tells it where to store the final built Debian packages (the output directory). WARNING: everything inside this directory will be deleted when the build finishes, so only specify a directory that doesn't contain anything important.
 * The final argument, `pkg:all`, is the task that the build script must run. The build script provides a number of tasks, such as tasks for building packages for specific distributions or architecture only, or tasks for building source packages only. The `pkg:all` task builds all source and binary packages for all supported distributions and architectures.

More command line options are available. Run `./build -h` to learn more. You can also run `./build -T` to learn which tasks are available.

When the build script is finished, the output directory (`-o`) will contain one subdirectory per distribution that was built for, with each subdirectory containing packages for that distribution (in all architectures that were built for). For example:

    output/
      |
      +-- trusty/
      |      |
      |      +-- *.deb
      |      |
      |      +-- *.dsc
      |
      +-- precise/
      |      |
      |      +-- *.deb
      |      |
      |      +-- *.dsc
      |
     ...

#### Vagrant notes

When using Vagrant, the directories referred to by `-w` and `-c` must be native filesystem directories. That is, they may not be located inside /vagrant, because /vagrant is a remote filesystem. I typically use `-w ~/work -c ~/cache` when developing with Vagrant.

#### Troubleshooting

If anything goes wrong during a build, please take a look at the various log files in the work directory. Of interest are:

 * state.log -- Overview.
 * pkg.*.log -- Build logs for a specific package, distribution and architecture.

### The test script

Once packages have been built, you can test them with the test script. Here is an example invocation:

    ./test -p /passenger -x ubuntu14.04 -d output/trusty -c cache

 * `-p` tells it where the Passenger source code is.
 * `-x` tells it which environment it should use for running the tests. Two environments are supported: `ubuntu10.04` and `ubuntu14.04`.
 * `-d` tells it where to find the packages that are to be tested. This must point to a subdirectory in the output directory produced by the build script, and the packages must match the test environment as specified by `-x`. For example, if you specified `-x ubuntu14.04`, and if the build script stored packages in the directory `output`, then you should pass `-d output/trusty`.
 * `-c` tells it where the cache directory is. The test script caches files into this directory so that subsequent runs will be faster.

#### Vagrant notes

When using Vagrant, the directory referred to by `-c` must be a native filesystem directory. That is, it may not be located inside /vagrant, because /vagrant is a remote filesystem. I typically use `-c ~/cache` when developing with Vagrant.

### The publish script

Once packages have been built, you can publish them to PackageCloud. The `publish` script publishes all packages inside a build script output directory. Example invocation:

    ./publish -d output -c ~/.packagecloud_token -r passenger-testing publish:all

 * `-d` tells it where the build script output directory is.
 * `-c` refers to a file that contains the PackageCloud security token.
 * `-r` tells it the name of the PackageCloud repository. For example `passenger-5`, `passenger-testing`.
 * The last argument is the task to run. The `publish:all` publishes all packages inside the build script output directory.

## Maintenance

### When a new distribution has been released

There are three things you need to do when a new distribution has been released.

 1. Add a definition for this new distribution to internal/lib/distro_info.rb.
 2. Update the package definitions in `debian_specs/`.
 3. Build and publish packages for this distribution only. You can do that by running the build script with the `-d` option.

    For example, if the new distribution is Ubuntu 14.04 "trusty", then run:

        ./build -p /passenger -w work -c cache -o output -d trusty pkg:all
        ./publish -d output -c ~/.packagecloud_token -r passenger-testing publish:all

### Building Nginx packages only

Sometimes you want to build Nginx packages only, without building the Phusion Passenger packages. You can do this by invoking the build script with the `pkg:nginx:all` task. For example:

    ./build -p /passenger -w work -c cache -o output -d trusty pkg:nginx:all

After the build script finishes, you can publish these Nginx packages:

    ./publish -d output -c ~/.packagecloud_token -r passenger-testing publish:all

## Jenkins integration

The `jenkins` directory contains scripts which are invoked from jobs in the Phusion Jenkins CI server.

### Debugging a packaging test failure

If a packaging test job fails, here's what you should do.

 1. Checkout the Passenger source code, go to the commit for which the test failed, then cd into the packaging/debian directory.

        git clone https://github.com/phusion/passenger.git
        git reset --hard <COMMIT FOR WHICH THE TEST FAILED>
        cd packaging/debian

 2. If you're not on Linux, setup the Vagrant development environment and login to the VM:

        vagrant up
        vagrant ssh

 3. Build packages for the distribution for which the test failed.

        ./build -w ~/work -c ~/cache -o ~/output -p /passenger -d ubuntu10.04 -a amd64 -j 2 pkg:all

    Be sure to customize the value passed to `-d` based on the distribution for which the test failed.
 4. Run the tests with the debugging console enabled:

        ./test -p /passenger -x ubuntu10.04 -d ~/output/lucid -c ~/cache -D

    Be sure to customize the values passed to `-x` and `-d` based on the distribution for which the test failed.

If the test fails now, a shell will be opened inside the test container, in which you can do anything you want. Please note that this is a root shell, but the tests are run as the `app` user, so be sure to prefix test commands with `setuser app`. You can see in internal/test/test.sh which commands are invoked inside the container in order to run the tests.

Inside the test container, you will be dropped into the directory /tmp/passenger, which is a *copy* of the Passenger source directory. The original Passenger source directory is mounted under /passenger.

## Related projects

 * https://github.com/phusion/passenger_autobuilder
 * https://github.com/phusion/passenger_rpm_automation
