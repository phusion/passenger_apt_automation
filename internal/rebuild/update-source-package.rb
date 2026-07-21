#!/usr/bin/env ruby
# Usage: update-source-package
# Update a Debian source package of Passenger for a new Nginx.
#
# Required environment variables:
#
#   DISTRIBUTION    Name of distribution to update the package for.
#   TARBALL         Base name of the Passenger or Nginx orig tarball.
#                   Expected to exist in /work.
#
#   SOURCENAME      Name of the top-level directory inside the orig tarball.
#   SPKG_DIR        Directory in which to place the source package.
#
#   MAINTAINER_EMAIL
#   DEBIAN_EPOCH
#   DEBIAN_VENDOR_VERSION
#   DEBIAN_HOTFIX_VERSION
#
#   PASSENGER_DEBIAN_NAME
#   PASSENGER_VERSION
#   NGINX_VERSION

require 'time'
require_relative '../lib/utils'

def sh(command)
  puts "+ #{command}"
  exit 1 unless system(command)
end

def fetch_env(name)
  value = ENV[name.to_s]
  abort "Environment variable #{name} required" if value.nil?
  Kernel.const_set(name.to_sym, value)
  value
end

fetch_env(:DISTRIBUTION)
fetch_env(:TARBALL)
fetch_env(:SOURCENAME)
fetch_env(:SPKG_DIR)
fetch_env(:MAINTAINER_EMAIL)
fetch_env(:DEBIAN_EPOCH)
fetch_env(:DEBIAN_VENDOR_VERSION)
fetch_env(:DEBIAN_HOTFIX_VERSION)
fetch_env(:PASSENGER_DEBIAN_NAME)
fetch_env(:PASSENGER_VERSION)
fetch_env(:NGINX_VERSION)

LONG_PACKAGE_VERSION="#{PASSENGER_VERSION}-#{DEBIAN_VENDOR_VERSION}~#{DISTRIBUTION}#{DEBIAN_HOTFIX_VERSION}"
ENV['DEBEMAIL']=MAINTAINER_EMAIL

puts "+ cd #{SPKG_DIR}/#{SOURCENAME}"
FileUtils.mkdir_p("#{SPKG_DIR}/#{SOURCENAME}")
Dir.chdir("#{SPKG_DIR}/#{SOURCENAME}")

puts "--> Extracting debian tarball"
sh "tar -xf /work/#{PASSENGER_DEBIAN_NAME}_#{LONG_PACKAGE_VERSION}*.debian.tar.xz"

puts "--> Updating Debian control files"
patterns = [
  "-e",
  "'s/nginx-common (= .*)/nginx-common (= #{NGINX_VERSION})/g'",
  "-e",
  "'s/#{PASSENGER_DEBIAN_NAME} (= ${binary:Version})/#{PASSENGER_DEBIAN_NAME} (= #{DEBIAN_EPOCH}:#{LONG_PACKAGE_VERSION})/g'",
].join(' ')
sh "sed #{patterns} -i'' ./debian/control"

puts "--> Updating Debian changelog file"
sh "debchange --rebuild 'Rebuilding for new nginx-common package'"

puts "--> Building Debian source package"
sh "ln /work/#{TARBALL} ../#{TARBALL}"
sh "debuild -us -uc -d -S -nc"
