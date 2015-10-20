#!/usr/bin/env ruby
# Usage: build-source-package
# Build a Debian source package of Passenger or Nginx.
#
# Required environment variables:
#
#   SPECDIR         Path to a Debian spec directory.
#   DISTRIBUTION    Name of distribution to build for.
#   TARBALL         Base name of the Passenger or Nginx orig tarball.
#                   Expected to exist in /work.
#   SOURCENAME      Name of the top-level directory inside the orig tarball.
#   SPKG_DIR        Directory in which to place the source package.
#
#   MAINTAINER_NAME
#   MAINTAINER_EMAIL
#   PACKAGE_VERSION
#   DEBIAN_NAME
#   DEBIAN_EPOCH
#   DEBIAN_VENDOR_VERSION
#   DEBIAN_HOTFIX_VERSION
#
#   PASSENGER_TARBALL
#   PASSENGER_DEBIAN_NAME
#   PASSENGER_VERSION
#   NEXT_PASSENGER_VERSION

require 'time'
require_relative '../lib/utils'

def sh(command)
  puts "+ #{command}"
  if !system(command)
    exit 1
  end
end

def fetch_env(name)
  value = ENV[name.to_s]
  if !value
    abort "Environment variable #{name} required"
  end
  Kernel.const_set(name.to_sym, value)
  value
end

fetch_env(:SPECDIR)
fetch_env(:DISTRIBUTION)
fetch_env(:TARBALL)
fetch_env(:SOURCENAME)
fetch_env(:SPKG_DIR)

fetch_env(:MAINTAINER_NAME)
fetch_env(:MAINTAINER_EMAIL)
fetch_env(:PACKAGE_VERSION)
fetch_env(:DEBIAN_NAME)
fetch_env(:DEBIAN_EPOCH)
fetch_env(:DEBIAN_VENDOR_VERSION)
fetch_env(:DEBIAN_HOTFIX_VERSION)

fetch_env(:PASSENGER_TARBALL)
fetch_env(:PASSENGER_DEBIAN_NAME)
fetch_env(:PASSENGER_VERSION)
fetch_env(:NEXT_PASSENGER_VERSION)

puts "--> Extracting orig tarball"
sh "tar -C #{SPKG_DIR} -xzf /work/#{TARBALL}"

if DEBIAN_NAME =~ /passenger/
  puts "+ Loading Passenger constants"
  require("#{SPKG_DIR}/#{SOURCENAME}/src/ruby_supportlib/phusion_passenger")
  PhusionPassenger.locate_directories
  PhusionPassenger.require_passenger_lib 'constants'
  PhusionPassenger.require_passenger_lib 'config/nginx_engine_compiler'
  include PhusionPassenger
end

puts "--> Preprocessing Debian spec files"
puts "+ cd #{SPECDIR}"
Dir.chdir(SPECDIR)
Utils.recursive_copy_files(Dir["**/*"], "#{SPKG_DIR}/#{SOURCENAME}/debian", true,
  :distribution => DISTRIBUTION)

if DEBIAN_NAME =~ /nginx/
  puts "--> Copying Passenger files into Debian directory"
  puts "+ cd #{SPKG_DIR}/#{SOURCENAME}/debian/modules"
  Dir.chdir("#{SPKG_DIR}/#{SOURCENAME}/debian/modules")
  sh "tar xzf /work/#{PASSENGER_TARBALL}"
  sh "mv passenger* passenger"
  sh "rm -rf passenger/debian.template passenger/doc/images/* passenger/test passenger/packaging"
  sh "rm -rf passenger/nginx-*"
  Dir.chdir("../..") do
    Dir["debian/modules/passenger/doc/*.pdf"].each do |filename|
      File.open("debian/source/include-binaries", "a") do |f|
        puts "+ Including #{filename} as binary"
        f.puts filename
      end
    end
  end
end

puts "--> Updating Debian changelog file"
puts "+ cd #{SPKG_DIR}/#{SOURCENAME}"
Dir.chdir("#{SPKG_DIR}/#{SOURCENAME}")
changelog = File.read("debian/changelog")
changelog =
  "#{DEBIAN_NAME} (#{DEBIAN_EPOCH}:#{PACKAGE_VERSION}-" +
    "#{DEBIAN_VENDOR_VERSION}~#{DISTRIBUTION}#{DEBIAN_HOTFIX_VERSION}) " +
    "#{DISTRIBUTION}; urgency=low\n" +
  "\n" +
  "  * Package built.\n" +
  "\n" +
  " -- #{MAINTAINER_NAME} <#{MAINTAINER_EMAIL}>  #{Time.now.rfc2822}\n\n" +
  changelog
puts "+ Modifying debian/changelog"
File.open("debian/changelog", "w") do |f|
  f.write(changelog)
end

puts "--> Building Debian source package"
sh "ln /work/#{TARBALL} ../#{TARBALL}"
sh "debuild -us -uc -S"
