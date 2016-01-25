#!/usr/bin/env ruby
require 'net/http'
require 'net/https'
require 'uri'

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

def clear_cache(url, fingerprint_file, password_file)
  expected_fingerprint = File.read(fingerprint_file).split("\n")
  admin_password = File.read(password_file).strip

  puts "+ POST #{url}"
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.ca_path = "/etc/ssl/certs"
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http.verify_callback = lambda do |preverify_ok, store_context|
    if preverify_ok && store_context.error == 0
      verify_certificate_chain(uri.host, store_context.chain, expected_fingerprints)
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
