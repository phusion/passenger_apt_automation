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
    * `create_nginx_package`: Creates Nginx packages that contain the Phusion Passenger module.
    * `new_release`: Creates Phusion Passenger packages.

 * **Internal tools** are not meant to be used directly by the user, but are used internally. They can be found in the `internal` directory.

 * **Developer tools** are only meant to be used by people who develop passenger_apt_automation. They can be found in the `devtools` directory.

## Getting started

### Development environment

A Vagrantfile is provided so that you can develop this project in a VM. To get started, run:

    host$ vagrant up

Then SSH into the VM and run these:

    vm$ cd /vagrant
    vm$ sudo ./setup-system -g
    vm$ sudo sudo -u psg_apt_automation -H ./create-dependency-packages -a

Every time you pulled from git, you should re-run `sudo ./setup-system -g` to update the VM with the latest development settings.

### Production environment

Login as any user that can run sudo, clone this repository as `psg_apt_automation` and run the setup script:

    git clone https://github.com/phusion/passenger_apt_automation.git ~/passenger_apt_automation
    cd ~/passenger_apt_automation
    sudo ./setup-system

Then move the directory to `/srv/passenger_apt_automation`:

    sudo mv ~/passenger_apt_automation /srv/
    sudo chown -R psg_apt_automation: /srv/passenger_apt_automation

Create packages for gems that Phusion Passenger depends on:

    sudo -u psg_apt_automation -H ./create-dependency-packages -a

## Creating Phusion Passenger packages

Upon installing passenger_apt_automation for the first time, and upon the release of a new Phusion Passenger version, run the following command to create packages, as `psg_apt_automation`:

    ./new_release <GIT_URL> <PROJECT_NAME> [REF]

where:

 * `GIT_URL` is the Phusion Passenger git repository URL.
 * `PROJECT_NAME` is either 'passenger' or 'passenger-enterprise'.
 * `REF` is the commit in git for which you want to build packages. If `REF` is not specified, then it is assumed to be `origin/master`.

For example:

    ./new_release https://github.com/phusion/passenger.git passenger

The `new_release` script is atomic: users will not see an intermediate state in which only some packages have been built.

## Troubleshooting

The `./new_release` script stores build output, temporary files and logs in `/var/cache/passenger_apt_automation`. If anything goes wrong, please take a look at the various .log files in that directory. Of interest are:

    /var/cache/passenger_apt_automation/<PROJECT_NAME>.workdir/stage
    /var/cache/passenger_apt_automation/<PROJECT_NAME>.workdir/pkg/*.log
    /var/cache/passenger_apt_automation/<PROJECT_NAME>.workdir/pkg/official/*.log

## Related projects

 * https://github.com/phusion/passenger_autobuilder
 * https://github.com/phusion/passenger_rpm_automation
