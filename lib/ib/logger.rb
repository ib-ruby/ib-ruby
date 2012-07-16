require "logger"

# Add default_logger accessor into Object
def default_logger
  @@default_logger ||= Logger.new(STDOUT).tap do |logger|
    logger.formatter = proc do |level, time, prog, msg|
      "#{time.strftime('%H:%M:%S.%N')} #{msg}\n"
    end
    logger.level = Logger::INFO
  end
end

def default_logger= logger
  @@default_logger = logger
end

# Add universally accessible log method/accessor into Object
def log *args
  default_logger.tap do |logger|
    logger.fatal *args unless args.empty?
  end
end












