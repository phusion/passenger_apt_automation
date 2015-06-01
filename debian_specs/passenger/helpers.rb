# Returns the Ruby versions available for a given distribution.
# The result is ordered from least preferred to most preferred.
def distro_ruby_versions
  case distribution_class
  when :ubuntu
    if is_distribution?("<= saucy")
      ["1.8", "1.9.1"]
    elsif is_distribution?("<= trusty")
      ["1.9.1", "2.0"]
    elsif is_distribution?("<= utopic")
      ["2.0", "2.1"]
    else
      ["2.1"]
    end
  when :debian
    if is_distribution?("<= wheezy")
      ["1.8", "1.9.1"]
    else
      ["2.1"]
    end
  else
    raise "Unknown distribution class"
  end
end
