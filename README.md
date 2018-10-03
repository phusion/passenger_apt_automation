# Phusion Passenger Debian packaging project

This repository contains Debian package definitions for [Phusion Passenger](https://www.phusionpassenger.com/), as well as tools for automatically building Passenger packages for multiple distributions and architectures.

The goal of this project is twofold:

 1. To allow Phusion to release Debian packages for multiple distributions and architectures, immediately after a Passenger source release, in a completely automated manner.
 2. To allow users to build their own Debian packages for Passenger, without having to wait for Phusion to do so.

> Are you a user who wants to build your own packages for a Passenger version that hasn't been released yet? Read [Tutorial: building your own packages](#tutorial-building-your-own-packages).

**Table of Contents**

 * [Conceptual Introduction to Debian Packaging](#conceptual-introduction-to-debian-packaging)
 * [Overview](#overview)
 * [Development](#development)
 * [Package building process](#package-building-process)
   - [The build script](#the-build-script)
   - [The test script](#the-test-script)
   - [The publish script](#the-publish-script)
 * [Maintenance](#maintenance)
   - [Updating build and/or testboxes](#updating-build-and-or-testboxes)
   - [Adding support for a new distribution](#adding-support-for-a-new-distribution)
   - [Removing support for a distribution](#removing-support-for-a-distribution)
   - [Updating the build box's APT cache](#updating-the-build-boxs-apt-cache)
   - [Building Nginx packages only](#building-nginx-packages-only)
   - [Updating SSL certificates](#updating-ssl-certificates)
 * [Jenkins integration](#jenkins-integration)
   - [Debugging a packaging test failure](#debugging-a-packaging-test-failure)
 * [Tutorial: building your own packages](#tutorial-building-your-own-packages)
 * [Related projects](#related-projects)

## Conceptual Introduction to Debian Packaging

Not familiar with Debian packaging? See [ConceptualIntroductiontoDebianPackaging.md](https://github.com/phusion/passenger_apt_automation/blob/master/ConceptualIntroductionToDebianPackaging.md).

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

 * `shell` -- Open a shell in a new buildbox container for debugging purposes.
 * `jenkins/` -- Scripts to be run by our Jenkins continuous integration jobs, either after every commit or during release time.

This project utilizes Docker for isolation. Because of the usage of Docker, these tools can be run on any 64-bit Linux system, including non-Debian-based systems. Though in practice, we've only tested on Ubuntu.

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

 * `-p` tells it where the Passenger source code is. N.B. this setting will be ignored (unless you use -R) if the cache already contains a .tar.gz file for the Passenger version in the specified source dir.
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

    ./test -p /passenger -x trusty -d output/trusty -c cache

 * `-p` tells it where the Passenger source code is in order to find the unit tests (those aren't in the debian package). The code / resources / executables under test come from the debian package built by the build script.
 * `-x` tells it which distribution it should use for running the tests. To learn which distributions are supported, run `./test -h`.
 * `-d` tells it where to find the packages that are to be tested. This must point to a subdirectory in the output directory produced by the build script, and the packages must match the test environment as specified by `-x`. For example, if you specified `-x trusty`, and if the build script stored packages in the directory `output`, then you should pass `-d output/trusty`.
 * `-c` tells it where the cache directory is. The test script caches files into this directory so that subsequent runs will be faster.

#### Vagrant notes

When using Vagrant, the directory referred to by `-c` must be a native filesystem directory. That is, it may not be located inside /vagrant, because /vagrant is a remote filesystem. I typically use `-c ~/cache` when developing with Vagrant.

The Vagrant VM uses 2 GB of RAM, so make sure your host has at least 4 GB.

### The publish script

Once packages have been built, you can publish them to PackageCloud. The `publish` script publishes all packages inside a build script output directory. Example invocation:

    ./publish -d output -c ~/.packagecloud_token -r passenger-testing publish:all

 * `-d` tells it where the build script output directory is.
 * `-c` refers to a file that contains the PackageCloud security token.
 * `-r` tells it the name of the PackageCloud repository. For example `passenger-5`, `passenger-testing`.
 * The last argument is the task to run. The `publish:all` publishes all packages inside the build script output directory.

## Maintenance

### Updating build and/or testboxes

Prior to changing the buildbox or testbox, you should update their version number as follows:

 1. Update the relevant part(s) in `internal/lib/docker_image_info.sh`.
 2. Run `./internal/scripts/regen_distro_info_script.sh`.

### Adding support for a new distribution

In these instructions, we assume that the new distribution is Ubuntu 16.04 "Xenial". Update the actual parameters accordingly.

 1. Bump the the buildbox version number's tiny component. Open `internal/lib/docker_image_info.sh` and change the number under `buildbox_version`.

 2. Add a definition for this new distribution to `internal/lib/distro_info.rb`.

     1. Add to either the `UBUNTU_DISTRIBUTIONS` or the `DEBIAN_DISTRIBUTIONS` constant.
     2. Add to the `DEFAULT_DISTROS` constant.

 3. Run `internal/scripts/regen_distro_info_script.sh`.

 4. Rebuild the build box so that it has the latest distribution information:

        make -C docker-images buildbox

 5. Update the package definitions in `debian_specs/`.
 
     1. Check if new ruby is available in distro update versions or comments in `debian_specs/passenger/helpers.rb`
     2. Add `<% if %>` statements accordingly to output the appropriate content for the target distribution. (e.g. in `debian_specs/passenger/control.erb`)
 
 6. Build publish packages for this distribution only. You can do that by running the build script with the `-d` option.

    For example:

        ./build -p /passenger -w work -c cache -o output -d xenial pkg:all

 7. Create a test box for this new distribution.

     1. Create `docker-images/testbox-ubuntu-16.04/` (copy of testbox of previous release)
     2. Set the correct From in `docker-images/testbox-ubuntu-16.04/Dockerfile`
     3. Edit `docker-images/Makefile` and add entries for this new testbox.
     
        make -C docker-images testbox-ubuntu-16.04

    When done, test Passenger under the new testbox:

        ./test -p /passenger -x xenial -d output/xenial -c cache

 8. Commit and push all changes, then publish the new packages and the updated Docker images by running:

        git add docker-images
        git commit -a -m "Add support for Ubuntu 16.04 Xenial"
        git push
        cd docker-images
        make upload

 9. Inside the [passenger](https://github.com/phusion/passenger) repository:

     1. Update the `packaging/debian` submodule (which refers to the `passenger_apt_automation` repository) to the latest commit. Assuming you want the submodule to update to the latest `master` branch commit:

            cd packaging/debian
            git checkout master
            git pull
            cd ../..

     2. Update `dev/ci/tests/debian/Jenkinsfile` and add this new distro under the `parameters` section.

     3. Commit and push the result:

            git commit -a -m "Add packaging support for Ubuntu 16.04 Xenial"
            git push

### Removing support for a distribution

In these instructions, we assume that the distribution to be removed is Ubuntu 16.04 "Xenial". Update the actual parameters accordingly.

 1. Remove the distribution's definition from `internal/lib/distro_info.rb`, `DEFAULT_DISTROS` constant.
 2. Run `./internal/scripts/regen_distro_info_script.sh`.
 3. Update the package definitions in `debian_specs/`. Remove `<% if %>` statements that target only this distribution.
 4. Remove the test box for this distribution.

     1. Remove `docker-images/testbox-ubuntu-16.04/`
     2. Edit `docker-images/Makefile` and remove entries for this distribution's testbox.

 5. Commit and push all changes:

        git add -u docker-images
        git commit -a -m "Remove support for Ubuntu 16.04 Xenial"
        git push

 6. Inside the [passenger](https://github.com/phusion/passenger) repository:

     1. Update the `packaging/debian` submodule (which refers to the `passenger_apt_automation` repository) to the latest commit, then commit the result. Assuming you want the submodule to update to the latest `master` branch commit:

            cd packaging/debian
            git checkout master
            git pull
            cd ../..

     2. Update `dev/ci/tests/debian/Jenkinsfile` and remove the deprecated distro under the `params` section.

     3. Commit and push the result:

            git commit -a -m "Remove packaging support for Ubuntu 16.04 Xenial"
            git push

### Updating the build box's APT cache

The package building process works by running `pbuilder-dist` inside a Docker container. `pbuilder-dist`, in turn, is a Debian tool for managing chroots for building packages for specific distributions. Once in a while, the APT cache inside these chroots will get out of date, resulting in HTTP 404 errors while building packages, like this:

    Get: 1 http://security.debian.org/ wheezy/updates/main libtasn1-3 amd64 2.13-2+deb7u2 [67.8 kB]
    Err http://security.debian.org/ wheezy/updates/main libxml2 amd64 2.8.0+dfsg1-7+wheezy4
      404  Not Found [IP: 212.211.132.250 80]

When this happens, it is time to update the chroot's APT cache. There are two ways to do this.

The first way is by deleting the pbuilder chroot tarball in the cache directory. It will be recreated next time you run a build process. For example:

    rm ~/cache/base-wheezy-amd64.tgz

The second way is by updating it in-place. For example:

 1. Run: `./shell -c ~/cache`. This will drop you into the buildbox shell.
 2. Run: `initpbuilder wheezy amd64`.
 3. Run: `pbuilder-dist wheezy amd64 update`.
 4. Run `exit` to exit the build box shell.

### Building Nginx packages only

Sometimes you want to build Nginx packages only, without building the Phusion Passenger packages. You can do this by invoking the build script with the `pkg:nginx:all` task. For example:

    ./build -p /passenger -w work -c cache -o output -d xenial pkg:nginx:all

After the build script finishes, you can publish these Nginx packages:

    ./publish -d output -c ~/.packagecloud_token -r passenger-testing publish:all

### Updating SSL certificates

The Jenkins publishing script posts to some HTTPS servers. For security reasons, we pin the certificates, but these certificates expire after a while. You can update them by running:

    ./internal/scripts/pin_certificates

## Jenkins integration

The `jenkins` directory contains scripts which are invoked from jobs in the Phusion Jenkins CI server.

## Troubleshooting

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

        ./build -w ~/work -c ~/cache -o ~/output -p /passenger -d xenial -a amd64 -j 2 -R pkg:all

    Be sure to customize the value passed to `-d` based on the distribution for which the test failed.
 4. Run the tests with the debugging console enabled:

        ./test -p /passenger -x xenial -d ~/output/xenial -c ~/cache -D

    Be sure to customize the values passed to `-x` and `-d` based on the distribution for which the test failed.

If the test fails now, a shell will be opened inside the test container, in which you can do anything you want. Please note that this is a root shell, but the tests are run as the `app` user, so be sure to prefix test commands with `setuser app`. You can see in internal/test/test.sh which commands are invoked inside the container in order to run the tests.

Inside the test container, you will be dropped into the directory /tmp/passenger, which is a *copy* of the Passenger source directory. The original Passenger source directory is mounted under /passenger.

### Manually interacting with the packages

Packages are built to `output/<distro>`. You can play around manually with examining and installing these in a docker image:

    docker run -v dir/on/host/output/<distro>:/dir/in/docker/img -it ubuntu:16.04
    apt-get update && apt-get upgrade
    dpkg -I passenger_5.1.x-1~distro1_amd64.deb  # view info
    dpkg -i passenger_5.1.x-1~distro1_amd64.deb  # install passenger (probably need to install a module too)
    apt --fix-broken install  # to install dependencies
    
    

## Tutorial: building your own packages

Are you a user who wants to build Debian packages for a Passenger version that hasn't been released yet? Maybe because you want to gain access to a bug fix that isn't part of a release yet? Then this tutorial is for you.

You can follow this tutorial on any OS you want. You do not necessarily have to follow this tutorial on the OS you wish to build packages for. For example, it is possible to build packages for Ubuntu 14.04 while following this tutorial on OS X.

### Prerequisites

If you are following this tutorial on a Linux system, then you must [install Docker](https://www.docker.com/).

If you are following this tutorial on any other OS, then you must install [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/).

NOTE: If you are on macOS, installing Docker for Mac is NOT enough. You MUST use Vagrant+VirtualBox.

### Step 1: Checkout out the desired source code

First, clone the Passenger git repository and its submodules:

    git clone git://github.com/phusion/passenger.git
    cd passenger
    git submodule update --init --recursive

Checkout the branch you want. At the time of writing (2017 July 6), you will most likely be interested in the `stable-5.1` branch because that's the branch that is slated to become the next release version.

    git checkout stable-5.1

Then go to the directory `packaging/debian`:

    cd packaging/debian

### Step 2 (non-Linux only): spin up Vagrant VM

If you are on a Linux system, then you can skip to step 3.

If you are not on a Linux system, then you must spin up the Vagrant VM. Type:

    vagrant up

Wait until the VM has booted, then run:

    vagrant ssh

You will now be dropped in an SSH session inside the VM. Any futher steps must be followed inside this SSH session.

### Step 3: build packages

Use the `./build` script to build packages. You must tell the build script which distribution and architecture it should build for. Run:

    ./build -p <PATH TO PASSENGER> -w ~/work -c ~/cache -o output -a <ARCHITECTURE> -d <DISTRIBUTION> pkg:all

Replace `<PATH TO PASSENGER>` with one of these:

 * If you are on a Linux system, it should be `../..`.
 * If you are on a non-Linux system (and using Vagrant), it should be `/passenger`.

Replace `<ARCHITECTURE>` with either `i386` or `amd64`. Replace `<DISTRIBUTION>` with the codename of the distribution you want to build for. For example:

 * `precise` -- Ubuntu 12.04
 * `trusty` -- Ubuntu 14.04
 * `xenial` -- Ubuntu 16.04
 * `wheezy` -- Debian 7
 * `jessie` -- Debian 8
 * `stretch` -- Debian 9

You can find the codename of your distribution version on Wikipedia: [Ubuntu codenames](https://en.wikipedia.org/wiki/Ubuntu#Releases), [Debian codenames](https://en.wikipedia.org/wiki/Debian#Release_timeline).

Here is an example invocation for building packages for Ubuntu 14.04, x86_64:

```bash
# If you are on a Linux system:
./build -p ../.. -w ~/work -c ~/cache -o output -a amd64 -d trusty pkg:all

# If you are on a non-Linux system (and using Vagrant):
./build -p /passenger -w ~/work -c ~/cache -o output -a amd64 -d trusty pkg:all
```

### Step 4: get packages, clean up

When the build is finished, you can find the packages in the `output` directory.

If you are on a non-Linux OS (and thus using Vagrant), you should know that this `output` directory is accessible from your host OS too. It is a subdirectory inside `<PASSENGER REPO>/packaging/debian`.

If you are not on a Linux system, then you should spin down the Vagrant VM. Run this on your host OS, inside the `packaging/debian` subdirectory:

    vagrant halt

## Related projects

 * https://github.com/phusion/passenger_autobuilder
 * https://github.com/phusion/passenger_rpm_automation
