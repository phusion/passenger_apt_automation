#!/bin/bash

cd /mnt/pwd || exit
apt update
apt install -y ruby-nokogiri distro-info-data
gem install ruby-xz
./internal/scripts/regen_distro_info_script.sh
