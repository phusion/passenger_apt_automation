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
  initialize_packagecloud!
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

def initialize_packagecloud!
  if SHOW_TASKS
    Kernel.const_set(:PACKAGECLOUD_YANK_ALL_TASKS, [])
    Kernel.const_set(:PACKAGECLOUD_PACKAGE_NAMES, [])
    Kernel.const_set(:PACKAGECLOUD_PACKAGE_URLS, [])
  else
    Kernel.const_set(:PACKAGECLOUD_TOKEN, File.read("/package_cloud_token.txt").strip)
    path = File.expand_path("~/.packagecloud")
    File.open(path, "w") do |f|
      f.puts %Q({"url":"https://packagecloud.io", "token": "#{PACKAGECLOUD_TOKEN}"})
      f.chmod(0600)
    end

    Kernel.const_set(:PACKAGECLOUD_HTTP, make_packagecloud_http)

    if YANK_ALL
      names, urls = get_packagecloud_package_urls
      Kernel.const_set(:PACKAGECLOUD_YANK_ALL_TASKS, generate_yank_all_task_names(names))
      Kernel.const_set(:PACKAGECLOUD_PACKAGE_NAMES, names)
      Kernel.const_set(:PACKAGECLOUD_PACKAGE_URLS, urls)
    else
      Kernel.const_set(:PACKAGECLOUD_YANK_ALL_TASKS, [])
      Kernel.const_set(:PACKAGECLOUD_PACKAGE_NAMES, [])
      Kernel.const_set(:PACKAGECLOUD_PACKAGE_URLS, [])
    end
  end
end

def make_packagecloud_http
  expected_fingerprints = File.read("/system/internal/publish/packagecloud_fingerprint.txt").split("\n")

  http = Net::HTTP::Persistent.new
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http.verify_callback = lambda do |preverify_ok, store_context|
    if preverify_ok && store_context.error == 0
      verify_certificate_chain('packagecloud.io',
        store_context.chain, expected_fingerprints)
    else
      false
    end
  end

  http
end

def verify_certificate_chain(host, chain, expected_fingerprints)
  chain_fingerprints = {}
  chain.each do |chain_item|
    certificate = OpenSSL::X509::Certificate.new(chain_item)
    fingerprint = Digest::SHA256.hexdigest(certificate.to_der).upcase.scan(/../).join(":")
    chain_fingerprints[certificate.subject] = fingerprint
  end

  if chain_fingerprints.values.any? { |v| expected_fingerprints.include?(v) }
    true
  else
    message = "Fingerprint verification for #{host} failed.\n" \
      "  Expected: #{expected_fingerprints.inspect}\n" \
      "  Actual  :\n"
    chain_fingerprints.each_pair do |subject, fingerprint|
      message << "    - #{subject}\n"
      message << "      #{fingerprint}\n"
    end
    STDERR.puts(message)
    false
  end
end

def get_packagecloud_package_urls
  items = []
  current_url = URI.parse("https://packagecloud.io/api/v1/repos/phusion/#{REPOSITORY}/packages.json?per_page=100")

  while current_url
    puts "Fetching #{current_url}"
    request = Net::HTTP::Get.new(uri_path_and_query_string(current_url))
    request.basic_auth(PACKAGECLOUD_TOKEN, "")
    response = PACKAGECLOUD_HTTP.request(current_url, request)
    if response.code != "200"
      abort "Unable to query PackageCloud repository package list:\n" +
        "URL   : #{current_url}\n" +
        "Status: #{response.code}\n" +
        "Body  : #{response.body}"
    end

    JSON.parse(response.body).each do |package|
      next if package["type"] != "deb" && package["type"] != "dsc"
      name = package["package_url"].sub(%r{^/api/v1/repos/phusion/#{REPOSITORY}/package/(deb|dsc)/}, "")
      name.sub!(/\.el[0-9]+\.json$/, "")
      name.gsub!("/", "-")
      items << [name, "https://packagecloud.io#{package["package_url"]}"]
    end

    current_url = get_next_link_path(response["Link"])
  end

  items.sort! do |a, b|
    a[0] <=> b[0]
  end

  names = []
  urls  = []
  items.each do |item|
    names << item[0]
    urls  << item[1]
  end
  [names, urls]
end

def generate_yank_all_task_names(names)
  names.map do |name|
    "yank:#{name}"
  end
end

def get_next_link_path(header)
  return nil if header.nil?

  header.split(/, */).each do |part|
    if part =~ /\A<(.+)>; *rel=\"(.+)\"/ && $2 == "next"
      return URI.parse($1)
    end
  end

  nil
end

def yank_package(task, distro_version, filename)
  url = URI.parse("https://packagecloud.io/api/v1/repos/phusion/#{REPOSITORY}/#{distro_version}/#{filename}")
  request = Net::HTTP::Delete.new(uri_path_and_query_string(url))
  request.basic_auth(PACKAGECLOUD_TOKEN, "")
  response = PACKAGECLOUD_HTTP.request(url, request)
  if response.code != "200" && response.code != "404"
    task.log "Unable to yank package #{filename}:"
    task.log "URL   : #{url}"
    task.log "Status: #{response.code}"
    task.log "Body  : #{response.body}"
    abort
  end
end

def uri_path_and_query_string(uri)
  result = uri.path
  if uri.query
    result += "?"
    result << uri.query
  end
  result
end
