#!/usr/bin/env ruby
require './lib/rubylib'
require 'shellwords'
require 'time'

PKG_DIR            = string_option('PKG_DIR', 'pkg')
ALL_DISTRIBUTIONS  = string_option("DEBIAN_DISTROS", "").split(/[ ,]/)
DEBIAN_NAME        = "nginx"
DEBIAN_EPOCH       = 1
DEBIAN_ARCHS       = string_option("DEBIAN_ARCHS", "").split(/[ ,]/)
MAINTAINER_NAME    = "Phusion"
MAINTAINER_EMAIL   = "info@phusion.nl"
PASSENGER_DIR      = string_option("PASSENGER_DIR")
NGINX_HOTFIX_VERSION = ENV['NGINX_HOTFIX_VERSION'] || '1'

if PASSENGER_DIR
	require "#{PASSENGER_DIR}/lib/phusion_passenger"
	PhusionPassenger.locate_directories
	PhusionPassenger.require_passenger_lib "constants"
	PASSENGER_PACKAGE = PhusionPassenger::PACKAGE_NAME
	PASSENGER_VERSION = PhusionPassenger::VERSION_STRING
	NGINX_VERSION     = PhusionPassenger::PREFERRED_NGINX_VERSION
	PACKAGE_VERSION   = NGINX_VERSION
	if defined?(PhusionPassenger::PASSENGER_IS_ENTERPRISE)
		# Let users see nginx updates after switching to the Enterprise repo.
		VENDOR_VERSION = 3
		PASSENGER_DEBIAN_NAME = "passenger-enterprise"
	else
		VENDOR_VERSION = 2
		PASSENGER_DEBIAN_NAME = "passenger"
	end
end


def download_nginx_tarball
	if !File.exist?("#{PKG_DIR}/#{DEBIAN_NAME}_#{NGINX_VERSION}.orig.tar.gz")
		sh "mkdir -p #{PKG_DIR}"
		sh "curl --fail -L -o #{PKG_DIR}/#{DEBIAN_NAME}_#{NGINX_VERSION}.orig.tar.gz http://nginx.org/download/nginx-#{NGINX_VERSION}.tar.gz"
	end
end

def create_passenger_tarball
	if !File.exist?("#{PKG_DIR}/#{PASSENGER_PACKAGE}-#{PASSENGER_VERSION}.tar.gz")
		sh "mkdir -p #{PKG_DIR}"
		pkg_dir = File.expand_path(PKG_DIR)
		sh "cd #{PASSENGER_DIR} && rake package:tarball PKG_DIR=#{Shellwords.escape pkg_dir}"
	end
end

def create_debian_package_dir(distribution, output_dir = PKG_DIR)
	variables = {
		:distribution => distribution,
		:passenger_version => PASSENGER_VERSION,
		:next_passenger_version => infer_next_passenger_version(PASSENGER_VERSION)
	}

	root = "#{output_dir}/#{distribution}"
	orig_tarball = File.expand_path("#{PKG_DIR}/#{DEBIAN_NAME}_#{PACKAGE_VERSION}.orig.tar.gz")
	passenger_tarball = File.expand_path("#{PKG_DIR}/#{PASSENGER_PACKAGE}-#{PASSENGER_VERSION}.tar.gz")

	sh "rm -rf #{root}"
	sh "mkdir -p #{root}"
	sh "cd #{root} && tar xzf #{orig_tarball}"
	sh "bash -c 'shopt -s dotglob && mv #{root}/nginx-#{NGINX_VERSION}/* #{root}'"
	sh "rmdir #{root}/nginx-#{NGINX_VERSION}"
	recursive_copy_files(Dir["nginx-debian/**/*"], root,
		true, variables)
	sh "mv #{root}/nginx-debian #{root}/debian"
	sh "cd #{root}/debian/modules && tar xzf #{passenger_tarball}"
	sh "cd #{root}/debian/modules && mv #{PASSENGER_PACKAGE}-#{PASSENGER_VERSION} passenger"
	sh "cd #{root}/debian/modules/passenger && rm -rf doc/images test rpm"
	Dir.chdir(root) do
		Dir["debian/modules/passenger/doc/*.pdf"].each do |filename|
			File.open("#{root}/debian/source/include-binaries", "a") do |f|
				f.puts filename
			end
		end
	end
	changelog = File.read("#{root}/debian/changelog")
	changelog =
		"#{DEBIAN_NAME} (#{DEBIAN_EPOCH}:#{PACKAGE_VERSION}-#{VENDOR_VERSION}.#{PASSENGER_VERSION}~#{distribution}#{NGINX_HOTFIX_VERSION}) #{distribution}; urgency=low\n" +
		"\n" +
		"  * Package built.\n" +
		"\n" +
		" -- #{MAINTAINER_NAME} <#{MAINTAINER_EMAIL}>  #{Time.now.rfc2822}\n\n" +
		changelog
	File.open("#{root}/debian/changelog", "w") do |f|
		f.write(changelog)
	end
