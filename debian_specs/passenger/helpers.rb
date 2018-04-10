def ruby_package_dependencies
  case distribution_class
  when :ubuntu
    if is_distribution?("<= saucy")
      "ruby1.8, ruby1.8-dev, rubygems1.8, ruby1.9.1, ruby1.9.1-dev"
    elsif is_distribution?("<= trusty")
      "ruby1.9.1, ruby1.9.1-dev, ruby2.0, ruby2.0-dev"
    elsif is_distribution?("<= artful")
      "ruby2.3, ruby2.3-dev"
    else
      # At least up to, and including, v18.04 Bionic 
      "ruby2.5, ruby2.5-dev"
    end
  when :debian
    if is_distribution?("<= wheezy")
      "ruby1.8, ruby1.8-dev, rubygems1.8, ruby1.9.1, ruby1.9.1-dev"
    elsif is_distribution?("<= jessie")
      "ruby2.1, ruby2.1-dev"
    else
      # At least up to, and including, v9 Stretch
      "ruby2.3, ruby2.3-dev"
    end
  else
    raise "Unknown distribution class"
  end
end

# Returns the Ruby versions available for a given distribution.
# The result is ordered from least preferred to most preferred.
def distro_ruby_versions
  case distribution_class
  when :ubuntu
    if is_distribution?("<= saucy")
      ["1.8", "1.9.1"]
    elsif is_distribution?("<= trusty")
      ["1.9.1", "2.0"]
    elsif is_distribution?("<= artful")
      ["2.3"]
    else
      # At least up to, and including, v18.04 Bionic 
      ["2.5"]
    end
  when :debian
    if is_distribution?("<= wheezy")
      ["1.8", "1.9.1"]
    elsif is_distribution?("<= jessie")
      ["2.1"]
    else
      # At least up to, and including, v9 Stretch
      ["2.3"]
    end
  else
    raise "Unknown distribution class"
  end
end

