# Phusion Passenger APT repository automation tools

This repository contains tools for automatically creating a multi-distribution APT repository for Phusion Passenger. The goal is to automatically build Debian packages for multiple distributions, immediately after a source release. These tools are meant to be run on Ubuntu 12.04.

First, install prerequisites and setup a user:

    sudo apt-get install ubuntu-dev-tools reprepro debhelper source-highlight ruby1.9.3
    sudo gem install bluecloth mizuho drake --no-rdoc --no-ri
    sudo adduser psg_apt_automation
    sudo mkdir /var/cache/passenger_apt_automation
    sudo chown psg_apt_automation: /var/cache/passenger_apt_automation

Add this to /etc/sudoers:

    Cmnd_Alias PBUILDER_CREATE = /usr/sbin/pbuilder --create *
    Cmnd_Alias PBUILDER_UPDATE = /usr/sbin/pbuilder --update *
    Cmnd_Alias PBUILDER_BUILD = /usr/sbin/pbuilder --build *
    Cmnd_Alias PBUILDER=PBUILDER_CREATE,PBUILDER_UPDATE,PBUILDER_BUILD
    Defaults!PBUILDER env_keep="ARCHITECTURE DISTRIBUTION ARCH DIST DEB_BUILD_OPTIONS HOME"
    psg_apt_automation ALL=(root)NOPASSWD:PBUILDER

Now install the pbuilder distributions. You need to patch pbuilder-dist and add Debian Wheezy support first. Edit `/usr/lib/pbuilder/pbuilder-apt-config` and replace:

    etch|lenny|squeeze|sid|oldstable|stable|testing|unstable|experimental)

with:

    etch|lenny|squeeze|sid|oldstable|stable|testing|unstable|experimental|wheezy)

Then checkout this repository as `psg_apt_automation` and run the setup script:

    sudo -u psg_apt_automation -H git clone https://github.com/phusion/passenger_apt_automation.git ~/passenger_apt_automation
    sudo mv ~/passenger_apt_automation /srv/
    cd /srv/passenger_apt_automation
    sudo -u psg_apt_automation -H ./setup-pbuilder-dist

Configure your GPG signing settings:

    sudo cp -dpR config.example config
    sudo nano config/general          # setup your key ID
    sudo nano config/passphrase       # put your password here
    sudo chown psg_apt_automation:psg_apt_automation passphrase
    sudo chmod 600 config/passphrase
    sudo -u psg_apt_automation -H gpg --keyserver keyserver.ubuntu.com --recv-keys C324F5BB38EEB5A0
    sudo -u psg_apt_automation -H gpg --armor --export C324F5BB38EEB5A0 | sudo apt-key add -

Edit `/home/psg_apt_automation/.pbuilderrc` and set:

    # Custom ccache directories per distro and architecture.
    CCACHEDIR=/var/cache/pbuilder/ccache/$DIST-$ARCH
    mkdir -p $CCACHEDIR

Import miscellaneous Phusion packages:

    sudo -u psg_apt_automation -H ./import_misc_packages

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
