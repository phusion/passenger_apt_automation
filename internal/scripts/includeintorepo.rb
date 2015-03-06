#!/usr/bin/env ruby
require 'shellwords'

def sh(command)
  puts "+++ #{command}"
  if !system(command)
    exit 1
  end
end

def shesc(path)
  Shellwords.escape(path)
end

def shesc_array(paths)
  paths.map { |path| shesc(path) }.join(" ")
end

def group_files_by_distro(paths)
  result = {}
  paths.each do |path|
    path =~ /~(.*?)\d/
    distro = $1
    result[distro] ||= []
    result[distro] << path
  end
  result
end

if (files = Dir["/package/*.deb"]).any?
  puts "++ Including .deb files into repo...."
  group_files_by_distro(files).each_pair do |distro, files2|
    sh("reprepro -Vb /output includedeb #{shesc distro} #{shesc_array files2}")
  end
end
if (files = Dir["/package/*.dsc"]).any?
  puts "++ Including .dsc files into repo...."
  group_files_by_distro(files).each_pair do |distro, files2|
    sh("reprepro -Vb /output includedsc #{shesc distro} #{shesc_array files2}")
  end
end
