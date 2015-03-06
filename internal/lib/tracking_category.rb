require_relative 'tracking_task'

class TrackingCategory
  attr_reader :name, :description, :db

  def initialize(db, name, description)
    @db      = db
    @monitor = db.monitor
    @log_dir = db.log_dir
    @name = name
    @description = description
    @task_list = []
    @tasks = {}
  end

  def register_task(name)
    task = TrackingTask.new(self, name)
    @task_list << task
    @tasks[name] = task
  end

  def [](name)
    @tasks[name]
  end

  def each_task
    @task_list.each do |task|
      yield task
    end
  end

  def reopen_logs
    each_task do |task|
      task.reopen_log
    end
  end

  def monitor
    @db.monitor
  end

  def log_dir
    @db.log_dir
  end
end
