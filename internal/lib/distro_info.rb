require 'uri'
require 'net/http'
require 'open-uri'
require 'json'
require 'csv'
require 'nokogiri'
require "zlib"

# After editing this file regenerate distro_info.sh by running:
# internal/scripts/regen_distro_info_script.sh

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
# https://ubuntu.com/about/release-cycle
# https://www.debian.org/releases/
DEFAULT_DISTROS = %w[
  jammy
  noble
  resolute

  bullseye
  bookworm
  trixie
]

###### Helper methods ######

def ubuntu_gte(codename, compare)
  generic_gte(UBUNTU_DISTRIBUTIONS, codename, compare)
end

def debian_gte(codename, compare)
  generic_gte(DEBIAN_DISTRIBUTIONS, codename, compare)
end

def is_ubuntu(codename)
  UBUNTU_DISTRIBUTIONS.keys.include?  codename
end

def is_debian(codename)
  DEBIAN_DISTRIBUTIONS.keys.include?  codename
end

def generic_gte(hash, codename, compare)
  return nil unless hash.key?(codename)
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

def systemd_tmpfiles?(distro)
  ubuntu_gte(distro, "vivid") || debian_gte(distro, "jessie")
end

def deb_comparitor(deb_a, op, deb_b)
  op_map = {
   '=' => 'eq',
  '==' => 'eq',
  '!=' => 'ne',
   '<' => 'lt',
  '<=' => 'le',
   '>' => 'gt',
  '>=' => 'ge',
  }
  raise ArgumentError, "deb a was nil" if deb_a.nil?
  raise ArgumentError, "deb b was nil" if deb_b.nil?
  system("dpkg", "--compare-versions", deb_a, op_map.fetch(op.to_s), deb_b)
end

def latest_nginx_unsanitized(distro)
  arch = "amd64"
  if is_ubuntu(distro)
    uri = "https://archive.ubuntu.com/ubuntu/dists/#{distro}/main/binary-#{arch}/Packages.gz"
  else
    uri = "https://ftp.debian.org/debian/dists/#{distro}/main/binary-#{arch}/Packages.gz"
  end
  uri = URI(uri)
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    http.request(Net::HTTP::Get.new(URI(uri))) do |r|
      if r.code.to_i < 300
        return Zlib::GzipReader.new(StringIO.new(r.body)).read.split(/\n\n+/).filter do |p|
          p.start_with?("Package: nginx-common\n")
        end.map do |p|
          p.lines.find { |l| l.start_with? "Version:" }.split(":").last.strip
        end.sort do |va, vb|
          next 0 if va == vb
          deb_comparitor(va, :>, vb) ? 1 : -1
        end.last
      else
        raise "#{uri} encountered error: #{r.message}"
      end
    end
  end
end
# [upstream_version]-[debian_revision_component]ubuntu[ubuntu_revision_component]
def latest_nginx_version_upstream(distro)
  latest_nginx_unsanitized(distro).split('-').first
end

def latest_nginx_version_debian_revision(distro)
  latest_nginx_unsanitized(distro).split('-').last.split('ubuntu').first
end

def latest_nginx_version_ubuntu_revision(distro)
  latest_nginx_unsanitized(distro).split('-').last.split('ubuntu').last
end
