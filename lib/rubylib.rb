require 'fileutils'
require_relative 'preprocessor'

def string_option(name, default_value = nil)
	value = ENV[name]
	if value.nil? || value.empty?
		return default_value
	else
		return value
	end
end

def boolean_option(name, default_value = false)
	value = ENV[name]
	if value.nil? || value.empty?
		return default_value
	else
		return value == "yes" || value == "on" || value == "true" || value == "1"
	end
end

def recursive_copy_files(files, destination_dir, preprocess = false, variables = {})
	if !STDOUT.tty?
		puts "Copying files..."
	end
	files.each_with_index do |filename, i|
		dir = File.dirname(filename)
		if !File.exist?("#{destination_dir}/#{dir}")
			FileUtils.mkdir_p("#{destination_dir}/#{dir}")
		end
		if !File.directory?(filename)
			if preprocess && filename =~ /\.template$/
				real_filename = filename.sub(/\.template$/, '')
				FileUtils.install(filename, "#{destination_dir}/#{real_filename}", :preserve => true)
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

def infer_next_passenger_version(passenger_version)
	components = passenger_version.split(".")
	components.last.sub!(/[0-9]+$/) do |number|
		(number.to_i + 1).to_s
	end
	return components.join(".")
end
