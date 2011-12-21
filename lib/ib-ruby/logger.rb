require "logger"

# Hack in log method into Object
def log
  @@log ||= Logger.new(STDOUT).tap do |log|
    log.formatter = proc do |level, time, prog, msg|
      "#{time.strftime('%m-%d %H:%M:%S.%3N')}-#{level[0]}: #{msg}\n"
    end
    log.level = Logger::WARN
  end
end











