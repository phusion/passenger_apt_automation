# Phusion Passenger APT repository automation tools

This repository contains tools for automatically creating a multi-distribution APT repository for Phusion Passenger. It is meant to be run on Ubuntu 12.04.

To begin:

    sudo apt-get install ubuntu-dev-tools reprepro
    ./setup-pbuilder-dist
    echo your-gpg-key-passphrase > passphrase
    chmod 600 passphrase

Then, every time a new Phusion Passenger version is released, run the following command to update the APT repository in `apt/`:

    ./new_release <GIT_URL> [REF]

where `GIT_URL` is the Phusion Passenger git repository URL, and `REF` is the commit in git for which you want to build packages. If `REF` is not specified, then it is assumed to be `origin/master`.

For example:

    ./new_release https://github.com/phusion/passenger.git

The `new_release` script is near-atomic: it is very unlikely that users will see an intermediate state in which only some packages have been built.
