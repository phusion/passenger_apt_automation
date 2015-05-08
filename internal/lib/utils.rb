require 'fileutils'
require 'shellwords'
require_relative 'preprocessor'

module Utils
  extend self

  COLORS = [
    "CadetBlue1",
    "yellow1",
    "burlywood1",
    "DarkOliveGreen1",
    "gold",
    "LightSalmon",
    "DarkTurquoise",
    "chocolate1",
    "SpringGreen1",
    "HotPink1",
    "GreenYellow",
    "MediumOrchid1",
    "DeepSkyBlue",
    "chartreuse1",
    "aquamarine"
  ].freeze

  def distance_of_time_in_hours_and_minutes(from_time, to_time)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    dist = (to_time - from_time).to_i
    minutes = (dist.abs / 60).round
    hours = minutes / 60
    minutes = minutes - (hours * 60)
    seconds = dist - (hours * 3600) - (minutes * 60)

    words = ''
    words << "#{hours} #{hours > 1 ? 'hours' : 'hour' } " if hours > 0
    words << "#{minutes} min " if minutes > 0
    words << "#{seconds} sec"
    words
  end

  def format_time(time)
    time.strftime("%Y-%m-%d %H:%M:%S")
  end

  def recursive_copy_files(files, destination_dir, preprocess = false, variables = {})
    if !STDOUT.tty?
      puts "Copying files..."
    end
    files.each_with_index do |filename, i|
      next if filename =~ /\.in(\.erb)?$/ || File.basename(filename) == "helpers.rb"
      dir = File.dirname(filename)
      if !File.exist?("#{destination_dir}/#{dir}")
        FileUtils.mkdir_p("#{destination_dir}/#{dir}")
      end
      if !File.directory?(filename)
        if preprocess && filename =~ /\.erb$/
          real_filename = filename.sub(/\.erb$/, '')
          Preprocessor.new.start(filename, "#{destination_dir}/#{real_filename}",
            variables)
        else
          FileUtils.install(filename, "#{destination_dir}/#{filename}", :preserve => true)
        end
      end
      if STDOUT.tty?
        printf "\r[%5d/%5d] [%3.0f%%] Copying files...", i + 1, files.size, i * 100.0 / files.size
        STDOUT.flush
      end
    end
    if STDOUT.tty?
      printf "\r[%5d/%5d] [%3.0f%%] Copying files...\n", files.size, files.size, 100
    end
  end

  def shesc(path)
    Shellwords.escape(path)
  end
end
