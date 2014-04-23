# Phusion Passenger APT repository automation tools

This repository contains tools for automatically creating a multi-distribution APT repository for Phusion Passenger. The goal is to automatically build Debian packages for multiple distributions, immediately after a source release. These tools are meant to be run on Ubuntu 12.04.

## Setting up a development environment

A Vagrantfile is provided so that you can develop this project in a VM. To get started, run:

    host$ vagrant up

Then SSH into the VM and run:

    vm$ cd /vagrant
    vm$ sudo ./setup-system -g

Every time you pulled from git, you should re-run `./setup-system` to update the VM with the latest development settings.

## Setting up in production

Login as any user that can run sudo, clone this repository as `psg_apt_automation` and run the setup script:

    git clone https://github.com/phusion/passenger_apt_automation.git ~/passenger_apt_automation
    cd ~/passenger_apt_automation
    sudo ./setup-system

Then move the directory to `/srv/passenger_apt_automation`:

    sudo mv ~/passenger_apt_automation /srv/
    sudo chown -R psg_apt_automation: /srv/passenger_apt_automation

Create packages for gems that Phusion Passenger depends on:

    sudo -u psg_apt_automation -H ./create-dependency-packages -a

Then, every time a new Phusion Passenger version is released, run the following command to update the APT repository in `apt/`, as `psg_apt_automation`:

    ./new_release <GIT_URL> <REPO_DIR> <APT_DIR> [REF]

where:

 * `GIT_URL` is the Phusion Passenger git repository URL.
 * `REPO_DIR` is the directory that the git repository should be cloned to.
 * `APT_DIR` is the APT repository directory.
 * `REF` is the commit in git for which you want to build packages. If `REF` is not specified, then it is assumed to be `origin/master`.

For example:

    ./new_release https://github.com/phusion/passenger.git passenger.repo passenger.apt

The `new_release` script is near-atomic: it is very unlikely that users will see an intermediate state in which only some packages have been built.

## Troubleshooting

The `./new_release` script stores build output, temporary files and logs in `/var/cache/passenger_apt_automation`. If anything goes wrong, please take a look at the various .log files in that directory. Of interest are:

    /var/cache/passenger_apt_automation/<NAME>/stage
    /var/cache/passenger_apt_automation/<NAME>/pkg/*.log
    /var/cache/passenger_apt_automation/<NAME>/pkg/official/*.log

## Related projects

 * https://github.com/phusion/passenger_autobuilder
 * https://github.com/phusion/passenger_rpm_automation
