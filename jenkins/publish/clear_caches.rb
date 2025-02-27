#!/usr/bin/env ruby
require 'net/http'
require 'net/https'
require 'uri'

def clear_cache(url, password_file)
  admin_password = File.read(password_file).strip

  puts "+ POST #{url}"
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.ca_path = "/etc/ssl/certs"
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  request = Net::HTTP::Post.new(uri.path)
  request.basic_auth("admin", admin_password)
  response = http.request(request)
  if response.code != "200"
    abort "Unable to clear cache:\n" +
      "Status: #{response.code}\n" +
      "Body  : #{response.body}"
  end
end

clear_cache("https://oss-binaries.phusionpassenger.com/packagecloud_proxy/clear_cache",
  "/oss_packagecloud_proxy_admin_password.txt")
clear_cache("https://www.phusionpassenger.com/packagecloud_proxy/clear_cache",
  "/enterprise_packagecloud_proxy_admin_password.txt")
