def ruby_package_dependencies
  case distribution_class
  when :ubuntu
    if is_distribution?("<= artful")
      "ruby2.3, ruby2.3-dev"
    elsif is_distribution?("<= eoan")
      # v18.04 Bionic -> v19.10 Eoan
      "ruby2.5, ruby2.5-dev"
    elsif is_distribution?("<= impish")
      # v20.04 Focal -> v21.10 Impish
      "ruby2.7, ruby2.7-dev"
    elsif is_distribution?("<= kinetic")
      # v22.04 Jolly -> v22.10 Kinetic
      "ruby3.0, ruby3.0-dev"
    elsif is_distribution?("<= mantic")
      # v23.04 Lunar -> v23.10 Mantic
      "ruby3.1, ruby3.1-dev"
    elsif is_distribution?("== noble")
      # v24.04 Noble
      "ruby3.2, ruby3.2-dev"
    else
      # v24.10 Oracular -> ???
      "ruby3.3, ruby3.3-dev"
    end
  when :debian
    if is_distribution?("<= jessie")
      "ruby2.1, ruby2.1-dev"
    elsif is_distribution?("<= stretch")
      "ruby2.3, ruby2.3-dev"
    elsif is_distribution?("<= buster")
      "ruby2.5, ruby2.5-dev"
    elsif is_distribution?("<= bullseye")
      "ruby2.7, ruby2.7-dev"
    else
      # bookworm
      "ruby3.1, ruby3.1-dev"
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
    elsif is_distribution?("<= eoan")
      ["2.5"]
    elsif is_distribution?("<= impish")
      ["2.7"]
    elsif is_distribution?("<= kinetic")
      ["3.0"]
    elsif is_distribution?("<= mantic")
      ["3.1"]
    elsif is_distribution?("== noble")
      ["3.2"]
    else
      ["3.3"]
    end
  when :debian
    if is_distribution?("<= jessie")
      ["2.1"]
    elsif is_distribution?("<= stretch")
      ["2.3"]
    elsif is_distribution?("<= buster")
      ["2.5"]
    elsif is_distribution?("<= bullseye")
      ["2.7"]
    else
      ["3.1"]
    end
  else
    raise "Unknown distribution class"
  end
end
