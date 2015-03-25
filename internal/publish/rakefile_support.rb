require_relative '../lib/distro_info'

REPOSITORY = ENV['REPOSITORY']
YANK       = !!ENV['YANK']
SHOW_TASKS = !!ENV['SHOW_TASKS']

def initialize_rakefile!
  STDOUT.sync = true
  STDERR.sync = true
  Dir.chdir("/system/internal/publish")
  Kernel.const_set(:DISTROS, infer_distros_info)
end

def infer_distros_info
  result = []
  Dir["/output/*"].each do |path|
    distro = File.basename(path)
    if UBUNTU_DISTRIBUTIONS[distro]
      result << ["ubuntu", distro]
    elsif DEBIAN_DISTRIBUTIONS[distro]
      result << ["debian", distro]
    else
      abort "Unknown distribution name: #{distro}"
    end
  end
  result
end
