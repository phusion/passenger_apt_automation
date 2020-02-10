require_relative '../lib/distro_info'
require 'net/http/persistent'
require 'uri'
require 'json'

REPOSITORY = ENV['REPOSITORY']
YANK       = ENV['YANK'] == 'true'
YANK_ALL   = !YANK && ENV['YANK_ALL'] == 'true'
SHOW_TASKS = ENV['SHOW_TASKS'] == 'true'
SHOW_OVERVIEW_PERIODICALLY = ENV['SHOW_OVERVIEW_PERIODICALLY'] == 'true'

def initialize_rakefile!
  STDOUT.sync = true
  STDERR.sync = true
  Dir.chdir("/system/internal/publish")
  Kernel.const_set(:DISTROS, infer_distros_info)
  initialize_repo_server_client!
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

def initialize_repo_server_client!
  if SHOW_TASKS
    Kernel.const_set(:REPO_SERVER_YANK_ALL_TASKS, [])
  else
    Kernel.const_set(:REPO_SERVER_API_USERNAME, ENV['REPO_SERVER_API_USERNAME'])
    Kernel.const_set(:REPO_SERVER_API_TOKEN, File.read("/repo_server_api_token.txt").strip)
    Kernel.const_set(:REPO_SERVER_HTTP, make_repo_server_http)
    if YANK_ALL
      Kernel.const_set(:REPO_SERVER_YANK_ALL_TASKS, [:yank_all])
    else
      Kernel.const_set(:REPO_SERVER_YANK_ALL_TASKS, [])
    end
  end
end

def make_repo_server_http
  http = Net::HTTP::Persistent.new
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http
end

def retry_at_most(task, max)
  tries = 0
  begin
    tries += 1
    yield
  rescue TrackingTask::CommandError => e
    if tries < max
      task.log(Paint["*** Retrying command: #{tries + 1} of #{max}", :yellow])
      sleep 0.5 + rand(0.5)
      retry
    else
      raise e
    end
  end
end
