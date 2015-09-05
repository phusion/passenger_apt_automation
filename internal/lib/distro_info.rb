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
  "wily"     => "15.10"
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
  precise
  trusty
  vivid
  wily

  squeeze
  wheezy
  jessie
)


###### Helper methods ######

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

def to_testbox_image(input)
  UBUNTU_DISTRIBUTIONS.each_pair do |codename, version|
    if input == codename \
        || input == "ubuntu-#{version}" \
        || input == "ubuntu#{version}"
      return "phusion/passenger_apt_automation_testbox_ubuntu_#{version.gsub('.', '_')}"
    end
  end

  DEBIAN_DISTRIBUTIONS.each_pair do |codename, version|
    if input == codename \
        || input == "ubuntu-#{version}" \
        || input == "ubuntu#{version}"
      return "phusion/passenger_apt_automation_testbox_debian_#{vesion}"
    end
  end

  nil
end

def valid_distro_name?(name)
  UBUNTU_DISTRIBUTIONS.key?(name) || DEBIAN_DISTRIBUTIONS.key?(name)
end
