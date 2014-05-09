# Phusion Passenger APT repository automation tools

This repository contains tools for automatically creating a multi-distribution APT repository for Phusion Passenger. The goal is to automatically build Debian packages for multiple distributions, immediately after a source release. These tools are meant to be run on Ubuntu 12.04 or Ubuntu 14.04, 64-bit.

These tools use pbuilder-dist to generate packages for multiple distributions and multiple architectures. Pbuilder-dist is a tool which sets up chroot environments for multiple distributions.

## Overview of tools

This repository provides three major categories of tools:

 * **Setup tools** prepare and set up the system.

    * `setup-system`: Installs dependencies, users, configuration files, etc. It runs `setup-pbuilder-dist` when it is run for the first time.
    * `setup-builder-dist`: Creates or updates the pbuilder-dist environments.

 * **Release tools** create packages.

    * `create-dependency-packages`: Creates packages for gems that Phusion Passenger depends on.
    * `create-nginx-packages`: Creates Nginx packages that contain the Phusion Passenger module.
    * `new_release`: Creates Nginx and Phusion Passenger packages. Uses `create-nginx-package` internally.

 * **Internal tools** are not meant to be used directly by the user, but are used internally. They can be found in the `internal` directory.

 * **Developer tools** are only meant to be used by people who develop passenger_apt_automation. They can be found in the `devtools` directory.

## Getting started

### Development environment

A Vagrantfile is provided so that you can develop this project in a VM. To get started, run:

    host$ vagrant up

Then SSH into the VM and run these:

    vm$ cd /vagrant
    vm$ sudo ./setup-system -g

Every time you pulled from git, you should re-run `sudo ./setup-system -g` to update the VM with the latest development settings.

If the Phusion Passenger source code (Git repository clone) is located on the host in `../passenger`, then that directory will be mounted inside the VM under `/passenger`.

### Production environment

Login as any user that can run sudo, clone this repository as `psg_apt_automation` and run the setup script:

    git clone https://github.com/phusion/passenger_apt_automation.git ~/passenger_apt_automation
    cd ~/passenger_apt_automation
    sudo ./setup-system

Then move the directory to `/srv/passenger_apt_automation`:

    sudo mv ~/passenger_apt_automation /srv/
    sudo chown -R psg_apt_automation: /srv/passenger_apt_automation

## Building packages

### Dependency packages

There are a number of gems (daemon_controller and crash-watch) that Phusion Passenger depend on, and for which packages should be built. Run the following command to build them and to import them into the APT repositories:

    sudo -u psg_apt_automation -H ./create-dependency-packages -a <PROJECT_NAMES...>

where `PROJECT_NAMES` is one of: 'passenger', 'passenger-enterprise', 'passenger-testing', 'passenger-enterprise-testing'.

#### When a new gem version has been released

When a new version of one of those gems has been released, you should build a package for the latest version of that gem only, by passing either `-d` (for daemon_controller) or `-c` (for crash-watch) instead of `-a`. For example:

    # Build package for latest version of daemon_controller.
    sudo -u psg_apt_automation -H ./create-dependency-packages -d <PROJECT_NAMES...>

    # Build package for latest version of crash-watch.
    sudo -u psg_apt_automation -H ./create-dependency-packages -c <PROJECT_NAMES...>

#### When a new distribution has been released

When a new distribution has been released, you should build packages for all gems, but for that distribution only. Edit `config/general` and set `DEBIAN_DISTROS` to that distribution only:

    $ nano config/general
    ...
    DEBIAN_DISTROS="trusty"

Then build packages for all gems:

    sudo -u psg_apt_automation -H ./create-dependency-packages -a <PROJECT_NAMES...>

Afterwards, edit `config/general` again and revert `DEBIAN_DISTROS` back to what it was:

    $ nano config/general
    ...
    DEBIAN_DISTROS="old value"

### Phusion Passenger packages

Upon installing passenger_apt_automation for the first time, and upon the release of a new Phusion Passenger version, run the following command to build Phusion Passenger packages as well as Nginx packages:

    sudo -u psg_apt_automation -H ./new_release <GIT_URL> <PROJECT_NAME> [REF]

where:

 * `GIT_URL` is the Phusion Passenger git repository URL.
 * `PROJECT_NAME` is one of: 'passenger', 'passenger-enterprise', 'passenger-testing', 'passenger-enterprise-testing'.
 * `REF` is the commit in git for which you want to build packages. If `REF` is not specified, then it is assumed to be `origin/master`.

For example:

    sudo -u psg_apt_automation -H ./new_release https://github.com/phusion/passenger.git passenger
    sudo -u psg_apt_automation -H ./new_release URL-TO-PASSENGER-ENTERPRISE passenger-enterprise

The `new_release` script is atomic: users will not see an intermediate state in which only some packages have been built.

In the Vagrant VM, if `/passenger` is mounted you can also run the following to test things against the Phusion Passenger Git repository that is located on the host:

    sudo -u psg_apt_automation -H ./new_release file:///passenger/.git passenger

#### When a new distribution has been released

When a new distribution has been released, you should build packages against the latest release of Phusion Passenger, and for that distribution only. Edit `config/general` and set `DEBIAN_DISTROS` to that distribution only:

    $ nano config/general
    ...
    DEBIAN_DISTROS="trusty"

Then build packages against a specific Git tag:

    sudo -u psg_apt_automation -H ./new_release https://github.com/phusion/passenger.git passenger release-x.x.x
    sudo -u psg_apt_automation -H ./new_release URL-TO-PASSENGER-ENTERPRISE passenger-enterprise enterprise-x.x.x

Afterwards, edit `config/general` again and revert `DEBIAN_DISTROS` back to what it was:

    $ nano config/general
    ...
    DEBIAN_DISTROS="old value"

#### Building Nginx packages only

During development you will sometimes want to build Nginx packages only. To do that, ensure that the `/passenger` directory is mounted, and set the following environment variables:

    export PKG_DIR=/home/psg_apt_automation/pkg
    export PASSENGER_DIR=/passenger

Then run the following to generate Nginx source packages in `$PKG_DIR`:

    sudo -E sudo -u psg_apt_automation -H -E ./create-nginx-packages source_packages

Run the following to generate Nginx binary packages in `$PKG_DIR`:

    sudo -E sudo -u psg_apt_automation -H -E ./create-nginx-packages binary_packages

## Troubleshooting

The `./new_release` script stores build output, temporary files and logs in `/var/cache/passenger_apt_automation`. If anything goes wrong, please take a look at the various .log files in that directory. Of interest are:

    /var/cache/passenger_apt_automation/<PROJECT_NAME>.workdir/stage
    /var/cache/passenger_apt_automation/<PROJECT_NAME>.workdir/full.log
    /var/cache/passenger_apt_automation/<PROJECT_NAME>.workdir/pkg/*.log
    /var/cache/passenger_apt_automation/<PROJECT_NAME>.workdir/pkg/official/*.log

## Related projects

 * https://github.com/phusion/passenger_autobuilder
 * https://github.com/phusion/passenger_rpm_automation
