require_relative 'tracking_category'
require_relative 'utils'
require 'monitor'
require 'stringio'
require 'paint'
require 'paint/rgb_colors'

class TrackingDatabase
  attr_accessor :thread
  attr_accessor :category_list
  attr_reader :log_dir
  attr_reader :start_time
  attr_reader :monitor

  def initialize(log_dir)
    @log_dir    = log_dir
    @category_list = []
    @categories = {}
    @start_time = Time.now
    @monitor    = Monitor.new
    @finished   = false
    @next_color_index = 0
  end

  def register_category(name, description)
    category = TrackingCategory.new(self, name, description)
    @category_list << category
    @categories[name] = category
  end

  def [](name)
    @categories[name]
  end

  def each_category
    @category_list.each do |category|
      yield category
    end
  end

  def set_finished!
    @monitor.synchronize do
      @finished = true
    end
  end

  def finished?
    @monitor.synchronize do
      @finished
    end
  end

  def has_errors?
    @monitor.synchronize do
      each_category do |category|
        category.each_task do |task|
          if task.state == :error
            return true
          end
        end
      end
    end
    false
  end

  def reopen_logs
    each_category do |category|
      category.reopen_logs
    end
  end

  def next_color
    result = nil
    @monitor.synchronize do
      result = Utils::COLORS[@next_color_index]
      @next_color_index = (@next_color_index + 1) % Utils::COLORS.size
    end
    result
  end

  def dump(color = false)
    io = StringIO.new
    if color
      success_color = [:green]
      error_color = [:red]
    else
      success_color = error_color = []
    end

    @monitor.synchronize do
      io.puts "Current time: #{Utils.format_time(Time.now)}"
      io.puts "Start time  : #{Utils.format_time(start_time)}"
      io.puts "Duration    : #{duration_description}"
      if finished?
        io.puts Paint["*** FINISHED ***", *success_color]
      end
      if has_errors?
        io.puts Paint["*** THERE WERE ERRORS ***", *error_color]
      end

      io.puts
      each_category do |category|
        io.puts "#{category.description}:"
        category.each_task do |task|
          if task.state == :done
            task_color = success_color
          elsif task.state == :error
            task_color = error_color
          else
            task_color = []
          end

          io.printf "  * %-25s: %-12s\n",
            task.display_name,
            Paint[task.state_name, *task_color]
          if task.start_time
            io.printf "    %25s  started %s\n", nil, Utils.format_time(task.start_time)
          end
          if desc = task.duration_description
            io.printf "    %25s  duration %s\n", nil, desc
          end
        end
        io.puts
      end
    end
    io.string
  end

  def duration_description
    Utils.distance_of_time_in_hours_and_minutes(@start_time, Time.now)
  end
end
