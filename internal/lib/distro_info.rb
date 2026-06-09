require 'open-uri'
require 'json'
require 'csv'
require 'nokogiri'

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
