#!/usr/bin/env ruby
require 'net/http'
require 'net/https'
require 'uri'
require 'net/http/persistent'

def make_repo_server_http
  http = Net::HTTP::Persistent.new
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http
end

Kernel.const_set(:REPO_SERVER_API_USERNAME, ENV['REPO_SERVER_API_USERNAME'])
Kernel.const_set(:REPO_SERVER_API_TOKEN, File.read("/repo_server_api_token.txt").strip)
Kernel.const_set(:REPO_SERVER_HTTP, make_repo_server_http)
Kernel.const_set(:REPOSITORY, ENV['REPOSITORY'])

url = URI.parse("https://#{REPOSITORY}.phusionpassenger.com/api/clear_caches")
request = Net::HTTP::Post.new(url)
request.basic_auth(REPO_SERVER_API_USERNAME, REPO_SERVER_API_TOKEN)
response = REPO_SERVER_HTTP.request(url, request)
if response.code != "200"
  task.log "Unable to clear caches:"
  task.log "URL   : #{url}"
  task.log "Status: #{response.code}"
  task.log "Body  : #{response.body}"
  abort
end
