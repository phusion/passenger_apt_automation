UBUNTU_DISTRIBUTIONS = {
  "lucid"    => "10.04",
  "maverick" => "10.10",
  "natty"    => "11.04",
  "oneiric"  => "11.10",
  "precise"  => "12.04",
  "quantal"  => "12.10",
  "raring"   => "13.04",
  "saucy"    => "13.10",
  "trusty"   => "14.04",
  "utopic"   => "14.10",
  "vivid"    => "15.04",
  "wily"     => "15.10",
  "xenial"   => "16.04",
  "yakkety"  => "16.10",
  "zesty"    => "17.04",
  "artful"   => "17.10"
}

DEBIAN_DISTRIBUTIONS = {
  "squeeze"  => 6,
  "wheezy"   => 7,
  "jessie"   => 8,
  "stretch"  => 9,
  "buster"   => 10
}

# A list of distribution codenames for which the `build` script
# will build for, and for which the `test` script will test for.
DEFAULT_DISTROS = %w(
  trusty
  xenial
  artful

  wheezy
  jessie
  stretch
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

def extract_nginx_version(os, distro, sanitize)
  cache_file = "/tmp/#{distro}_nginx_version.txt"
  if !File.exists?(cache_file) || ((Time.now - 60*60*24) > File.mtime(cache_file))
    require 'open-uri'
    if UBUNTU_DISTRIBUTIONS.key?(distro)
      require 'json'
      uri = "https://api.launchpad.net/1.0/ubuntu/+archive/primary?ws.op=getPublishedBinaries&binary_name=nginx&exact_match=true&distro_arch_series=https://api.launchpad.net/1.0/ubuntu/#{distro}/amd64&status=Published"
      version = JSON.parse(open(uri).read)["entries"][0]["binary_package_version"]
    elsif DEBIAN_DISTRIBUTIONS.key?(distro)
      require 'nokogiri'
      version = Nokogiri::XML(open("https://packages.debian.org/search?suite=#{distro}&exact=1&searchon=names&keywords=nginx")).at_css('#psearchres ul li').text.lines.select{|s|s.include? ": all"}.first.strip.split.first.chomp(':')
    end
    File.write(cache_file,version)
  else
    version = File.read(cache_file)
  end
  version.gsub!(/(-[0-9]+|{os}).*/,"") if sanitize
  version
end

def dynamic_module_supported?(distro)
  ubuntu_gte(distro, "artful") || debian_gte(distro, "stretch")
end

def latest_nginx_sanitized?(distro, sanitized)
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
  return latest_nginx_sanitized?(distro, false)
end

def latest_nginx_available(distro)
  latest_nginx_sanitized?(distro, true)
end
