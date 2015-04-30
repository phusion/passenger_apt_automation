#!/usr/bin/env ruby
require 'net/http'
require 'net/https'
require 'uri'

def clear_cache(url, fingerprint_file, password_file)
  expected_fingerprint = File.read(fingerprint_file).strip
  admin_password = File.read(password_file).strip

  puts "+ POST #{url}"
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.ca_path = "/etc/ssl/certs"
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http.verify_callback = lambda do |preverify_ok, store_context|
    if preverify_ok and store_context.error == 0
      certificate = OpenSSL::X509::Certificate.new(store_context.chain[0])
      fingerprint = Digest::SHA256.hexdigest(certificate.to_der).upcase.scan(/../).join(":")
      if fingerprint == expected_fingerprint
        true
      else
        abort "Fingerprint verification for #{uri.host} failed.\n" +
          "  Expected: #{expected_fingerprint}\n" +
          "  Actual  : #{fingerprint}"
        false
      end
    else
      false
    end
  end

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
  "/system/internal/publish/oss-binaries.phusionpassenger.com-fingerprint.txt",
  "/oss_packagecloud_proxy_admin_password.txt")
clear_cache("https://www.phusionpassenger.com/packagecloud_proxy/clear_cache",
  "/system/internal/publish/passenger_website_fingerprint.txt",
  "/enterprise_packagecloud_proxy_admin_password.txt")
