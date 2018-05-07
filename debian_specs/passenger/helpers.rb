def ruby_package_dependencies
  case distribution_class
  when :ubuntu
    if is_distribution?("<= artful")
      "ruby2.3, ruby2.3-dev"
    else
      # At least up to, and including, v18.04 Bionic 
      "ruby2.5, ruby2.5-dev"
    end
  when :debian
    # At least up to, and including, v9 Stretch
    "ruby2.3, ruby2.3-dev"
  else
    raise "Unknown distribution class"
  end
end

# Returns the Ruby versions available for a given distribution.
# The result is ordered from least preferred to most preferred.
def distro_ruby_versions
  case distribution_class
  when :ubuntu
    if is_distribution?("<= artful")
      ["2.3"]
    else
      # At least up to, and including, v18.04 Bionic 
      ["2.5"]
    end
  when :debian
    # At least up to, and including, v9 Stretch
    ["2.3"]
  else
    raise "Unknown distribution class"
  end
end

