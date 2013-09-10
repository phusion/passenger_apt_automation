#!/usr/bin/env ruby
require './preprocessor'

def string_option(name, default_value = nil)
	value = ENV[name]
	if value.nil? || value.empty?
		return default_value
	else
		return value
	end
end

def boolean_option(name, default_value = false)
	value = ENV[name]
	if value.nil? || value.empty?
		return default_value
	else
		return value == "yes" || value == "on" || value == "true" || value == "1"
	end
end

def recursive_copy_files(files, destination_dir, preprocess = false, variables = {})
	require 'fileutils' if !defined?(FileUtils)
	if !STDOUT.tty?
		puts "Copying files..."
	end
	files.each_with_index do |filename, i|
		dir = File.dirname(filename)
		if !File.exist?("#{destination_dir}/#{dir}")
			FileUtils.mkdir_p("#{destination_dir}/#{dir}")
		end
		if !File.directory?(filename)
			if preprocess && filename =~ /\.template$/
				real_filename = filename.sub(/\.template$/, '')
				FileUtils.install(filename, "#{destination_dir}/#{real_filename}", :preserve => true)
				Preprocessor.new.start(filename, "#{destination_dir}/#{real_filename}",
					variables)
			else
				FileUtils.install(filename, "#{destination_dir}/#{filename}", :preserve => true)
			end
		end
		if STDOUT.tty?
			printf "\r[%5d/%5d] [%3.0f%%] Copying files...", i + 1, files.size, i * 100.0 / files.size
			STDOUT.flush
		end
	end
	if STDOUT.tty?
		printf "\r[%5d/%5d] [%3.0f%%] Copying files...\n", files.size, files.size, 100
	end
end

PKG_DIR = string_option('PKG_DIR', 'pkg')
ALL_DISTRIBUTIONS  = string_option("DEBIAN_DISTROS", "").split(/[ ,]/)
DEBIAN_NAME        = "nginx"
DEBIAN_EPOCH       = 1
DEBIAN_ARCHS       = string_option("DEBIAN_ARCHS", "").split(/[ ,]/)
MAINTAINER_NAME    = "Phusion"
MAINTAINER_EMAIL   = "info@phusion.nl"
PASSENGER_DIR      = string_option("PASSENGER_DIR") || abort("Please set the environment variable PASSENGER_DIR")

$LOAD_PATH.unshift(File.expand_path("#{PASSENGER_DIR}/lib"))
require "phusion_passenger"
require "phusion_passenger/constants"
PASSENGER_PACKAGE = PhusionPassenger::PACKAGE_NAME
PASSENGER_VERSION = PhusionPassenger::VERSION_STRING
NGINX_VERSION     = PhusionPassenger::PREFERRED_NGINX_VERSION
PACKAGE_VERSION   = NGINX_VERSION
if defined?(PhusionPassenger::PASSENGER_IS_ENTERPRISE)
	# Let users see nginx updates after switching to the Enterprise repo.
	VENDOR_VERSION = 3
else
	VENDOR_VERSION = 2
end

if ALL_DISTRIBUTIONS.empty? || DEBIAN_ARCHS.empty?
	abort "Please run ./create_nginx_package instead of running this .rb file directly"
end

task :default do
	abort "Please run ./create_nginx_package -T for possible tasks"
end


def download_nginx_tarball
	if !File.exist?("#{PKG_DIR}/#{DEBIAN_NAME}_#{NGINX_VERSION}.orig.tar.gz")
		sh "mkdir -p #{PKG_DIR}"
		sh "curl -L -o #{PKG_DIR}/#{DEBIAN_NAME}_#{NGINX_VERSION}.orig.tar.gz http://nginx.org/download/nginx-#{NGINX_VERSION}.tar.gz"
	end
end

def create_passenger_tarball
	if !File.exist?("#{PKG_DIR}/#{PASSENGER_PACKAGE}-#{PASSENGER_VERSION}.tar.gz")
		sh "mkdir -p #{PKG_DIR}"
		pkg_dir = File.expand_path(PKG_DIR)
		sh "cd #{PASSENGER_DIR} && rake package:tarball PKG_DIR='#{pkg_dir}'"
	end
end

def infer_next_passenger_version
	components = PASSENGER_VERSION.split(".")
	components.last.sub!(/[0-9]+$/) do |number|
		(number.to_i + 1).to_s
	end
	return components.join(".")
end

def create_debian_package_dir(distribution, output_dir = PKG_DIR)
	require 'time'

	variables = {
		:distribution => distribution,
		:passenger_version => PASSENGER_VERSION,
		:next_passenger_version => infer_next_passenger_version
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
		"#{DEBIAN_NAME} (#{DEBIAN_EPOCH}:#{PACKAGE_VERSION}-#{VENDOR_VERSION}~#{distribution}1) #{distribution}; urgency=low\n" +
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
		base_name = "#{DEBIAN_NAME}_#{PACKAGE_VERSION}-#{VENDOR_VERSION}~#{distribution}1"
		sh "cd #{PKG_DIR} && pbuilder-dist #{distribution} #{arch} build #{base_name}.dsc"
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
		abort "Please run './create_nginx_package source_packages' first."
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
