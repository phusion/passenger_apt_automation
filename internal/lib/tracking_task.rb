# encoding: binary
require_relative 'utils'
require 'shellwords'
require 'paint'
require 'paint/rgb_colors'

class TrackingTask
  class CommandError < SystemExit
    def initialize(status = 1)
      super(status)
    end
  end

  attr_reader :name, :category

  def initialize(category, name)
    @category = category
    @monitor  = category.monitor
    @log_dir  = category.log_dir
    @color    = category.db.next_color
    @name     = name
    @state    = :not_started
  end

  def reopen_log
    if @log
      @log.close
      @log = File.open(logfile_path, "a")
    end
  end

  def set_running!
    @monitor.synchronize do
      @state      = :running
      @start_time = Time.now
      @log        = File.open(logfile_path, "w")
    end
  end

  def set_done!
    @monitor.synchronize do
      @state = :done
      @end_time = Time.now
    end
  end

  def set_error!
    @monitor.synchronize do
      @state = :error
      @end_time = Time.now
    end
  end

  def state
    @monitor.synchronize do
      @state
    end
  end

  def state_name
    state.to_s.gsub('_', ' ')
  end

  def start_time
    @monitor.synchronize do
      @start_time
    end
  end

  def elapsed
    @monitor.synchronize do
      if @start_time
        (@end_time || Time.now) - @start_time
      else
        nil
      end
    end
  end

  def duration_description
    @monitor.synchronize do
      if @start_time
        Utils.distance_of_time_in_hours_and_minutes(@start_time, @end_time || Time.now)
      else
        nil
      end
    end
  end

  def display_name
    name.to_s.gsub(/[:\.]/, ' ')
  end

  def sh(command, env = {})
    real_command = build_real_command(command, env)
    log("--> #{real_command}")

    IO.popen("/bin/bash -c #{Shellwords.escape(real_command)} 2>&1", "rb") do |io|
      while !io.eof?
        line = io.readline.chomp
        if line =~ /^\e\[44m\e\[33m\e\[1m/
          # Looks like a header. Replace color codes with an ASCII
          # indicator.
          line.sub!(/^\e\[44m\e\[33m\e\[1m/, "--> ")
          line.sub!("\e[0m", "")
        elsif line !~ /^--> /
          line = "    #{line}"
        end
        log(line)
      end
    end

    if $?.nil? || $?.exitstatus != 0
      log(Paint["*** Command failed: ", :red] + command)
      raise CommandError
    end
  end

  def log(message)
    prefix = "#{category.name}:#{name}"
    prefix = Paint[prefix.ljust(29) + " | ", @color]
    time = Utils.format_time(Time.now)
    @monitor.synchronize do
      @log.puts("#{time}: #{message}")
      @log.flush
      STDOUT.write("#{prefix}#{time}: #{message}\n")
    end
  end

private
  def logfile_path
    name = @name.gsub(/[: ]/, '.')
    "#{@log_dir}/#{category.name}.#{name}.log"
  end

  def build_real_command(command, env)
    if env.empty?
      command
    else
      result = "env "
      env.each_pair do |key, val|
        result << "#{Shellwords.escape key.to_s}=#{Shellwords.escape val.to_s} "
      end
      result << command
      result
    end
  end
end
