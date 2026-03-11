def ruby_package_dependencies
  distro_ruby_versions.map { |ver| "ruby#{ver}, ruby#{ver}-dev" }.join(", ")
end

# Returns the Ruby versions available for a given distribution.
# The result is ordered from least preferred to most preferred.
def distro_ruby_versions
  case distribution_class
  when :ubuntu
    if is_distribution?("<= impish") # 21.10
      ["2.7"]
    elsif is_distribution?("<= kinetic") # 22.10
      ["3.0"]
    elsif is_distribution?("<= mantic") # 23.10
      ["3.1"]
    elsif is_distribution?("== noble") # 24.04
      ["3.2"]
    else # 24.10+
      ["3.3"]
    end
  when :debian
    if is_distribution?("<= bullseye")
      ["2.7"]
    elsif is_distribution?("<= bookworm")
      ["3.1"]
    else # trixie+
      ["3.3"]
    end
  else
    raise "Unknown distribution class"
  end
end
