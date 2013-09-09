#!/usr/bin/env ruby
require './preprocessor'

def sh(*command)
	puts "# #{command.join(' ')}"
	if !system(*command)
		abort "*** Command failed"
	end
end

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

if ALL_DISTRIBUTIONS.empty? || DEBIAN_ARCHS.empty?
	abort "Please run ./create_nginx_package instead of running this .rb file directly"
end

def download_nginx_tarball(nginx_version)
	if !File.exist?("#{PKG_DIR}/#{DEBIAN_NAME}_#{nginx_version}.orig.tar.gz")
		sh "mkdir -p #{PKG_DIR}"
		sh "curl -L -o #{PKG_DIR}/#{DEBIAN_NAME}_#{nginx_version}.orig.tar.gz http://nginx.org/download/nginx-#{nginx_version}.tar.gz"
	end
end

def create_passenger_tarball(passenger_dir, passenger_package, passenger_version)
	if !File.exist?("#{PKG_DIR}/#{passenger_package}-#{passenger_version}.tar.gz")
		sh "mkdir -p #{PKG_DIR}"
		pkg_dir = File.expand_path(PKG_DIR)
		sh "cd #{passenger_dir} && rake package:tarball PKG_DIR='#{pkg_dir}'"
	end
end

def infer_next_passenger_version(passenger_version)
	components = passenger_version.split(".")
	components.last.sub!(/[0-9]+$/) do |number|
		(number.to_i + 1).to_s
	end
	return components.join(".")
end

def create_debian_package_dir(distribution, passenger_package, passenger_version,
	nginx_version, package_version, output_dir = PKG_DIR)
	require 'time'

	variables = {
		:distribution => distribution,
		:passenger_version => passenger_version,
		:next_passenger_version => infer_next_passenger_version(passenger_version)
	}

	root = "#{output_dir}/#{distribution}"
	orig_tarball = File.expand_path("#{PKG_DIR}/#{DEBIAN_NAME}_#{package_version}.orig.tar.gz")
	passenger_tarball = File.expand_path("#{PKG_DIR}/#{passenger_package}-#{passenger_version}.tar.gz")

	sh "rm -rf #{root}"
	sh "mkdir -p #{root}"
	sh "cd #{root} && tar xzf #{orig_tarball}"
	sh "bash -c 'shopt -s dotglob && mv #{root}/nginx-#{nginx_version}/* #{root}'"
	sh "rmdir #{root}/nginx-#{nginx_version}"
	recursive_copy_files(Dir["nginx-debian/**/*"], root,
		true, variables)
	sh "mv #{root}/nginx-debian #{root}/debian"
	sh "cd #{root}/debian/modules && tar xzf #{passenger_tarball}"
	sh "cd #{root}/debian/modules && mv #{passenger_package}-#{passenger_version} passenger"
	changelog = File.read("#{root}/debian/changelog")
	changelog =
		"#{DEBIAN_NAME} (#{DEBIAN_EPOCH}:#{package_version}-1~#{distribution}1) #{distribution}; urgency=low\n" +
		"\n" +
		"  * Package built.\n" +
		"\n" +
		" -- #{MAINTAINER_NAME} <#{MAINTAINER_EMAIL}>  #{Time.now.rfc2822}\n\n" +
		changelog
	File.open("#{root}/debian/changelog", "w") do |f|
		f.write(changelog)
	end
end

def build_source_packages(passenger_dir)
	$LOAD_PATH.unshift(File.expand_path("#{passenger_dir}/lib"))
	require "phusion_passenger"
	passenger_package = PhusionPassenger::PACKAGE_NAME
	passenger_version = PhusionPassenger::VERSION_STRING
	nginx_version = PhusionPassenger::PREFERRED_NGINX_VERSION
	package_version = nginx_version

	download_nginx_tarball(nginx_version)
	create_passenger_tarball(passenger_dir, passenger_package, passenger_version)

	sh "rm -rf #{PKG_DIR}/nginx-#{nginx_version}"
	sh "cd #{PKG_DIR} && tar xzf #{DEBIAN_NAME}_#{nginx_version}.orig.tar.gz"

	if boolean_option('USE_CCACHE', false)
		# The resulting Debian rules file must not set USE_CCACHE.
		abort "USE_CCACHE must be returned off."
	end

	ALL_DISTRIBUTIONS.each do |distribution|
		create_debian_package_dir(distribution, passenger_package, passenger_version,
			nginx_version, package_version)
	end
	ALL_DISTRIBUTIONS.each do |distribution|
		sh "cd #{PKG_DIR}/#{distribution} && debuild -S -us -uc"
	end

	#files = Dir["nginx-debian/**/*"]
	#recursive_copy_files(files, "#{PKG_DIR}/#{DEBIAN_NAME}_#{package_version}")

	#sh "rm -rf #{PKG_DIR}/passenger-#{passenger_version}"
	#sh "cd #{PKG_DIR}/#{DEBIAN_NAME}_#{package_version} && tar xvf passenger-#{passenger_version}.tar.gz"

	#sh "cd #{PKG_DIR}/#{DEBIAN_NAME}_#{package_version} && tar xzf #{local_nginx_tarball}"
	#sh "cd #{PKG_DIR} && tar -c #{DEBIAN_NAME}_#{package_version} | gzip --best > #{DEBIAN_NAME}_#{package_version}.orig.tar.gz"
end

def start
	passenger_dir = ARGV[0]
	build_source_packages(passenger_dir)
end

start
