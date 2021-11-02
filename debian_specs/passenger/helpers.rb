def ruby_package_dependencies
  case distribution_class
  when :ubuntu
    if is_distribution?("<= artful")
      "ruby2.3, ruby2.3-dev"
    elsif is_distribution?(">= focal")
      "ruby2.7, ruby2.7-dev"
    else
      # v18.04 Bionic
      "ruby2.5, ruby2.5-dev"
    end
  when :debian
    if is_distribution?("<= jessie")
      "ruby2.1, ruby2.1-dev"
    elsif is_distribution?("<= stretch")
      "ruby2.3, ruby2.3-dev"
    elsif is_distribution?("<= buster")
      "ruby2.5, ruby2.5-dev"
    else
      # bullseye
      "ruby2.7, ruby2.7-dev"
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
    if is_distribution?("<= artful")
      ["2.3"]
    elsif is_distribution?(">= focal")
      ["2.7"]
    else
      # v18.04 Bionic
      ["2.5"]
    end
  when :debian
    if is_distribution?("<= jessie")
      ["2.1"]
    elsif is_distribution?("<= stretch")
      ["2.3"]
    elsif is_distribution?("<= buster")
      ["2.5"]
    else
      # bullseye
      ["2.7"]
    end
  else
    raise "Unknown distribution class"
  end
end
