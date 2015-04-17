require_relative 'tracking_database'
require 'thread'
require 'stringio'

def initialize_tracking_database!(show_overview_periodically)
  db = TrackingDatabase.new("/work")
  Kernel.const_set(:TRACKING_DB, db)

  if !SHOW_TASKS
    db.thread = Thread.new do
      Thread.current.abort_on_exception = true
      begin
        while true
          sleep 5
          db.monitor.synchronize do
            dump_tracking_database(show_overview_periodically)
          end
        end
      rescue Exception => e
        STDERR.puts("#{e} (#{e.class})\n  " << e.backtrace.join("\n  "))
        exit!
      end
    end
  end
end

def initialize_tracking_database_logs!
  TRACKING_DB.monitor.synchronize do
    Kernel.const_set(:MAIN_LOG, File.open("/work/state.log", "w+"))
  end
  TRACKING_DB.reopen_logs
end

def register_tracking_category(name, description)
  TRACKING_DB.register_category(name, description)
end

def register_tracking_task(category_name, task_name)
  TRACKING_DB[category_name].register_task(task_name)
end

def track_task(category_name, task_name, print_progress_when_done = true)
  succeeded = false
  task = nil
  TRACKING_DB.monitor.synchronize do
    category = TRACKING_DB[category_name]
    task = category[task_name]
    task.set_running!
    STDOUT.write("----- Task started: #{category.description} -> #{task_name} -----\n")
    dump_tracking_database
  end
  begin
    yield(task)
    succeeded = true
    STDOUT.write("\n")
  ensure
    if succeeded
      task.set_done!
      STDOUT.write("----- Task done: #{task.category.description} -> #{task_name} -----\n")
    else
      task.set_error!
      STDOUT.write("----- Task errored: #{task.category.description} -> #{task_name} -----\n")
    end
    if print_progress_when_done
      dump_tracking_database
    end
  end
end

def dump_tracking_database(print_to_stdout = true)
  TRACKING_DB.monitor.synchronize do
    if defined?(MAIN_LOG)
      output = TRACKING_DB.dump
    end
    if print_to_stdout
      console_output = TRACKING_DB.dump(true)
    end

    if defined?(MAIN_LOG)
      MAIN_LOG.truncate(0)
      MAIN_LOG.rewind
      MAIN_LOG.write(output)
      MAIN_LOG.flush
    end

    if print_to_stdout
      STDOUT.write("\n")
      STDOUT.write("---------------------------------------------\n")
      STDOUT.write(console_output.chomp + "\n")
      STDOUT.write("---------------------------------------------\n")
      STDOUT.write("\n")
      STDOUT.flush
    end
  end
end