end

desc "Build Debian source packages"
task :source_packages do
	download_nginx_tarball
	create_passenger_tarball

	sh "rm -rf #{PKG_DIR}/nginx-#{NGINX_VERSION}"
	sh "cd #{PKG_DIR} && tar xzf #{DEBIAN_NAME}_#{NGINX_VERSION}.orig.tar.gz"

	if boolean_option('USE_CCACHE', false)
		# The resulting Debian rules file must not set USE_CCACHE.
		abort "USE_CCACHE must be returned off."
	end

	ALL_DISTRIBUTIONS.each do |distribution|
		create_debian_package_dir(distribution)
	end
	ALL_DISTRIBUTIONS.each do |distribution|
		sh "cd #{PKG_DIR}/#{distribution} && debuild -S -us -uc"
	end
end

def pbuilder_base_name(distribution, arch)
	if arch == "amd64"
		return distribution
	else
		return "#{distribution}-#{arch}"
	end
end

def create_binary_package_task(distribution, arch)
	desc "Build Debian binary package for #{distribution} #{arch}"
	task "binary_packages:#{distribution}_#{arch}" => 'binary_packages:prepare' do
		base_name = "#{DEBIAN_NAME}_#{PACKAGE_VERSION}-#{VENDOR_VERSION}.#{PASSENGER_VERSION}~#{distribution}#{NGINX_HOTFIX_VERSION}"
		logfile = "#{PKG_DIR}/nginx_#{distribution}_#{arch}.log"
		command = "cd #{PKG_DIR} && " +
			"pbuilder-dist #{distribution} #{arch} build #{base_name}.dsc " +
			"2>&1 | awk '{ print strftime(\"%Y-%m-%d %H:%M:%S -- \"), $0; fflush(); }'" +
			" | tee #{logfile}; test ${PIPESTATUS[0]} -eq 0"
		sh "bash -c #{Shellwords.escape(command)}"
		sh "echo Done >> #{logfile}"
	end
	return "binary_packages:#{distribution}_#{arch}"
end

BINARY_PACKAGES_TASKS = []
ALL_DISTRIBUTIONS.each do |distribution|
	DEBIAN_ARCHS.each do |arch|
		BINARY_PACKAGES_TASKS << create_binary_package_task(distribution, arch)
	end
end

task 'binary_packages:prepare' do
	if !File.exist?(PKG_DIR)
		abort "Please run './create-nginx-packages source_packages' first."
	end

	pbuilder_dir = File.expand_path("~/pbuilder")
	ALL_DISTRIBUTIONS.each do |distribution|
		DEBIAN_ARCHS.each do |arch|
			pbase_name = pbuilder_base_name(distribution, arch) + "-base.tgz"
			if !File.exist?("#{pbuilder_dir}/#{pbase_name}")
				abort "Missing pbuilder environment for #{distribution}-#{arch}. " +
					"Please run this first: pbuilder-dist #{distribution} #{arch} create"
			end
		end
	end
end

desc "Build Debian binary packages with pbuilder"
task :binary_packages => BINARY_PACKAGES_TASKS
