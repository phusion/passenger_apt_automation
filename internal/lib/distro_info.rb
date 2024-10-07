require 'open-uri'
require 'json'
require 'csv'
require 'nokogiri'

def gen_distros(family)
  throw "must be run from #{family}" unless File.exist?("/usr/share/distro-info/#{family}.csv")
  CSV.read("/usr/share/distro-info/#{family}.csv", headers: true).each_with_object(Hash.new) { |r, a|
    a[r["series"]] = r.fetch("version")&.sub(/(\.0|\sLTS)\z/, "")
  }.compact
end

UBUNTU_DISTRIBUTIONS = gen_distros("ubuntu")

DEBIAN_DISTRIBUTIONS = gen_distros("debian").transform_values(&:to_i)

# A list of distribution codenames for which the `build` script
# will build for, and for which the `test` script will test for.
DEFAULT_DISTROS = %w(
  focal
  jammy
  noble
  oracular

  bullseye
  bookworm
)

###### Helper methods ######

def ubuntu_gte(codename, compare)
  generic_gte(UBUNTU_DISTRIBUTIONS, codename, compare)
end

def debian_gte(codename, compare)
  generic_gte(DEBIAN_DISTRIBUTIONS, codename, compare)
end

def generic_gte(hash, codename, compare)
  return nil if !hash.key?(codename)
  hash[codename] >= hash[compare]
end

def to_distro_codename(input)
  UBUNTU_DISTRIBUTIONS.each_pair do |codename, version|
    if input == codename \
       || input == "ubuntu-#{version}" \
       || input == "ubuntu#{version}"
      return codename
    end
  end

  DEBIAN_DISTRIBUTIONS.each_pair do |codename, version|
    if input == codename \
       || input == "debian-#{version}" \
       || input == "debian#{version}"
      return codename
    end
  end

  nil
end

def valid_distro_name?(name)
  UBUNTU_DISTRIBUTIONS.key?(name) || DEBIAN_DISTRIBUTIONS.key?(name)
end

def fetch_latest_nginx_version_from_launchpad_api(distro)
  ['Updates', 'Security', 'Release'].each do |pocket|
    url = "https://api.launchpad.net/1.0/ubuntu/+archive/primary?ws.op=getPublishedBinaries&binary_name=nginx&exact_match=true&distro_arch_series=https://api.launchpad.net/1.0/ubuntu/#{distro}/amd64&status=Published&pocket=#{pocket}"
    if RUBY_VERSION >= '2.5'
      data = URI.open(url) do |io|
        io.read
      end
    else
      data = open(url) do |io|
        io.read
      end
    end
    entry = JSON.parse(data)['entries'][0]
    if entry
      return entry['binary_package_version']
    end
  end
  abort "Unable to query Launchpad for latest Nginx version in Ubuntu #{distro}"
end

def extract_nginx_version(os, distro, sanitize)
  cache_file = "/tmp/#{distro}_nginx_version.txt"
  if !File.exist?(cache_file) || ((Time.now - 60*60*24) > File.mtime(cache_file))
    if UBUNTU_DISTRIBUTIONS.key?(distro)
      version = fetch_latest_nginx_version_from_launchpad_api(distro)
    elsif DEBIAN_DISTRIBUTIONS.key?(distro)
      url = "https://packages.debian.org/search?suite=#{distro}&exact=1&searchon=names&keywords=nginx"
      if RUBY_VERSION >= '2.5'
        doc = URI.open(url) do |io|
          Nokogiri.XML(io)
        end
      else
        doc = open(url) do |io|
          Nokogiri.XML(io)
        end
      end
      version = doc.at_css('#psearchres ul li').text.lines.select{|s|s.include? ": all" or s.include? ": amd64 arm64"}.first.strip.split.first.chomp(':')
    end
    File.write(cache_file,version)
  else
    version = File.read(cache_file)
  end
  version.gsub!(/(-[0-9]+|{os}).*/, '') if sanitize
  version
end

def dynamic_module_supported?(distro)
  ubuntu_gte(distro, "artful") || debian_gte(distro, "stretch")
end

def systemd_tmpfiles?(distro)
  ubuntu_gte(distro, "vivid") || debian_gte(distro, "jessie")
end

def latest_nginx_sanitized(distro, sanitized)
  if UBUNTU_DISTRIBUTIONS.key?(distro)
    os = 'ubuntu'
  elsif DEBIAN_DISTRIBUTIONS.key?(distro)
    os = 'debian'
  else
    # unknown distro
    return ""
  end
  return extract_nginx_version(os, distro, sanitized)
end

def latest_nginx_unsanitized(distro)
  return latest_nginx_sanitized(distro, false)
end

def latest_nginx_available(distro)
  latest_nginx_sanitized(distro, true)
end

def next_nginx_tiny_version(distro)
  version_number = latest_nginx_available(distro)
  components = version_number.split('.')

  tiny_version = components.last
  if tiny_version !~ /\A[0-9]+\Z/
    raise "Error parsing Nginx version number: #{version_number}"
  end

  components[-1] = tiny_version.to_i + 1
  components.join('.')
end
